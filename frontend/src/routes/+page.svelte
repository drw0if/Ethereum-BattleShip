<script>
	import {
		defaultEvmStores,
		web3,
		selectedAccount,
		connected,
		chainId,
		chainData
	} from 'svelte-web3';
	import BattleShip from '../components/BattleShip.svelte';

	import { onMount } from 'svelte';

	onMount(() => {
		try{
			defaultEvmStores.setProvider();
		}
		catch{
			alert("Please enable Metamask on this page");
		}
	});
</script>

{#if !$connected}
	<p>Application not yet connected</p>
{:else}
	<BattleShip></BattleShip>
{/if}
