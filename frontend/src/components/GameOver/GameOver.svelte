<script>
	import { Spinner } from '../Spinner';
	import { web3, selectedAccount, contracts } from 'svelte-web3';
	import { GameStates } from '$lib/constants.js';
	import { toast, Toast } from '../Toast';
	export let ctx;

	let winner = null;
	let title = null;
	let text = null;
	let can_withdraw = false;

	$contracts.BattleShip.events
		.GameOver({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Winner is
			winner = $web3.utils.toBigInt(event.returnValues.winner);
			let current_account = $web3.utils.toBigInt($selectedAccount);

			if (winner === current_account) {
				title = 'You won!';
				text = 'Congratulations! You won the game. You can now withdraw your winnings.';
				can_withdraw = true;
			} else if (winner === ctx.opponent_id) {
				title = 'You lost!';
				text = 'Unfortunately, you lost the game. Better luck next time!';
				can_withdraw = false;
			} else {
				title = 'Draw!';
				text = 'The game ended in a draw. You can now withdraw your bet.';
				can_withdraw = true;
			}
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
				return;
			}

			// Current player cheated, so move to Hall of shame page
			ctx.set_state(GameStates.HallOfShame);
		});

	const withdraw = () => {
		$contracts.BattleShip.methods
			.withdraw(ctx.game_id)
			.send({ from: $selectedAccount })
			.on('receipt', (receipt) => {
				toast.set({ message: 'Withdrawal successful', type: 'success' });
				can_withdraw = false;
			})
			.on('error', (error) => {
				toast.set({ message: 'Withdrawal failed', type: 'error' });
			});
	};
</script>

{#if winner === null}
	<Spinner />
	<p class="text-center">Fetching the winner</p>
{:else}
	<!-- Main modal -->
	<div
		id="default-modal"
		tabindex="-1"
		aria-hidden="true"
		class="overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 justify-center items-center w-full md:inset-0 h-[calc(100%-1rem)] max-h-full flex"
	>
		<div class="relative p-4 w-full max-w-2xl max-h-full mx-auto">
			<!-- Modal content -->
			<div class="relative bg-white rounded-lg shadow dark:bg-gray-700">
				<!-- Modal header -->
				<div
					class="flex items-center justify-between p-4 md:p-5 border-b rounded-t dark:border-gray-600"
				>
					<h3 class="text-xl font-semibold text-gray-900 dark:text-white">{title}</h3>
				</div>
				<!-- Modal body -->
				<div class="p-4 md:p-5 space-y-4">
					<p class="text-base leading-relaxed text-gray-500 dark:text-gray-400">
						{text}
					</p>
				</div>
				<!-- Modal footer -->
				<div
					class="flex items-center p-4 md:p-5 border-t border-gray-200 rounded-b dark:border-gray-600"
				>
					{#if can_withdraw}
						<button
							data-modal-hide="default-modal"
							type="button"
							class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
							on:click={withdraw}>Withdraw</button
						>
					{:else}
						<button
							data-modal-hide="default-modal"
							type="button"
							class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
							on:click={() => {
								document.location.reload();
							}}>Quit</button
						>
					{/if}
				</div>
			</div>
		</div>
	</div>
{/if}

<Toast />
