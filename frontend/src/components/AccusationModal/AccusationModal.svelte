<script>
	import { GameStates } from '$lib/constants.js';
	import { web3, contracts, selectedAccount } from 'svelte-web3';

	export let ctx;
	let blocks_left = 5;

	const check_accusation = async () => {
		$contracts.BattleShip.methods.check_accusation(ctx.game_id).send({ from: $selectedAccount });
	};

	$contracts.BattleShip.events
		.AccusationInPlace({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Here if the accusation is still in place
			blocks_left = 5 - (Number(event.blockNumber) - Number(ctx.accused_at));
		});
</script>

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
				<h3 class="text-xl font-semibold text-gray-900 dark:text-white">
					Waiting for opponent move...
				</h3>
			</div>
			<!-- Modal body -->
			<div class="p-4 md:p-5 space-y-4">
				<p class="text-base leading-relaxed text-gray-500 dark:text-gray-400">
					You accused the opponent of leaving the game, it has {blocks_left} block(s) left to respond.
				</p>
			</div>
			<!-- Modal footer -->
			<div
				class="flex items-center p-4 md:p-5 border-t border-gray-200 rounded-b dark:border-gray-600"
			>
				<button
					data-modal-hide="default-modal"
					type="button"
					class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
					on:click={check_accusation}>Check accusation</button
				>
			</div>
		</div>
	</div>
</div>
