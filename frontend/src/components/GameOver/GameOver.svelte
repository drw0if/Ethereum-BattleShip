<script>
	import { Spinner } from '../Spinner';
	import { web3, selectedAccount, contracts } from 'svelte-web3';
	import { GameStates } from '$lib/constants.js';
	export let ctx;

	let winner = null;

	$contracts.BattleShip.events
		.GameOver({
			filter: { game_id: ctx.game_id },
			fromBlock: ctx.last_block_received
		})
		.on('data', (event) => {
			// Winner is
			winner = event.returnValues.winner;
			console.log('The winner is: ', event.returnValues.winner);
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
</script>

{#if winner === null}
	<Spinner />
	<p class="text-center">Fetching the winner</p>
{:else}
	<p class="text-center">The winner is: {winner}</p>
{/if}
