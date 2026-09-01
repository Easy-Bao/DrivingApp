<script lang="ts">
  import favicon from '$lib/assets/favicon.svg';
  import '../app.css';

  let { children } = $props();
</script>

<svelte:head>
  <link rel="icon" href={favicon} />
  <title>EasyRide</title>
  <meta
    name="description"
    content="Secure operations dashboard for EasyRide in Pagadian City."
  />
</svelte:head>

{@render children()}
