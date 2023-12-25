<script>
	import { onMount } from 'svelte';
	import { defaultEvmStores as evm, web3, selectedAccount, contracts } from 'svelte-web3';
	import { Spinner } from './Spinner';
	import { StartingMenu } from './StartingMenu';
	import { GameStates, CONTRACT_ADDRESS } from '$lib/constants.js';

	import abi from '$lib/abi.js';

	let ctx = {
		game_state: GameStates.SettingUp,
		game_id: null,
		last_transaction_hash: null,

		set_state: (new_state) => {
			ctx.game_state = new_state;
		}
	};

	/*
        FOR DEBUG PURPOSE: set ctx and the game will jump at the specified state
    */

	onMount(async () => {
		evm.attachContract('BattleShip', CONTRACT_ADDRESS, abi);
		ctx.game_state = GameStates.NotStarted;
	});
</script>

<button
	on:click={async () => {
		const x = await $contracts.BattleShip.methods.get_free_games_length().call();
		console.log('Free games length: ', x);
	}}>DEBUG</button
>
{#if ctx.game_state === GameStates.SettingUp}
	<Spinner />
	<p class="text-center">Attaching to the contract</p>
{:else if ctx.game_state === GameStates.NotStarted}
	<StartingMenu bind:ctx />
{:else if ctx.game_state === GameStates.WaitingForOpponent}
	<p>Waiting for opponent</p>
{:else if ctx.game_state === GameStates.FeeNegotiation}
	<p>Fee negotiation</p>
{:else if ctx.game_state === GameStates.WaitingCommitment}
	<p>Waiting for commitment</p>
{:else if ctx.game_state === GameStates.WaitingForMove}
	<p>Waiting for move</p>
{:else if ctx.game_state === GameStates.WaitingForProof}
	<p>Waiting for proof</p>
{:else if ctx.game_state === GameStates.WaitingForReveal}
	<p>Waiting for reveal</p>
{:else if ctx.game_state === GameStates.GameOver}
	<p>Game over</p>
{:else if ctx.game_state === GameStates.WaitingForReceipt}
	<Spinner />
{:else}
	<p>Unknown state</p>
{/if}
