<script>
	import { GameStates } from '$lib/constants.js';
	import { web3, selectedAccount, contracts } from 'svelte-web3';
	import { Toast, toast } from '../Toast';
	import { Modal } from '../Modal';
	import { compute_proof } from '$lib/utils.js';

	export let ctx;

	let ship_sizes = [5, 4, 3, 2, 2];
	let ships = [];
	let current_selection = [];
	let is_valid_selection = false;
	// 0 empty
	// 1 selected
	// 2 placed
	let board_status = new Array(64).fill(0);

	const cell_background_colors = ['bg-gray-200', 'bg-blue-500', 'bg-green-500'];

	const manage_cell = (i, j) => {
		const index = i * 8 + j;
		if (board_status[index] === 2) {
			let position = null;
			ships.forEach((ship, ship_index) => {
				if (ship.find((x) => x.i === i && x.j === j)) {
					position = ship_index;
				}
			});

			const ship = ships[position];
			const ship_size = ship.length;

			ship.forEach(({ i, j }) => {
				board_status[i * 8 + j] = 0;
			});

			ship_sizes.push(ship_size);
			ship_sizes.sort().reverse();
			ship_sizes = ship_sizes;

			ships.splice(position, 1);
			ships = ships;

			return;
		}

		if (ship_sizes.length === 0) {
			return;
		}

		if (board_status[index] === 0) {
			board_status[index] = 1;
			current_selection.push({ i, j });
		} else {
			board_status[index] = 0;
			current_selection = current_selection.filter((x) => x.i !== i || x.j !== j);
		}
		is_valid_selection = check_selection();
	};

	const add_ship = () => {
		current_selection.sort(({ i: i1, j: j1 }, { i: i2, j: j2 }) => {
			if (i1 === i2) {
				return j1 - j2;
			}
			return i1 - i2;
		});
		ships.push(current_selection);
		ship_sizes.splice(ship_sizes.indexOf(current_selection.length), 1);
		ship_sizes = ship_sizes;
		current_selection.forEach(({ i, j }) => {
			board_status[i * 8 + j] = 2;
		});
		current_selection = [];
	};

	const check_selection = () => {
		if (!ship_sizes.includes(current_selection.length)) {
			return false;
		}

		// Check if all i are the same
		const i_set = new Set(current_selection.map((x) => x.i));
		const j_set = new Set(current_selection.map((x) => x.j));

		// ship is horizontal
		if (i_set.size === 1) {
			// Check if all j are consecutive
			const j_array = current_selection.map((x) => x.j);
			j_array.sort();
			for (let i = 0; i < j_array.length - 1; i++) {
				if (j_array[i] + 1 !== j_array[i + 1]) {
					return false;
				}
			}
			return true;
		}
		// ship is vertical
		else if (j_set.size === 1) {
			// Check if all i are consecutive
			const i_array = current_selection.map((x) => x.i);
			i_array.sort();
			for (let i = 0; i < i_array.length - 1; i++) {
				if (i_array[i] + 1 !== i_array[i + 1]) {
					return false;
				}
			}
			return true;
		}
		return false;
	};

	const commit_board = () => {
		// Generate nonces
		const nonces = new Array(64).fill(0).map((x, i) => {
			const nonce = new Array(4)
				.fill(0)
				.map((x) => $web3.utils.randomHex(8).slice(2))
				.reduce((a, b) => a + b, '0x');
			return $web3.utils.toBigInt(nonce, 16);
		});

		// Building merkle tree 1-indexed (for efficient son-father calculation)
		// starting with generating hash(position_status || nonce)
		// in leafs
		let merkle_tree = new Array(128).fill(0);

		board_status.forEach((cell_state, i) => {
			merkle_tree[i + 64] = compute_proof(cell_state === 2, nonces[i]);
		});

		// Compute Merkle tree root
		let i = 63;

		while (i > 0) {
			merkle_tree[i] = compute_proof(merkle_tree[i * 2], merkle_tree[i * 2 + 1]);
			i--;
		}

		// Save state in context
		ctx.merkle_tree = merkle_tree;
		ctx.nonces = nonces;

		// Sort ships by size, descending
		ships.sort((a, b) => b.length - a.length);
		ctx.ships = ships;

		// Commit board on blockchain
		$contracts.BattleShip.methods
			.commit_board(ctx.game_id, ctx.merkle_tree[1])
			.send({ from: $selectedAccount, value: ctx.fee })
			.on('receipt', (receipt) => {
				// Save reference to block and change state
				ctx.board_status = board_status;
				ctx.last_block_received = receipt.blockNumber;
				ctx.set_state(GameStates.Game);
			});
	};
</script>

<section class="bg-gray-50 dark:bg-gray-900 flex flex-row mx-auto">
	<table>
		{#each { length: 8 } as _, i}
			<tr>
				{#each { length: 8 } as _, j}
					<td
						class="border border-gray-200 dark:border-gray-700 cell {cell_background_colors[
							board_status[i * 8 + j]
						]}"
						on:click={() => {
							manage_cell(i, j);
						}}
					>
					</td>
				{/each}
			</tr>
		{/each}
	</table>
	<div class="flex flex-col ml-10 justify-between">
		<div class="flex flex-col max-w-64">
			<p class="mb-3 text-gray-500 dark:text-gray-400">
				In order to place a ship draw it's shape on the board and click on the button "Add".
			</p>
			<button
				type="button"
				class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800 mb-10 disabled:opacity-50"
				disabled={!is_valid_selection}
				on:click={add_ship}
			>
				Add
			</button>
		</div>

		{#if ship_sizes.length > 0}
			<div class="flex flex-col items-start text-center">
				<h5 class="text-xl font-bold dark:text-white w-100 md-2">Ships available</h5>
				<div class="flex flex-row items-start">
					{#each ship_sizes as size}
						<table class="mx-1">
							{#each { length: size } as _, i}
								<tr>
									<td class="border border-gray-200 dark:border-gray-700 cell_preview"> </td>
								</tr>
							{/each}
						</table>
					{/each}
				</div>
			</div>
		{/if}

		<button
			type="button"
			class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800 mb-10 disabled:opacity-50"
			disabled={ship_sizes.length !== 0}
			on:click={commit_board}
		>
			COMMIT
		</button>
		<button
			type="button"
			class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800 mb-10 disabled:opacity-50"
			on:click={() => {
				ship_sizes = [];
				ships = [
					[
						{
							i: 0,
							j: 0
						},
						{
							i: 1,
							j: 0
						},
						{
							i: 2,
							j: 0
						},
						{
							i: 3,
							j: 0
						},
						{
							i: 4,
							j: 0
						}
					],
					[
						{
							i: 0,
							j: 1
						},
						{
							i: 1,
							j: 1
						},
						{
							i: 2,
							j: 1
						},
						{
							i: 3,
							j: 1
						}
					],
					[
						{
							i: 0,
							j: 2
						},
						{
							i: 1,
							j: 2
						},
						{
							i: 2,
							j: 2
						}
					],
					[
						{
							i: 0,
							j: 3
						},
						{
							i: 1,
							j: 3
						}
					],
					[
						{
							i: 0,
							j: 4
						},
						{
							i: 1,
							j: 4
						}
					]
				];
				board_status = [
					2, 2, 2, 2, 2, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0,
					0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0
				];
			}}
		>
			Populate
		</button>
	</div>
</section>

<Toast />

<style>
	.cell {
		width: 70px;
		height: 70px;
		border: 1px solid black;
	}

	.cell_preview {
		width: 30px;
		height: 30px;
		border: 1px solid black;
	}
</style>
