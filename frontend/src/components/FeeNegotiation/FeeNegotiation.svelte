<script>
	import { web3, selectedAccount, contracts } from 'svelte-web3';
	import { GameStates } from '$lib/constants.js';
	import { Toast, toast } from '../Toast';
	import { Modal } from '../Modal';

	export let ctx;
	let hide_modal = true;
	let current_fee = 100;
	let last_proposed_fee = null;
	let opponent_fee = null;

	// Subscribe to FeeProposed event to update the opponent proposed fee
	// and open the modal
	$contracts.BattleShip.events
		.FeeProposed({
			filter: { game_id: ctx.game_id, player_id: ctx.opponent_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', async (event) => {
			const { game_id, fee, player_id } = event.returnValues;
			if (game_id !== ctx.game_id) {
				return;
			}

			if (player_id === ctx.opponent_id) {
				opponent_fee = fee;
				hide_modal = false;
			} else {
				return;
			}
		});

	// Subscribe to FeeAgreed event to move to the next state
	$contracts.BattleShip.events
		.FeeAgreed({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', async (event) => {
			const { game_id, fee } = event.returnValues;
			if (game_id !== ctx.game_id) {
				return;
			}
			hide_modal = true;

			ctx.fee = fee;
			ctx.last_block_received = event.blockNumber;
			ctx.set_state(GameStates.WaitingCommitment);
		});

	const propose_fee = () => {
		try {
			if (!current_fee) {
				throw new Error('Invalid fee proposed');
			}
			const proposed_fee = $web3.utils.toBigInt(current_fee);

			$contracts.BattleShip.methods
				.propose_fee(ctx.game_id, proposed_fee)
				.send({ from: $selectedAccount });
			last_proposed_fee = proposed_fee;
		} catch (err) {
			console.error(err);
			if (
				err.message &&
				(err.message.includes('Invalid value given') || err.message.includes('Cannot convert'))
			) {
				toast.set({ message: 'Invalid fee proposed' });
			} else {
				toast.set({ message: "Can't propose that fee" });
			}
		}
	};

	const accept_fee = () => {
		current_fee = opponent_fee;
		propose_fee();
	};
</script>

<section class="bg-gray-50 dark:bg-gray-900 flex flex-col mx-auto">
	{#if last_proposed_fee}
		<p class="mb-3 text-gray-500 dark:text-gray-400 text-center">
			Your last proposal: {last_proposed_fee.toString()}
		</p>
	{/if}

	<form class="max-w-sm mx-auto p-10">
		<div class="mb-5">
			<label for="fee" class="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
				>Propose your fee:</label
			>
			<input
				type="number"
				id="fee"
				class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder="100"
				required
				bind:value={current_fee}
			/>
		</div>
		<button
			type="button"
			class="block text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800 m-auto"
			on:click|preventDefault={propose_fee}>Propose</button
		>
	</form>

	{#if opponent_fee}
		<form class="max-w-sm mx-auto p-10">
			<div class="mb-5">
				<p class="mb-3 text-gray-500 dark:text-gray-400 text-center">
					Your opponent proposed: {opponent_fee}
				</p>
			</div>
			<button
				type="button"
				class="block text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800 m-auto"
				on:click|preventDefault={accept_fee}>Accept</button
			>
		</form>
	{/if}
</section>
<Modal
	bind:hide={hide_modal}
	title="Opponent fee proposal"
	text={`Opponent proposed: ${opponent_fee}`}
	ok_text="Accept"
	deny_text="Deny"
	on_ok={accept_fee}
/>

<Toast />
