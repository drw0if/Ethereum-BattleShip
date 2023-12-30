<script>
	import { defaultEvmStores as evm, web3, selectedAccount, contracts } from 'svelte-web3';
	import Specification from '$lib/Specification.pdf';
	//import Documentation from '$lib/Documentation.pdf';

	import '../app.css';

	const address_pretty_print = (address) => {
		return address.slice(0, 6) + '...' + address.slice(-4);
	};
</script>

<svelte:head>
	<title>Home</title>
	<meta name="description" content="just b00k" />
</svelte:head>

<section class="bg-gray-50 dark:bg-gray-900 min-h-screen flex flex-col justify-between">
	<nav class="bg-white border-gray-200 dark:border-gray-600 dark:bg-gray-900 border-y">
		<div class="flex flex-wrap justify-between items-center mx-auto max-w-screen-xl p-4">
			<a href="/" class="flex items-center space-x-3 rtl:space-x-reverse">
				<span class="self-center text-2xl font-semibold whitespace-nowrap dark:text-white"
					>BattleShip</span
				>
			</a>

			<!-- svelte-ignore a11y-click-events-have-key-events -->
			<p
				class="font-bold hover:bg-gray-400 p-4 rounded cursor-pointer"
				title={$selectedAccount}
				on:click={() => {
					if ($selectedAccount) {
						navigator.clipboard.writeText($selectedAccount);
					}
				}}
			>
				Account: {$selectedAccount ? address_pretty_print($selectedAccount) : 'No account'}
			</p>
		</div>
	</nav>

	<slot />

	<footer class="bg-white rounded-lg shadow m-4 dark:bg-gray-800">
		<div class="w-full mx-auto max-w-screen-xl p-4 md:flex md:items-center md:justify-between">
			<span class="text-sm text-gray-500 sm:text-center dark:text-gray-400"
				>© 2023 <a href="/" class="hover:underline">paleandro™</a>. All Rights Reserved.
			</span>
			<ul
				class="flex flex-wrap items-center mt-3 text-sm font-medium text-gray-500 dark:text-gray-400 sm:mt-0"
			>
				<li>
					<a href={Specification} class="hover:underline me-4 md:me-6">About</a>
				</li>
				<li>
					<a href={Specification} class="hover:underline me-4 md:me-6">TODO: Documentation</a>
				</li>
				<li>
					<a
						href="https://github.com/drw0if/Ethereum-BattleShip"
						class="hover:underline me-4 md:me-6">Source</a
					>
				</li>
			</ul>
		</div>
	</footer>
</section>

<style>
</style>
