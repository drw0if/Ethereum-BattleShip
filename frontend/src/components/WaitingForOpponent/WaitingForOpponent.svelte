<script>
	import { web3, selectedAccount, contracts } from 'svelte-web3';
	import { GameStates } from '$lib/constants.js';
	import { Toast, toast } from '../Toast';

	export let ctx;

	// Wait for players to join
	$contracts.BattleShip.events
		.PlayerJoined({
			fromBlock: ctx.last_block_received,
			filter: { game_id: ctx.game_id }
		})
		.on('data', (event) => {
			let opponent_id = event.returnValues.player_id;

			ctx.opponent_id = $web3.utils.toBigInt(opponent_id);
			ctx.set_state(GameStates.FeeNegotiation, event.blockNumber);
		});
</script>

<section class="bg-gray-50 dark:bg-gray-900 flex flex-row mx-auto">
	<div class="flex flex-col items-center justify-center px-6 py-8 mx-auto my-auto lg:py-0">
		<div
			class="w-full bg-white rounded-lg shadow dark:border md:mt-0 sm:max-w-md xl:p-0 dark:bg-gray-800 dark:border-gray-700"
		>
			<div class="p-6 space-y-4 md:space-y-6 sm:p-8">
				<p class="mb-3 text-gray-500 dark:text-gray-400 text-center">
					Share the game ID to invite another player to join your match!
				</p>
				<input
					type="text"
					class="block w-full p-4 text-sm text-gray-900 border border-gray-300 rounded-lg bg-gray-50 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
					value={ctx.game_id}
					disabled
				/>
				<button
					type="button"
					class="block text-white bg-blue-700 hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 font-medium rounded-full text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800 mx-auto"
					on:click={() => {
						navigator.clipboard.writeText(ctx.game_id);
						toast.set({ message: 'Game ID copied to clipboard', type: 'success' });
					}}>COPY</button
				>
			</div>
		</div>
	</div>
</section>
<Toast />
