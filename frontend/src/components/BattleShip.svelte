<script>
	import { onMount } from 'svelte';
	import { defaultEvmStores as evm, web3, selectedAccount, contracts } from 'svelte-web3';
	import { Spinner } from './Spinner';
	import { StartingMenu } from './StartingMenu';
	import { WaitingForOpponent } from './WaitingForOpponent';
	import { FeeNegotiation } from './FeeNegotiation';
	import { BuildBoard } from './BuildBoard';
	import { MakeMove } from './MakeMove';
	import { RevealBoard } from './RevealBoard';
	import { GameOver } from './GameOver';
	import { GameStates, CONTRACT_ADDRESS } from '$lib/constants.js';
	import Debug from './Debug.svelte';

	import abi from '$lib/abi.js';

	let ctx = {
		game_state: GameStates.SettingUp,
		game_id: null,
		last_block_received: null,
		fee: 0,
		opponent_id: null,
		ships: null,
		merkle_tree: null,
		nonces: null,

		set_state: (new_state, last_block_received = null) => {
			ctx.game_state = new_state;
			if (last_block_received) {
				ctx.last_block_received = last_block_received;
			}
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

<!--<Debug bind:ctx />-->
{#if ctx.game_state === GameStates.SettingUp}
	<Spinner />
	<p class="text-center">Attaching to the contract</p>
{:else if ctx.game_state === GameStates.NotStarted}
	<StartingMenu bind:ctx />
{:else if ctx.game_state === GameStates.WaitingForOpponent}
	<WaitingForOpponent bind:ctx />
{:else if ctx.game_state === GameStates.FeeNegotiation}
	<FeeNegotiation bind:ctx />
{:else if ctx.game_state === GameStates.WaitingCommitment}
	<BuildBoard bind:ctx />
{:else if ctx.game_state === GameStates.Game}
	<MakeMove bind:ctx />
{:else if ctx.game_state === GameStates.RevealBoard}
	<RevealBoard bind:ctx />
{:else if ctx.game_state === GameStates.GameOver}
	<GameOver bind:ctx />
{:else if ctx.game_state === GameStates.HallOfShame}
	<p>Don't cheat, bro...</p>
{:else}
	<p>Unknown state</p>
{/if}
