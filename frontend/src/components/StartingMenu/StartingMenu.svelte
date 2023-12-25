<script>
	import { contracts, web3, selectedAccount } from 'svelte-web3';
	import { GameStates } from '$lib/constants.js';
	import { Toast, toast } from '../Toast';
	import { decode_event } from '$lib/utils.js';

	export let ctx;

	let user_provided_game_id = '';

	const create_new_game = async () => {
		try {
			ctx.set_state(GameStates.WaitingForReceipt);

			const tx_hash = await $contracts.BattleShip.methods
				.new_game()
				.send({
					from: $selectedAccount
				})
				.on('receipt', (receipt) => {
					if (receipt.logs.length == 0) {
						toast.set({ message: "Can't create a new game, please try again in a while" });
						return;
					}

					const decoded_data = decode_event('NewGame', receipt.logs[0]);

					ctx.game_id = decoded_data.game_id;
					ctx.set_state(GameStates.WaitingForOpponent);
				});
		} catch (err) {
			toast.set({ message: "Can't create a new game, please try again in a while" });
		}
	};

	const join_game = async () => {
		try {
			let game_id = null;
			let tx_hash = null;
			let new_state = null;

			// If no game id is provided, join a random game
			if (user_provided_game_id === '') {
				//ctx.set_state(GameStates.WaitingForReceipt);
				console.log('Joining a random game without ID');

				const tx_hash = await $contracts.BattleShip.methods
					.join_random_game()
					.send({
						from: $selectedAccount
					})
					.on('receipt', (receipt) => {
						console.log('Receipt: ', receipt);

						if (receipt.logs.length == 0) {
							toast.set({ message: "Can't join any game, try to create a new one" });
							return;
						}

						let decoded_data;
						let new_game = false;

						try {
							decoded_data = decode_event('NewGame', receipt.logs[0]);
							new_game = true;
							console.log(`NewGame`);
						} catch (err) {
							decoded_data = decode_event('PlayerJoined', receipt.logs[0]);
							console.log(`PlayerJoined`);
						}

						console.log(decoded_data);
						console.log(new_game);

						//ctx.game_id = decoded_data.game_id;
						//game_id = result[0];
						//ctx.set_state(result[1] ? GameStates.WaitingForOpponent : GameStates.FeeNegotiation);
					});
			} else {
				// Otherwise, try to convert the string to a uint256 and
				// join the game with the provided id
				game_id = $web3.utils.toBN(user_provided_game_id);
				console.log(`User provided: ${user_provided_game_id} -> ${game_id}`);
				const result = await $contracts.BattleShip.methods.join_game(game_id).call();
				const tx_hash = await $contracts.BattleShip.methods.join_game(game_id).send({
					from: $selectedAccount
				});
				console.log(result);
				//ctx.game_state = GameStates.FeeNegotiation;
			}
		} catch (err) {
			console.log(err);
			toast.set({ message: "Can't join the game, please try again in a while" });
		}
	};
</script>

<section class="bg-gray-50 dark:bg-gray-900 flex flex-row mx-auto">
	<div class="flex flex-col items-center justify-center px-6 py-8 mx-auto my-auto lg:py-0">
		<div
			class="w-full bg-white rounded-lg shadow dark:border md:mt-0 sm:max-w-md xl:p-0 dark:bg-gray-800 dark:border-gray-700"
		>
			<div class="p-6 space-y-4 md:space-y-6 sm:p-8">
				<form class="space-y-4 md:space-y-6" action="#">
					<button
						type="button"
						class="w-full text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
						on:click|preventDefault={create_new_game}
					>
						<h1 class="text-xl font-bold leading-tight tracking-tight text-gray-200 md:text-2xl">
							Create new game
						</h1>
					</button>
				</form>
			</div>
		</div>
	</div>
	<div class="flex flex-col items-center justify-center px-6 py-8 mx-auto mx-auto my-auto lg:py-0">
		<div
			class="w-full bg-white rounded-lg shadow dark:border md:mt-0 sm:max-w-md xl:p-0 dark:bg-gray-800 dark:border-gray-700"
		>
			<div class="p-6 space-y-4 md:space-y-6 sm:p-8">
				<form class="space-y-4 md:space-y-6" action="#">
					<div>
						<input
							type="text"
							name="game_id"
							id="game_id"
							class="bg-gray-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg focus:ring-primary-600 focus:border-primary-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
							placeholder="Game ID"
							bind:value={user_provided_game_id}
						/>
					</div>
					<button
						type="button"
						class="w-full text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
						on:click|preventDefault={join_game}
					>
						<h1 class="text-xl font-bold leading-tight tracking-tight text-gray-200 md:text-2xl">
							Join game
						</h1>
					</button>
					<p class="text-sm font-light text-gray-500 dark:text-gray-400">
						Leave blank to join a random game
					</p>
				</form>
			</div>
		</div>
	</div>
</section>
<Toast />
