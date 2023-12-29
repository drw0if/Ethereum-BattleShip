<script>
	import { web3, contracts, selectedAccount } from 'svelte-web3';
	import { GameStates } from '$lib/constants.js';
	export let ctx;

	ctx.has_revealed = false;

	const reveal_board = (cheat) => {
		let ships = ctx.ships.map((ship) => {
			return {
				start_position: ship[0].i * 8 + ship[0].j,
				is_horizontal: new Set(ship.map((x) => x.i)).size === 1
			};
		});

		if (cheat) {
			ships = new Array(5).fill({
				start_position: 0,
				is_horizontal: true
			});
		}

		$contracts.BattleShip.methods
			.reveal_board(ctx.game_id, ships, ctx.nonces)
			.send({ from: $selectedAccount })
			.on('receipt', (receipt) => {
				ctx.last_block_received = receipt.blockNumber;
				ctx.has_revealed = true;
			});
	};

	const make_accusation = () => {};

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

	$contracts.BattleShip.events
		.GameOver({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Here only if game ends correctly
			ctx.last_block_received = event.blockNumber;
			ctx.set_state(GameStates.GameOver);
		});
</script>

<section class="bg-gray-50 dark:bg-gray-900 flex flex-col mx-auto">
	{#if !ctx.has_revealed}
		<div class="text-center mt-3">
			<button
				type="button"
				class="w-auto text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
				on:click={() => {
					reveal_board(false);
				}}>Reveal board</button
			>
			<button
				type="button"
				class="w-auto text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
				on:click={() => {
					reveal_board(true);
				}}>Cheat</button
			>
		</div>
	{:else}
		<button
			type="button"
			class="w-auto text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
			on:click={make_accusation}>Accuse of leaving</button
		>
	{/if}
</section>
