<script lang="ts">
  import {
    REPORTS,
    formatCentavos,
    formatManila,
    isRecord,
    recordsFrom,
    type AdminRecord,
  } from '$lib/admin';

  let { data } = $props();

  let reportName = $derived(REPORTS.find((report) => report.slug === data.report)?.label ?? 'Report');
  let rows = $derived(recordsFrom(data.payload, data.report, 'items', 'records'));
  let columns = $derived(reportColumns(rows));

  function reportColumns(records: AdminRecord[]): string[] {
    const hidden = new Set(['before', 'after', 'metadata']);
    return [
      ...new Set(records.flatMap((record) => Object.keys(record)).filter((key) => !hidden.has(key))),
    ].slice(0, 8);
  }

  function label(value: string): string {
    return value.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/^./, (letter) => letter.toUpperCase());
  }

  function display(record: AdminRecord, key: string): string {
    const value = record[key];
    if (key.toLowerCase().includes('centavos')) {
      return formatCentavos(value);
    }
    if ((key.endsWith('At') || key === 'timestamp') && value) {
      return formatManila(value);
    }
    if (isRecord(value)) {
      return JSON.stringify(value);
    }
    return value === null || value === undefined || value === '' ? '—' : String(value);
  }
</script>

<svelte:head>
  <title>{reportName} report · BaoBao Operations</title>
</svelte:head>

<article class="print-report">
  <header>
    <div>
      <p class="eyebrow">BaoBao Operations · Pagadian City</p>
      <h1>{reportName} report</h1>
      <p>Generated {formatManila(data.generatedAt)} · Asia/Manila</p>
    </div>
    <button class="button primary print-button" type="button" onclick={() => window.print()}>
      Print / Save as PDF
    </button>
  </header>

  <div class="table-wrap">
    <table>
      <caption>{reportName} operational records</caption>
      <thead>
        <tr>
          {#each columns as column}<th>{label(column)}</th>{/each}
        </tr>
      </thead>
      <tbody>
        {#each rows as row}
          <tr>{#each columns as column}<td>{display(row, column)}</td>{/each}</tr>
        {:else}
          <tr><td colspan={Math.max(columns.length, 1)} class="table-empty">No records match this report.</td></tr>
        {/each}
      </tbody>
    </table>
  </div>

  <footer>Internal operational record · Owner-generated</footer>
</article>
