<script>
	export let ctx;
</script>

<div>
	<button
		type="button"
		class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
		on:click={async () => {
			console.log('Current context: ', ctx);
		}}>DEBUG</button
	>
	<button
		type="button"
		class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
		on:click={async () => {
			console.log('Current context: ', ctx);
		}}
	>
		PRINT STATE
	</button>
	<button
		type="button"
		class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
		on:click={async () => {
			let x = {};

			Object.keys(ctx).forEach((key) => {
				if (typeof ctx[key] === 'bigint') {
					x[key] = ctx[key].toString();
				} else {
					x[key] = ctx[key];
				}
			});

			ctx.game_id = ctx.game_id.toString();
			if (ctx.opponent_id) {
				ctx.opponent_id = ctx.opponent_id.toString();
			}
			if (ctx.last_block_received) {
				ctx.last_block_received = ctx.last_block_received.toString();
			}

			window.localStorage.setItem('ctx', JSON.stringify(x));
		}}
	>
		SAVE STATE
	</button>
	<button
		type="button"
		class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
		on:click={async () => {
			const big_int_fields = ['game_id', 'opponent_id', 'last_block_received'];

			let x = JSON.parse(window.localStorage.getItem('ctx'));

			big_int_fields.forEach((key) => {
				if (x[key]) {
					x[key] = BigInt(x[key]);
				}
			});

			ctx = x;
		}}
	>
		LOAD STATE
	</button>
</div>
