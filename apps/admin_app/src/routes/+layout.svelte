<script lang="ts">
  import favicon from '$lib/assets/favicon.svg';
  import '../app.css';

  let { children } = $props();
</script>

<svelte:head>
  <link rel="icon" href={favicon} />
  <title>BaoBao Operations</title>
  <meta
    name="description"
    content="Secure operations dashboard for the BaoBao Pagadian ride service."
  />
</svelte:head>

{@render children()}
