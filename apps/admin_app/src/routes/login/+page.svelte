<script lang="ts">
  let { form } = $props();
</script>

<svelte:head>
  <title>Owner sign in · BaoBao Operations</title>
</svelte:head>

<main class="login-page">
  <section class="login-intro" aria-labelledby="login-title">
    <div class="brand">
      <span class="brand-mark" aria-hidden="true">B</span>
      <span>BaoBao Operations</span>
    </div>
    <p class="eyebrow">Pagadian City ride operations</p>
    <h1 id="login-title">Keep every ride moving safely.</h1>
    <p class="login-copy">
      Review drivers, monitor active trips, verify service credits, and handle support from
      one secure workspace.
    </p>
    <div class="login-note">
      <strong>Owner-only access</strong>
      <span>Accounts are provisioned privately. There is no public registration.</span>
    </div>
  </section>

  <section class="login-card" aria-labelledby="form-title">
    <div>
      <p class="eyebrow">Secure workspace</p>
      <h2 id="form-title">Sign in</h2>
      <p>Use the owner credentials created by the setup command.</p>
    </div>

    {#if form?.message}
      <p class="form-message error" role="alert">{form.message}</p>
    {/if}

    <form method="POST" class="form-stack">
      <label>
        Email address
        <input
          name="email"
          type="email"
          autocomplete="username"
          value={form?.email ?? ''}
          required
        />
      </label>
      <label>
        Password
        <input
          name="password"
          type="password"
          autocomplete="current-password"
          minlength="12"
          required
        />
      </label>
      <button class="button primary wide" type="submit">Open operations dashboard</button>
    </form>

    <p class="fine-print">
      Sessions expire after eight hours. Contact the system owner to rotate credentials.
    </p>
  </section>
</main>
