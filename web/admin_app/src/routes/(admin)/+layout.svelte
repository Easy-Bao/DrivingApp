<script lang="ts">
  import { ADMIN_SECTIONS } from '$lib/admin';

  let { data, children } = $props();

  let activeSection = $derived(
    ADMIN_SECTIONS.find((section) => data.activePath === `/${section.slug}`) ?? ADMIN_SECTIONS[0],
  );
</script>

<a class="skip-link" href="#main-content">Skip to main content</a>

<div class="admin-shell">
  <aside class="sidebar">
    <a class="brand" href="/overview" aria-label="EasyRide operations home">
      <span class="brand-mark" aria-hidden="true">E</span>
      <span>
        EasyRide
        <small>Operations</small>
      </span>
    </a>

    <nav aria-label="Operations sections">
      {#each ADMIN_SECTIONS as section}
        <a
          href="/{section.slug}"
          class:active={data.activePath === `/${section.slug}`}
          aria-current={data.activePath === `/${section.slug}` ? 'page' : undefined}
        >
          <span class="nav-icon" aria-hidden="true">{section.icon}</span>
          <span>{section.label}</span>
        </a>
      {/each}
    </nav>

    <div class="sidebar-footer">
      <div class="environment">
        <span class="online-dot" aria-hidden="true"></span>
        Pagadian operations
      </div>
      <form method="POST" action="/logout">
        <button class="button ghost wide" type="submit">Sign out</button>
      </form>
    </div>
  </aside>

  <div class="workspace">
    <header class="topbar">
      <div>
        <p class="eyebrow">EasyRide operations</p>
        <h1>{activeSection.label}</h1>
      </div>
      <div class="topbar-meta">
        <span class="topbar-date">
          {new Intl.DateTimeFormat('en-PH', {
            weekday: 'short',
            month: 'short',
            day: 'numeric',
            timeZone: 'Asia/Manila',
          }).format(new Date())}
        </span>
        <span class="owner-avatar" aria-label="Signed in as owner">BO</span>
      </div>
    </header>

    <nav class="tablet-nav" aria-label="Operations sections">
      {#each ADMIN_SECTIONS as section}
        <a
          href="/{section.slug}"
          class:active={data.activePath === `/${section.slug}`}
          aria-current={data.activePath === `/${section.slug}` ? 'page' : undefined}
        >
          {section.shortLabel}
        </a>
      {/each}
    </nav>

    <main id="main-content" tabindex="-1">
      {@render children()}
    </main>
  </div>
</div>
