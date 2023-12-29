<script>
	import { web3, contracts, selectedAccount } from 'svelte-web3';
	import { Toast, toast } from '../Toast';
	import { GameStates } from '$lib/constants.js';
	import { AccusationModal } from '../AccusationModal';

	export let ctx;

	const BoardStatus = {
		Empty: 0,
		Selected: 1,
		Placed: 2,
		Hit: 3,
		Miss: 4
	};

	const color_map = {
		[BoardStatus.Empty]: 'bg-gray-200',
		[BoardStatus.Selected]: 'bg-black',
		[BoardStatus.Placed]: 'bg-green-500',
		[BoardStatus.Hit]: 'bg-red-500',
		[BoardStatus.Miss]: 'bg-blue-500'
	};

	ctx.can_make_move = false;
	ctx.can_reveal = false;
	ctx.opponent_board_status = new Array(64).fill(BoardStatus.Empty);
	ctx.opponent_selection = null;
	ctx.running_accusation = false;

	// wait for GameStarted to enable the selection
	$contracts.BattleShip.events
		.GameStarted({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			if (event.returnValues.game_id != ctx.game_id) {
				return;
			}
			ctx.last_block_received = event.blockNumber;
			ctx.can_make_move = true;
			toast.set({ message: 'Game started', type: 'success' });
		});

	// send the move to the contract when user clicks on the grid
	const make_move = (i, j) => {
		if (!ctx.can_make_move) {
			return;
		}

		const index = i * 8 + j;

		if (ctx.opponent_board_status[index] !== BoardStatus.Empty) {
			toast.set({ message: 'Waiting for opponent move', type: 'error' });
			return;
		}

		$contracts.BattleShip.methods
			.submit_move(ctx.game_id, index)
			.send({ from: $selectedAccount })
			.catch(() => {
				ctx.opponent_board_status[index] = BoardStatus.Empty;
				ctx.can_make_move = true;
			});

		ctx.opponent_board_status[index] = BoardStatus.Selected;
		ctx.can_make_move = false;
	};

	// When opponent propose a move change the color of the board
	$contracts.BattleShip.events
		.MoveProposed({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			if (event.returnValues.game_id != ctx.game_id) {
				return;
			}

			const player = $web3.utils.toBigInt(event.returnValues.player_id);

			const index = event.returnValues.move;
			if (player === ctx.opponent_id) {
				ctx.opponent_selection = Number(index);
				ctx.can_reveal = true;
			} else if (player === $web3.utils.toBigInt($selectedAccount)) {
				ctx.opponent_board_status[index] = BoardStatus.Selected;
				ctx.can_make_move = false;
			}
		});

	const reveal = async (cheat) => {
		if (!ctx.can_reveal) {
			return;
		}

		const proof = new Array();

		let cursor = 1;
		let lb = 1;
		let up = 64;

		for (let i = 0; i < 6; i++) {
			const mid = Math.floor((lb + up) / 2);
			if (ctx.opponent_selection + 1 <= mid) {
				// leaf is on the left
				// so the proof contains the right hash
				proof.push(ctx.merkle_tree[cursor * 2 + 1]);
				up = mid;
				cursor = cursor * 2;
			} else {
				// leaf is on the right
				// so the proof contains the left hash
				proof.push(ctx.merkle_tree[cursor * 2]);
				lb = mid;
				cursor = cursor * 2 + 1;
			}
		}

		// the contract expects the proof from the leaf to the root
		proof.reverse();

		const has_ship = ctx.board_status[ctx.opponent_selection] === BoardStatus.Placed;
		const tmp = ctx.opponent_selection;

		const tx = await $contracts.BattleShip.methods
			.submit_proof(ctx.game_id, has_ship, cheat ? 1 : ctx.nonces[ctx.opponent_selection], proof)
			.send({ from: $selectedAccount })
			.catch((_) => {
				ctx.can_reveal = true;
				ctx.board_status[ctx.opponent_selection] = has_ship
					? BoardStatus.Placed
					: BoardStatus.Empty;
				ctx.opponent_selection = tmp;
			});

		ctx.board_status[ctx.opponent_selection] = has_ship ? BoardStatus.Hit : BoardStatus.Miss;
		ctx.can_reveal = false;
		ctx.opponent_selection = null;
	};

	const hit_or_miss = (receipt, type) => {
		const player_id = $web3.utils.toBigInt(receipt.returnValues.player_id);
		let index = Number(receipt.returnValues.position);

		if (player_id === ctx.opponent_id) {
			ctx.board_status[index] = type === 'hit' ? BoardStatus.Hit : BoardStatus.Miss;
		} else if (player_id === $web3.utils.toBigInt($selectedAccount)) {
			ctx.opponent_board_status[index] = type === 'hit' ? BoardStatus.Hit : BoardStatus.Miss;
		}
	};

	$contracts.BattleShip.events
		.Hit({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (receipt) => hit_or_miss(receipt, 'hit'));

	$contracts.BattleShip.events
		.Miss({
			filter: { game_id: ctx.game_id, player_id: ctx.opponent_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (receipt) => hit_or_miss(receipt, 'miss'));

	$contracts.BattleShip.events
		.NextRound({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			ctx.last_block_received = event.blockNumber;
			ctx.can_make_move = true;
			toast.set({ message: 'Next round', type: 'success' });
		});

	$contracts.BattleShip.events
		.EndOfGame({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Here only if game ends correctly
			ctx.last_block_received = event.blockNumber;
			ctx.set_state(GameStates.RevealBoard);
		});

	$contracts.BattleShip.events
		.CheatingAttempt({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			const player_id = $web3.utils.toBigInt(event.returnValues.player_id);
			ctx.last_block_received = event.blockNumber;

			if (player_id === ctx.opponent_id) {
				// Opponent cheated so, move to GameOver state
				ctx.set_state(GameStates.GameOver);
				return;
			}

			// Current player cheated, so move to Hall of shame page
			ctx.set_state(GameStates.HallOfShame);
		});

	const make_accusation = () => {
		if (ctx.can_make_move || ctx.can_reveal) {
			return;
		}

		$contracts.BattleShip.methods
			.make_accusation(ctx.game_id)
			.send({ from: $selectedAccount })
			.on('receipt', (receipt) => {
				ctx.accused_at = receipt.blockNumber;
			})
			.catch((_) => {
				ctx.running_accusation = false;
			});

		ctx.running_accusation = true;
	};

	$contracts.BattleShip.events
		.AccusationElapsed({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			console.log('AccusationElapsed event');
			// Here only if opponent left the game and the accusation elapsed
			ctx.last_block_received = event.blockNumber;
			ctx.set_state(GameStates.GameOver);
		});

	$contracts.BattleShip.events
		.AccusationRetired({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Here if the accusation has been retired remove the popup
			ctx.running_accusation = false;
		});

	$contracts.BattleShip.events
		.AccusationRequest({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Here if the accusation has been requested
			ctx.last_block_received = event.blockNumber;

			if (event.returnValues.player_id.toLowerCase() !== $selectedAccount.toLowerCase()) {
				toast.set({
					message: 'You have been accused of idle, make your move to avoid losing the game!',
					type: 'error'
				});
			} else {
				ctx.running_accusation = true;
				ctx.accused_at = event.blockNumber;
			}
		});
</script>

<section class="bg-gray-50 dark:bg-gray-900 flex flex-col mx-auto">
	<div class="bg-gray-50 dark:bg-gray-900 flex flex-row mx-auto">
		<div>
			<h5 class="text-xl font-bold dark:text-white w-100 text-center m-5">Your board</h5>
			<table class="mx-5">
				{#each { length: 8 } as _, i}
					<tr>
						{#each { length: 8 } as _, j}
							<td
								class="border border-gray-200 dark:border-gray-700 cell {color_map[
									ctx.board_status[i * 8 + j]
								]} {ctx.opponent_selection === i * 8 + j ? 'selected_cell' : ''}"
							>
							</td>
						{/each}
					</tr>
				{/each}
			</table>
		</div>
		<div>
			<h5 class="text-xl font-bold dark:text-white w-100 text-center m-5">Opponent board</h5>
			<table class="mx-5">
				{#each { length: 8 } as _, i}
					<tr>
						{#each { length: 8 } as _, j}
							<td
								class="border border-gray-200 dark:border-gray-700 cell {color_map[
									ctx.opponent_board_status[i * 8 + j]
								]}"
								on:click={() => make_move(i, j)}
							>
							</td>
						{/each}
					</tr>
				{/each}
			</table>
		</div>
	</div>
	<div class="text-center mt-3">
		{#if ctx.can_make_move}
			<h5 class="text-xl font-bold dark:text-white w-100 text-center">Make your move</h5>
			<p class="mb-3 text-gray-500 dark:text-gray-400">
				By clicking the cell you want to uncover on the opponent board
			</p>
		{:else if ctx.can_reveal}
			<button
				type="button"
				class="w-auto text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
				on:click={() => {
					reveal(false);
				}}>Reveal</button
			>
			<button
				type="button"
				class="w-auto text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
				on:click={() => {
					reveal(true);
				}}>Cheat</button
			>
		{:else}
			<h5 class="text-xl font-bold dark:text-white w-100 mt-3 text-center">Waiting for opponent</h5>
			<button
				type="button"
				class="w-auto text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
				on:click={make_accusation}>Accuse of leaving</button
			>
		{/if}
	</div>
</section>

<Toast />

{#if ctx.running_accusation}
	<AccusationModal bind:ctx />
{/if}

<style>
	.cell {
		width: 50px;
		height: 50px;
		border: 1px solid black;
	}

	.selected_cell {
		background-color: black;
	}
</style>
