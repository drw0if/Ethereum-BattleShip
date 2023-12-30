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
	<div class="text-center m-5">
		<h1
			class="mb-4 text-4xl font-extrabold leading-none tracking-tight text-gray-900 md:text-5xl lg:text-6xl dark:text-white"
		>
			You cheated!
		</h1>
		<p
			class="mb-6 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 xl:px-48 dark:text-gray-400"
		>
			You did not manage to prove your board. Your opponent won the game and you lost your fees.
		</p>
		<p
			class="mb-6 text-lg font-normal text-gray-500 lg:text-xl sm:px-16 xl:px-48 dark:text-gray-400"
		>
			Please be nice the next time!
		</p>
		<button
			type="button"
			class="text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
			on:click={async () => {
				document.location.reload();
			}}>Quit</button
		>
	</div>
{:else}
	<p>Unknown state</p>
{/if}
