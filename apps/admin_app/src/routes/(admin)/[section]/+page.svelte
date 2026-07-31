<script lang="ts">
  import { invalidateAll } from '$app/navigation';
  import { onMount } from 'svelte';
  import DispatchMap from '$lib/components/DispatchMap.svelte';
  import {
    ADMIN_SECTIONS,
    REPORTS,
    formatCentavos,
    formatManila,
    isRecord,
    nestedRecord,
    numberFrom,
    recordsFrom,
    statusClass,
    textFrom,
    unwrapData,
    type AdminRecord,
  } from '$lib/admin';

  let { data, form } = $props();

  const descriptions = {
    overview: 'Today’s service health, queues, and actions that need attention.',
    drivers: 'Approve drivers and record off-app document verification.',
    dispatch: 'Monitor Pagadian ride activity and safely assign eligible drivers.',
    finance: 'Verify top-ups, protect the credit ledger, and schedule commission changes.',
    zones: 'Choose which Pagadian barangays can accept pickups and destinations.',
    cases: 'Resolve rider concerns and apply traceable account restrictions.',
    reports: 'Export operational records and review every owner action.',
  } as const;

  const statusFilters: Record<string, Array<{ value: string; label: string }>> = {
    drivers: [
      { value: 'pending', label: 'Pending' },
      { value: 'approved', label: 'Approved' },
      { value: 'rejected', label: 'Rejected' },
    ],
    finance: [
      { value: 'pending', label: 'Pending' },
      { value: 'approved', label: 'Approved' },
      { value: 'rejected', label: 'Rejected' },
    ],
    cases: [
      { value: 'open', label: 'Open' },
      { value: 'under_review', label: 'Under review' },
      { value: 'resolved', label: 'Resolved' },
      { value: 'dismissed', label: 'Dismissed' },
    ],
    reports: [
      { value: 'pending', label: 'Pending' },
      { value: 'approved', label: 'Approved' },
      { value: 'rejected', label: 'Rejected' },
      { value: 'open', label: 'Open' },
      { value: 'resolved', label: 'Resolved' },
      { value: 'completed', label: 'Completed' },
      { value: 'cancelled', label: 'Cancelled' },
    ],
  };

  let body = $derived(recordBody(data.payload));
  let extraBody = $derived(recordBody(data.extra));
  let topupChannels = $derived(recordsFrom(data.tertiary, 'channels', 'topupChannels'));
  let fareRules = $derived(recordsFrom(extraBody, 'fare_rules', 'fareRules'));
  let summary = $derived({
    ...body,
    ...nestedRecord(body, 'summary'),
    ...nestedRecord(body, 'counts'),
  });
  let records = $derived(sectionRecords(data.section, data.payload));
  let sectionTitle = $derived(
    ADMIN_SECTIONS.find((section) => section.slug === data.section)?.label ?? 'Admin',
  );

  function recordBody(value: unknown): AdminRecord {
    const unwrapped = unwrapData(value);
    return isRecord(unwrapped) ? unwrapped : {};
  }

  function sectionRecords(section: string, value: unknown): AdminRecord[] {
    const keys: Record<string, string[]> = {
      overview: ['recentActivity', 'activity', 'trips'],
      drivers: ['drivers'],
      dispatch: ['sessions', 'requests', 'openRequests'],
      finance: ['topups', 'topUps'],
      zones: ['zones', 'barangays'],
      cases: ['cases'],
      reports: ['audits', 'events'],
    };
    return recordsFrom(value, ...(keys[section] ?? []));
  }

  function itemId(record: AdminRecord): string {
    return textFrom(
      record,
      'id',
      'driverId',
      'driver_id',
      'topupId',
      'top_up_id',
      'caseId',
      'case_id',
      'zoneId',
      'psgcCode',
      'psgc_code',
      'requestId',
      'sessionId',
      'session_id',
    );
  }

  function filterHref(page: number): string {
    const query = new URLSearchParams();
    if (data.filters.status) query.set('status', data.filters.status);
    if (data.filters.from) query.set('from', data.filters.from);
    if (data.filters.to) query.set('to', data.filters.to);
    query.set('page', String(page));
    return `?${query}`;
  }

  function reportHref(path: string): string {
    const query = new URLSearchParams();
    if (data.filters.status) query.set('status', data.filters.status);
    if (data.filters.from) query.set('from', data.filters.from);
    if (data.filters.to) query.set('to', data.filters.to);
    const suffix = query.toString();
    return suffix ? `${path}?${suffix}` : path;
  }

  onMount(() => {
    const timer = window.setInterval(() => {
      if (['overview', 'dispatch', 'finance'].includes(data.section)) {
        void invalidateAll();
      }
    }, 10_000);
    return () => window.clearInterval(timer);
  });
</script>

<svelte:head>
  <title>{sectionTitle} · BaoBao Operations</title>
</svelte:head>

<section class="page-heading">
  <div>
    <p>{descriptions[data.section]}</p>
    <span class="updated">
      Updated {formatManila(data.lastUpdated)}
      {#if ['overview', 'dispatch', 'finance'].includes(data.section)}
        · refreshes every 10 seconds
      {/if}
    </span>
  </div>
  <button class="button secondary" type="button" onclick={() => invalidateAll()}>Refresh data</button>
</section>

{#if form?.message}
  <p class:success={form.success} class:error={!form.success} class="form-message" role="status">
    {form.message}
  </p>
{/if}

{#if !['overview', 'zones', 'dispatch'].includes(data.section)}
  <form method="GET" class="filter-bar" aria-label="Filter records">
    <label>
      Status
      <select name="status">
        <option value="">All statuses</option>
        {#each statusFilters[data.section] ?? [] as option}
          <option value={option.value} selected={data.filters.status === option.value}>
            {option.label}
          </option>
        {/each}
      </select>
    </label>
    <label>From<input name="from" type="date" value={data.filters.from} /></label>
    <label>To<input name="to" type="date" value={data.filters.to} /></label>
    <input name="page" type="hidden" value="1" />
    <button class="button secondary" type="submit">Apply filters</button>
  </form>
{/if}

{#if data.apiError}
  <section class="empty-state" role="alert">
    <span class="empty-icon" aria-hidden="true">!</span>
    <div>
      <h2>Admin API is not ready</h2>
      <p>{data.apiError}</p>
      <p>Start the gateway and admin service, then use “Refresh data.”</p>
    </div>
  </section>
{:else if data.section === 'overview'}
  <section class="metric-grid" aria-label="Operations summary">
    <article class="metric-card accent-blue">
      <span>Active trips</span>
      <strong>{numberFrom(summary, 'activeTrips', 'activeTripCount', 'active_rides')}</strong>
      <small>Currently moving</small>
    </article>
    <article class="metric-card accent-teal">
      <span>Registered drivers</span>
      <strong>{numberFrom(summary, 'drivers', 'driverCount')}</strong>
      <small>Operational driver records</small>
    </article>
    <article class="metric-card accent-amber">
      <span>Open requests</span>
      <strong>{numberFrom(summary, 'openRequests', 'openRequestCount', 'open_requests')}</strong>
      <small>Awaiting assignment</small>
    </article>
    <article class="metric-card accent-purple">
      <span>Top-ups waiting</span>
      <strong>{numberFrom(summary, 'pendingTopups', 'pendingTopupCount', 'pending_topups')}</strong>
      <small>Verify external receipt</small>
    </article>
  </section>

  <div class="content-grid two-thirds">
    <section class="panel">
      <div class="panel-heading">
        <div>
          <p class="eyebrow">Live operations</p>
          <h2>Recent activity</h2>
        </div>
        <a class="text-link" href="/dispatch">Open dispatch</a>
      </div>
      <div class="table-wrap">
        <table>
          <caption class="sr-only">Recent operations activity</caption>
          <thead>
            <tr><th>Event</th><th>Status</th><th>When</th></tr>
          </thead>
          <tbody>
            {#each records as record}
              <tr>
                <td>
                  <strong>{textFrom(record, 'title', 'action', 'type')}</strong>
                  <small>{textFrom(record, 'description', 'targetId', 'id')}</small>
                </td>
                <td>
                  <span class="status {statusClass(record.status)}">
                    {textFrom(record, 'status', 'outcome')}
                  </span>
                </td>
                <td>{formatManila(record.createdAt ?? record.updatedAt)}</td>
              </tr>
            {:else}
              <tr><td colspan="3" class="table-empty">No activity has been recorded yet.</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <aside class="panel attention-panel">
      <p class="eyebrow">Owner queue</p>
      <h2>Needs attention</h2>
      <a href="/drivers">
        <span>Driver reviews</span>
        <strong>{numberFrom(summary, 'pendingDrivers', 'pendingApprovalCount', 'pending_drivers')}</strong>
      </a>
      <a href="/finance">
        <span>Top-up checks</span>
        <strong>{numberFrom(summary, 'pendingTopups', 'pendingTopupCount', 'pending_topups')}</strong>
      </a>
      <a href="/cases">
        <span>Open cases</span>
        <strong>{numberFrom(summary, 'openCases', 'openCaseCount', 'open_cases')}</strong>
      </a>
      <a href="/zones">
        <span>Active barangays</span>
        <strong>{numberFrom(summary, 'activeZones', 'activeZoneCount', 'active_zones')}</strong>
      </a>
    </aside>
  </div>
{:else if data.section === 'drivers'}
  <div class="content-grid form-aside">
    <section class="panel">
      <div class="panel-heading">
        <div>
          <p class="eyebrow">Compliance queue</p>
          <h2>Driver applications</h2>
        </div>
        <span class="count">{records.length} shown</span>
      </div>
      <div class="table-wrap">
        <table>
          <caption class="sr-only">Driver approval and document status</caption>
          <thead>
            <tr><th>Driver</th><th>Approval</th><th>Documents</th><th>Action</th></tr>
          </thead>
          <tbody>
            {#each records as driver}
              <tr>
                <td>
                  <strong>{textFrom(driver, 'fullName', 'name')}</strong>
                  <small>{textFrom(driver, 'phoneNumber', 'email', 'id')}</small>
                </td>
                <td>
                  <span class="status {statusClass(driver.approvalStatus)}">
                    {textFrom(driver, 'approvalStatus', 'approval_status', 'status')}
                  </span>
                  <small>{textFrom(driver, 'restrictionStatus', 'restriction_status')}</small>
                </td>
                <td>
                  <span>{textFrom(driver, 'documentStatus', 'complianceStatus')}</span>
                  <small>{recordsFrom(driver, 'documents').length} checklist items</small>
                </td>
                <td>
                  <details>
                    <summary>Review</summary>
                    <form method="POST" action="?/driverApproval" class="compact-form">
                      <input type="hidden" name="driverId" value={itemId(driver)} />
                      <label>
                        Approval
                        <select name="status" required>
                          <option value="approved">Approve</option>
                          <option value="pending">Return to pending</option>
                          <option value="rejected">Reject</option>
                        </select>
                      </label>
                      <label>
                        Reason
                        <textarea name="reason" rows="2" required></textarea>
                      </label>
                      <button class="button primary" type="submit">Save approval</button>
                    </form>
                    <form method="POST" action="?/documentVerification" class="compact-form">
                      <input type="hidden" name="driverId" value={itemId(driver)} />
                      <label>
                        Document requirement
                        <select name="documentId" required>
                          <option value="">Choose a requirement</option>
                          {#each recordsFrom(data.extra, 'requirements') as requirement}
                            <option value={itemId(requirement)}>
                              {textFrom(requirement, 'name')}
                            </option>
                          {/each}
                        </select>
                      </label>
                      <label>
                        Result
                        <select name="status" required>
                          <option value="verified">Verified</option>
                          <option value="pending">Pending</option>
                          <option value="rejected">Rejected</option>
                          <option value="expired">Expired</option>
                        </select>
                      </label>
                      <label>
                        Expiry
                        <input name="expiresAt" type="date" />
                      </label>
                      <label>
                        Notes
                        <textarea name="notes" rows="2"></textarea>
                      </label>
                      <label>
                        Audit reason
                        <input name="reason" required />
                      </label>
                      <button class="button secondary" type="submit">Record check</button>
                    </form>
                  </details>
                </td>
              </tr>
            {:else}
              <tr><td colspan="4" class="table-empty">No driver applications found.</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <aside class="panel">
      <p class="eyebrow">Checklist setup</p>
      <h2>Document requirements</h2>
      <ul class="plain-list">
        {#each recordsFrom(data.extra, 'requirements') as requirement}
          <li>
            <strong>{textFrom(requirement, 'name')}</strong>
            <span class="status {statusClass(requirement.status)}">
              {textFrom(requirement, 'status')}
            </span>
          </li>
        {:else}
          <li class="muted">No requirements configured.</li>
        {/each}
      </ul>
      <form method="POST" action="?/documentRequirement" class="form-stack divided">
        <label>
          Requirement name
          <input name="name" placeholder="e.g. Professional driver’s license" required />
        </label>
        <label class="check-label">
          <input name="requiresExpiry" type="checkbox" value="true" />
          This document has an expiry date
        </label>
        <label>
          Reason for change
          <textarea name="reason" rows="2" required></textarea>
        </label>
        <button class="button primary" type="submit">Add requirement</button>
      </form>
    </aside>
  </div>
{:else if data.section === 'dispatch'}
  {@const requests = recordsFrom(data.payload, 'sessions', 'requests', 'openRequests')}
  {@const trips = recordsFrom(data.payload, 'rides', 'trips', 'activeTrips')}
  <section class="panel map-panel">
    <div class="panel-heading">
      <div>
        <p class="eyebrow">Live every 10 seconds</p>
        <h2>Pagadian dispatch map</h2>
      </div>
      <div class="inline-stats">
        <span><strong>{requests.length}</strong> open requests</span>
        <span><strong>{trips.length}</strong> active trips</span>
      </div>
    </div>
    <DispatchMap {requests} {trips} />
  </section>

  <div class="content-grid two-thirds">
    <section class="panel">
      <div class="panel-heading">
        <div><p class="eyebrow">Unassigned</p><h2>Open requests</h2></div>
      </div>
      <div class="table-wrap">
        <table>
          <caption class="sr-only">Open ride requests</caption>
          <thead><tr><th>Request</th><th>Route</th><th>Fare</th><th>Waiting</th></tr></thead>
          <tbody>
            {#each requests as request}
              <tr>
                <td><strong>{itemId(request)}</strong><small>{textFrom(request, 'passengerName')}</small></td>
                <td>{textFrom(request, 'pickupAddress', 'originAddress')} → {textFrom(request, 'destinationAddress')}</td>
                <td>{formatCentavos(request.fareCentavos ?? request.estimatedFareCentavos)}</td>
                <td>{formatManila(request.createdAt)}</td>
              </tr>
            {:else}
              <tr><td colspan="4" class="table-empty">There are no open ride requests.</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <aside class="panel">
      <p class="eyebrow">Owner-assisted dispatch</p>
      <h2>Manual assignment</h2>
      <p class="muted">Approval, restriction, zone, and service-credit checks cannot be bypassed.</p>
      <form method="POST" action="?/manualAssignment" class="form-stack">
        <label>
          Ride request ID
          <input name="requestId" required />
        </label>
        <label>
          Eligible driver ID
          <input name="driverId" list="eligible-drivers" required />
          <datalist id="eligible-drivers">
            {#each recordsFrom(data.payload, 'drivers', 'eligibleDrivers') as driver}
              <option value={itemId(driver)}>{textFrom(driver, 'fullName', 'name')}</option>
            {/each}
          </datalist>
        </label>
        <label>
          Assignment reason
          <textarea name="reason" rows="3" required></textarea>
        </label>
        <button class="button primary" type="submit">Check and assign</button>
      </form>
    </aside>
  </div>

  <section class="panel">
    <div class="panel-heading"><div><p class="eyebrow">In progress</p><h2>Active trips</h2></div></div>
    <div class="table-wrap">
      <table>
        <caption class="sr-only">Active ride trips</caption>
        <thead><tr><th>Trip</th><th>Driver</th><th>Passenger</th><th>Status</th><th>Started</th></tr></thead>
        <tbody>
          {#each trips as trip}
            <tr>
              <td><strong>{itemId(trip)}</strong></td>
              <td>{textFrom(trip, 'driverName', 'driverId')}</td>
              <td>{textFrom(trip, 'passengerName', 'passengerId')}</td>
              <td><span class="status {statusClass(trip.status)}">{textFrom(trip, 'status')}</span></td>
              <td>{formatManila(trip.startedAt ?? trip.updatedAt)}</td>
            </tr>
          {:else}
            <tr><td colspan="5" class="table-empty">No trips are active.</td></tr>
          {/each}
        </tbody>
      </table>
    </div>
  </section>
{:else if data.section === 'finance'}
  <section class="metric-grid three">
    <article class="metric-card accent-amber">
      <span>Pending top-ups</span>
      <strong>{records.filter((record) => textFrom(record, 'status') === 'pending').length}</strong>
      <small>Verify against the business e-wallet</small>
    </article>
    <article class="metric-card accent-blue">
      <span>Current commission</span>
      <strong>
        {numberFrom(
          nestedRecord(extraBody, 'commission'),
          'rateBasisPoints',
          'rate_basis_points',
          'commissionBasisPoints',
        ) / 100}%
      </strong>
      <small>Snapshotted per accepted ride</small>
    </article>
    <article class="metric-card accent-teal">
      <span>Top-up range</span>
      <strong>₱100–₱1,000</strong>
      <small>Purchased-credit policy</small>
    </article>
  </section>

  <div class="content-grid two-thirds">
    <section class="panel">
      <div class="panel-heading"><div><p class="eyebrow">Verification queue</p><h2>Driver top-ups</h2></div></div>
      <div class="table-wrap">
        <table>
          <caption class="sr-only">Driver service-credit top-up requests</caption>
          <thead><tr><th>Driver</th><th>Payment reference</th><th>Amount</th><th>Status</th><th>Review</th></tr></thead>
          <tbody>
            {#each records as topup}
              <tr>
                <td><strong>{textFrom(topup, 'driverName', 'driver_name', 'driverId', 'driver_id')}</strong><small>{textFrom(topup, 'senderName', 'sender_name')}</small></td>
                <td>{textFrom(topup, 'transactionReference', 'transaction_reference', 'reference')}</td>
                <td>{formatCentavos(topup.amountCentavos ?? topup.amount_centavos)}</td>
                <td><span class="status {statusClass(topup.status)}">{textFrom(topup, 'status')}</span></td>
                <td>
                  <details>
                    <summary>Review</summary>
                    <form method="POST" action="?/topupReview" class="compact-form">
                      <input type="hidden" name="topupId" value={itemId(topup)} />
                      <label>
                        Decision
                        <select name="status" required>
                          <option value="approved">Approve</option>
                          <option value="rejected">Reject</option>
                        </select>
                      </label>
                      <label>
                        Verification reason
                        <textarea name="reason" rows="2" required></textarea>
                      </label>
                      <button class="button primary" type="submit">Record decision</button>
                    </form>
                  </details>
                </td>
              </tr>
            {:else}
              <tr><td colspan="5" class="table-empty">No top-up requests found.</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <aside class="panel">
      <p class="eyebrow">Immutable ledger</p>
      <h2>Credit adjustment</h2>
      <p class="muted">Use only for a verified correction or account-closure refund.</p>
      <form method="POST" action="?/creditAdjustment" class="form-stack">
        <label>Driver ID<input name="driverId" required /></label>
        <label>
          Centavos (+ or −)
          <input name="amountCentavos" type="number" step="1" required />
        </label>
        <label>Reason<textarea name="reason" rows="3" required></textarea></label>
        <button class="button secondary" type="submit">Record adjustment</button>
      </form>
      <hr />
      <p class="eyebrow">Verified account closure</p>
      <h2>Refund unused credit</h2>
      <form method="POST" action="?/creditRefund" class="form-stack">
        <label>Driver ID<input name="driverId" required /></label>
        <label>
          Centavos
          <input name="amountCentavos" type="number" min="1" step="1" required />
        </label>
        <label>Reason<textarea name="reason" rows="3" required></textarea></label>
        <button class="button secondary" type="submit">Record refund</button>
      </form>
    </aside>
  </div>

  <div class="content-grid two-thirds">
    <section class="panel">
      <div class="panel-heading">
        <div><p class="eyebrow">Driver payment instructions</p><h2>Top-up channels</h2></div>
      </div>
      <div class="table-wrap">
        <table>
          <caption class="sr-only">Configured driver top-up channels</caption>
          <thead><tr><th>Channel</th><th>Destination</th><th>Status</th><th>Change</th></tr></thead>
          <tbody>
            {#each topupChannels as channel}
              <tr>
                <td>
                  <strong>{textFrom(channel, 'name')}</strong>
                  <small>{textFrom(channel, 'instructions')}</small>
                </td>
                <td>
                  {textFrom(channel, 'accountName', 'account_name')}
                  <small>{textFrom(channel, 'accountReference', 'account_reference')}</small>
                </td>
                <td>
                  <span class="status {Boolean(channel.isActive ?? channel.is_active) ? 'positive' : 'warning'}">
                    {Boolean(channel.isActive ?? channel.is_active) ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td>
                  <details>
                    <summary>Edit</summary>
                    <form method="POST" action="?/topupChannelUpdate" class="compact-form">
                      <input type="hidden" name="channelId" value={itemId(channel)} />
                      <label>Name<input name="name" value={textFrom(channel, 'name')} required /></label>
                      <label>
                        Account name
                        <input name="accountName" value={textFrom(channel, 'accountName', 'account_name')} required />
                      </label>
                      <label>
                        Account reference
                        <input name="accountReference" value={textFrom(channel, 'accountReference', 'account_reference')} required />
                      </label>
                      <label>Instructions<textarea name="instructions" rows="2">{textFrom(channel, 'instructions')}</textarea></label>
                      <input
                        type="hidden"
                        name="isActive"
                        value={Boolean(channel.isActive ?? channel.is_active) ? 'false' : 'true'}
                      />
                      <label>Audit reason<input name="reason" required /></label>
                      <button class="button secondary" type="submit">
                        {Boolean(channel.isActive ?? channel.is_active) ? 'Save and deactivate' : 'Save and activate'}
                      </button>
                    </form>
                  </details>
                </td>
              </tr>
            {:else}
              <tr><td colspan="4" class="table-empty">No top-up channels configured.</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <aside class="panel">
      <p class="eyebrow">New payment destination</p>
      <h2>Add top-up channel</h2>
      <form method="POST" action="?/topupChannelCreate" class="form-stack">
        <label>Channel name<input name="name" required /></label>
        <label>Account name<input name="accountName" required /></label>
        <label>Account reference<input name="accountReference" required /></label>
        <label>Driver instructions<textarea name="instructions" rows="3"></textarea></label>
        <label>Audit reason<textarea name="reason" rows="2" required></textarea></label>
        <button class="button primary" type="submit">Create channel</button>
      </form>
    </aside>
  </div>

  <section class="panel">
    <div class="panel-heading">
      <div><p class="eyebrow">Passenger pricing</p><h2>Fare rules</h2></div>
    </div>
    <div class="zone-grid">
      {#each fareRules as rule}
        <article class="zone-card" class:enabled={Boolean(rule.isActive ?? rule.is_active)}>
          <form method="POST" action="?/fareRuleUpdate" class="form-stack">
            <input
              type="hidden"
              name="serviceType"
              value={textFrom(rule, 'serviceType', 'service_type')}
            />
            <h3>{textFrom(rule, 'serviceType', 'service_type')}</h3>
            <label>Base fare<input name="baseFare" type="number" min="0" step="0.01" value={numberFrom(rule, 'baseFare', 'base_fare')} required /></label>
            <label>Per km<input name="perKmRate" type="number" min="0" step="0.01" value={numberFrom(rule, 'perKmRate', 'per_km_rate')} required /></label>
            <label>Per minute<input name="perMinuteRate" type="number" min="0" step="0.01" value={numberFrom(rule, 'perMinuteRate', 'per_minute_rate')} required /></label>
            <label>Minimum fare<input name="minimumFare" type="number" min="0" step="0.01" value={numberFrom(rule, 'minimumFare', 'minimum_fare')} required /></label>
            <label>Surge multiplier<input name="surgeMultiplier" type="number" min="1" max="3" step="0.01" value={numberFrom(rule, 'surgeMultiplier', 'surge_multiplier')} required /></label>
            <label>
              Status
              <select name="isActive" required>
                <option value="true" selected={Boolean(rule.isActive ?? rule.is_active)}>Active</option>
                <option value="false" selected={!Boolean(rule.isActive ?? rule.is_active)}>Inactive</option>
              </select>
            </label>
            <label>Audit reason<input name="reason" required /></label>
            <button class="button secondary" type="submit">Save fare rule</button>
          </form>
        </article>
      {:else}
        <div class="table-empty">No fare rules available.</div>
      {/each}
    </div>
  </section>

  <section class="panel">
    <div class="panel-heading">
      <div><p class="eyebrow">Fare configuration</p><h2>Schedule commission</h2></div>
      <span class="policy-note">30-day notice after the first real ride</span>
    </div>
    <form method="POST" action="?/pricingUpdate" class="inline-form">
      <label>
        Basis points
        <input name="commissionBasisPoints" type="number" min="0" max="5000" value="1000" required />
      </label>
      <label>
        Effective date
        <input name="effectiveAt" type="datetime-local" required />
      </label>
      <label class="grow">
        Audit reason
        <input name="reason" required />
      </label>
      <button class="button primary" type="submit">Schedule change</button>
    </form>
  </section>
{:else if data.section === 'zones'}
  <section class="panel">
    <div class="panel-heading">
      <div>
        <p class="eyebrow">Pagadian City</p>
        <h2>Barangay service coverage</h2>
      </div>
      <span class="count">{records.filter((zone) => Boolean(zone.isActive)).length} active of {records.length}</span>
    </div>
    <p class="panel-intro">
      Both pickup and destination must be inside active barangays. Boundaries must be verified
      before public enforcement.
    </p>
    <div class="zone-grid">
      {#each records as zone}
        <article class:enabled={Boolean(zone.isActive)} class="zone-card">
          <div>
            <span class="zone-code">{textFrom(zone, 'psgcCode', 'psgc_code', 'code')}</span>
            <h3>{textFrom(zone, 'name')}</h3>
            <span class="status {Boolean(zone.isActive) ? 'positive' : 'warning'}">
              {Boolean(zone.isActive) ? 'Active' : 'Inactive'}
            </span>
          </div>
          <form method="POST" action="?/zoneUpdate" class="compact-form">
            <input type="hidden" name="zoneId" value={itemId(zone)} />
            <input type="hidden" name="isActive" value={Boolean(zone.isActive) ? 'false' : 'true'} />
            <label>
              Reason
              <input name="reason" required />
            </label>
            <button class="button {Boolean(zone.isActive) ? 'danger' : 'primary'}" type="submit">
              {Boolean(zone.isActive) ? 'Deactivate' : 'Activate'}
            </button>
          </form>
        </article>
      {:else}
        <div class="table-empty">No barangays have been loaded.</div>
      {/each}
    </div>
  </section>
{:else if data.section === 'cases'}
  <div class="content-grid form-aside">
    <section class="panel">
      <div class="panel-heading"><div><p class="eyebrow">Support queue</p><h2>Complaint cases</h2></div></div>
      <div class="table-wrap">
        <table>
          <caption class="sr-only">Passenger and driver complaint cases</caption>
          <thead><tr><th>Case</th><th>Target</th><th>Category</th><th>Status</th><th>Update</th></tr></thead>
          <tbody>
            {#each records as supportCase}
              <tr>
                <td><strong>{itemId(supportCase)}</strong><small>{formatManila(supportCase.createdAt)}</small></td>
                <td>{textFrom(supportCase, 'targetType')} · {textFrom(supportCase, 'targetId')}</td>
                <td>{textFrom(supportCase, 'category')}</td>
                <td><span class="status {statusClass(supportCase.status)}">{textFrom(supportCase, 'status')}</span></td>
                <td>
                  <details>
                    <summary>Update</summary>
                    <form method="POST" action="?/caseUpdate" class="compact-form">
                      <input type="hidden" name="caseId" value={itemId(supportCase)} />
                      <label>
                        Status
                        <select name="status" required>
                          <option value="under_review">Under review</option>
                          <option value="resolved">Resolved</option>
                          <option value="dismissed">Dismissed</option>
                        </select>
                      </label>
                      <label>Resolution<textarea name="resolution" rows="2"></textarea></label>
                      <label>Audit reason<input name="reason" required /></label>
                      <button class="button primary" type="submit">Save case</button>
                    </form>
                  </details>
                </td>
              </tr>
            {:else}
              <tr><td colspan="5" class="table-empty">No cases found.</td></tr>
            {/each}
          </tbody>
        </table>
      </div>
    </section>

    <aside class="stacked-panels">
      <section class="panel">
        <p class="eyebrow">New complaint</p>
        <h2>Open a case</h2>
        <form method="POST" action="?/createCase" class="form-stack">
          <label>
            Target type
            <select name="targetType" required>
              <option value="ride">Ride</option>
              <option value="driver">Driver</option>
              <option value="passenger">Passenger</option>
            </select>
          </label>
          <label>Target ID<input name="targetId" required /></label>
          <label>Category<input name="category" required /></label>
        <label>Case notes<textarea name="notes" rows="3" required></textarea></label>
        <label>Audit reason<input name="reason" required /></label>
          <button class="button primary" type="submit">Open case</button>
        </form>
      </section>

      <section class="panel">
        <p class="eyebrow">Safety control</p>
        <h2>Restrict account</h2>
        <form method="POST" action="?/createRestriction" class="form-stack">
          <label>
            Account type
            <select name="targetType" required>
              <option value="driver">Driver</option>
              <option value="passenger">Passenger</option>
            </select>
          </label>
          <label>Account ID<input name="targetId" required /></label>
          <label>Related case ID (optional)<input name="caseId" /></label>
          <label>End time (blank = indefinite)<input name="endsAt" type="datetime-local" /></label>
          <label>Reason<textarea name="reason" rows="3" required></textarea></label>
          <button class="button danger" type="submit">Apply restriction</button>
        </form>
      </section>

      <section class="panel">
        <p class="eyebrow">Restore ride access</p>
        <h2>Lift restriction</h2>
        <form method="POST" action="?/liftRestriction" class="form-stack">
          <label>
            Account type
            <select name="targetType" required>
              <option value="driver">Driver</option>
              <option value="passenger">Passenger</option>
            </select>
          </label>
          <label>Restriction ID<input name="restrictionId" required /></label>
          <label>Audit reason<textarea name="reason" rows="3" required></textarea></label>
          <button class="button secondary" type="submit">Lift restriction</button>
        </form>
      </section>
    </aside>
  </div>
{:else if data.section === 'reports'}
  <section class="report-grid" aria-label="Download reports">
    {#each REPORTS as report}
      <article class="report-card">
        <span class="report-icon" aria-hidden="true">CSV</span>
        <div><h2>{report.label}</h2><p>Filtered operational records in Manila time.</p></div>
        <div class="report-actions">
          <a class="button secondary" href={reportHref(`/reports/${report.slug}.csv`)}>Download CSV</a>
          <a class="text-link" href={reportHref(`/print/${report.slug}`)}>Print / Save as PDF</a>
        </div>
      </article>
    {/each}
  </section>

  <section class="panel">
    <div class="panel-heading"><div><p class="eyebrow">Append-only</p><h2>Audit trail</h2></div></div>
    <div class="table-wrap">
      <table>
        <caption class="sr-only">Admin audit events</caption>
        <thead><tr><th>When</th><th>Action</th><th>Target</th><th>Reason</th><th>Outcome</th></tr></thead>
        <tbody>
          {#each records as audit}
            <tr>
              <td>{formatManila(audit.createdAt ?? audit.timestamp)}</td>
              <td><strong>{textFrom(audit, 'action')}</strong><small>{textFrom(audit, 'actorId')}</small></td>
              <td>{textFrom(audit, 'targetType')} · {textFrom(audit, 'targetId')}</td>
              <td>{textFrom(audit, 'reason', 'reference')}</td>
              <td><span class="status {statusClass(audit.outcome)}">{textFrom(audit, 'outcome')}</span></td>
            </tr>
          {:else}
            <tr><td colspan="5" class="table-empty">No audit events have been recorded.</td></tr>
          {/each}
        </tbody>
      </table>
    </div>
  </section>
{/if}

{#if !data.apiError && !['overview', 'zones', 'dispatch'].includes(data.section)}
  <nav class="pagination" aria-label="Record pages">
    {#if data.filters.page > 1}
      <a class="button secondary" href={filterHref(data.filters.page - 1)}>Previous</a>
    {/if}
    <span>Page {data.filters.page}</span>
    {#if records.length > 0}
      <a class="button secondary" href={filterHref(data.filters.page + 1)}>Next</a>
    {/if}
  </nav>
{/if}
