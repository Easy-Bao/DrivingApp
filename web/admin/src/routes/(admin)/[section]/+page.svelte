<script lang="ts">
  import {
    REPORTS,
    formatManila,
    nestedRecord,
    numberFrom,
    recordsFrom,
    statusClass,
    textFrom,
  } from '$lib/admin';

  let { data, form } = $props();
</script>

{#if form?.message}
  <div class:success={form.success} class="notice">{form.message}</div>
{/if}

{#if data.unavailable}
  <section class="empty-state panel">
    <p class="eyebrow">Service unavailable</p>
    <h2>Admin data could not be loaded</h2>
    <p>{data.message}</p>
  </section>
{:else if data.section === 'overview'}
  {@const counts = nestedRecord(data.payload, 'counts')}
  <section class="hero-panel">
    <div>
      <p class="eyebrow">Isolated Admin foundation</p>
      <h2>Owner operations are ready for manual testing</h2>
      <p>
        This first integration keeps authentication, complaint cases, reports,
        and audit history inside the Admin boundary. Passenger and Driver
        integrations remain intentionally deferred.
      </p>
    </div>
  </section>

  <section class="metrics-grid" aria-label="Admin overview">
    <article class="metric-card">
      <span>Open cases</span>
      <strong>{numberFrom(counts, 'openCases')}</strong>
    </article>
    <article class="metric-card">
      <span>Under review</span>
      <strong>{numberFrom(counts, 'underReviewCases')}</strong>
    </article>
    <article class="metric-card">
      <span>Audit events</span>
      <strong>{numberFrom(counts, 'auditEvents')}</strong>
    </article>
  </section>
{:else if data.section === 'cases'}
  {@const cases = recordsFrom(data.payload)}
  <div class="content-grid two-column">
    <section class="panel">
      <div class="panel-heading">
        <div>
          <p class="eyebrow">Manual intake</p>
          <h2>Record a complaint case</h2>
        </div>
      </div>
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
        <label>Ride ID, if applicable<input name="rideId" /></label>
        <label>Category<input name="category" required /></label>
        <label>Case notes<textarea name="notes" rows="4" required></textarea></label>
        <label>Reason for recording<textarea name="reason" rows="2" required></textarea></label>
        <button class="button primary" type="submit">Record case</button>
      </form>
    </section>

    <section class="panel table-panel">
      <div class="panel-heading">
        <div>
          <p class="eyebrow">Owner review</p>
          <h2>Complaint cases</h2>
        </div>
      </div>
      {#if cases.length === 0}
        <p class="empty-copy">No complaint cases match the current filters.</p>
      {:else}
        <div class="table-scroll">
          <table>
            <caption class="sr-only">Complaint cases awaiting owner review</caption>
            <thead>
              <tr><th>Case</th><th>Target</th><th>Status</th><th>Created</th><th>Update</th></tr>
            </thead>
            <tbody>
              {#each cases as caseRecord}
                <tr>
                  <td>
                    <strong>{textFrom(caseRecord, 'category')}</strong>
                    <small>{textFrom(caseRecord, 'notes')}</small>
                  </td>
                  <td>{textFrom(caseRecord, 'targetType')} · {textFrom(caseRecord, 'targetId')}</td>
                  <td><span class="status {statusClass(caseRecord.status)}">{textFrom(caseRecord, 'status')}</span></td>
                  <td>{formatManila(caseRecord.createdAt)}</td>
                  <td>
                    <form method="POST" action="?/updateCase" class="inline-form">
                      <input type="hidden" name="caseId" value={textFrom(caseRecord, 'id')} />
                      <select name="status" aria-label="Case status">
                        <option value="under_review">Under review</option>
                        <option value="resolved">Resolved</option>
                        <option value="dismissed">Dismissed</option>
                      </select>
                      <input name="resolution" placeholder="Resolution when closing" />
                      <input name="reason" placeholder="Reason" required />
                      <button class="button secondary" type="submit">Save</button>
                    </form>
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        </div>
      {/if}
    </section>
  </div>
{:else if data.section === 'reports'}
  <section class="panel">
    <div class="panel-heading">
      <div>
        <p class="eyebrow">Admin-local exports</p>
        <h2>Download CSV reports</h2>
      </div>
    </div>
    <div class="report-grid">
      {#each REPORTS as report}
        <a class="report-card" href="/reports/{report.slug}.csv">
          <strong>{report.label}</strong>
          <span>Download CSV</span>
        </a>
      {/each}
    </div>
  </section>
{:else if data.section === 'audit'}
  {@const audits = recordsFrom(data.payload)}
  <section class="panel table-panel">
    <div class="panel-heading">
      <div>
        <p class="eyebrow">Append-only history</p>
        <h2>Admin audit events</h2>
      </div>
    </div>
    {#if audits.length === 0}
      <p class="empty-copy">No Admin mutations have been recorded.</p>
    {:else}
      <div class="table-scroll">
        <table>
          <caption class="sr-only">Admin audit events</caption>
          <thead>
            <tr><th>Time</th><th>Action</th><th>Target</th><th>Outcome</th><th>Reason</th></tr>
          </thead>
          <tbody>
            {#each audits as audit}
              <tr>
                <td>{formatManila(audit.createdAt)}</td>
                <td>{textFrom(audit, 'action')}</td>
                <td>{textFrom(audit, 'targetType')} · {textFrom(audit, 'targetId')}</td>
                <td><span class="status {statusClass(audit.outcome)}">{textFrom(audit, 'outcome')}</span></td>
                <td>{textFrom(audit, 'reason')}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      </div>
    {/if}
  </section>
{/if}
