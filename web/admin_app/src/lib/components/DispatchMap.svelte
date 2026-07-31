<script lang="ts">
  import { env } from '$env/dynamic/public';
  import { onMount } from 'svelte';
  import type { Map, Marker } from 'mapbox-gl';
  import 'mapbox-gl/dist/mapbox-gl.css';
  import { isRecord, numberFrom, type AdminRecord } from '$lib/admin';

  let {
    trips = [],
    requests = [],
  }: {
    trips?: AdminRecord[];
    requests?: AdminRecord[];
  } = $props();

  let container!: HTMLDivElement;
  let map = $state.raw<Map | null>(null);
  let mapbox = $state.raw<typeof import('mapbox-gl')['default'] | null>(null);
  let markers: Marker[] = [];
  let message = $state('Loading operations map…');

  function coordinates(record: AdminRecord): [number, number] | null {
    const nested = isRecord(record.pickup)
      ? record.pickup
      : isRecord(record.origin)
        ? record.origin
        : {};
    const latitude =
      numberFrom(record, 'pickupLatitude', 'originLatitude', 'latitude', 'lat') ||
      numberFrom(nested, 'latitude', 'lat');
    const longitude =
      numberFrom(record, 'pickupLongitude', 'originLongitude', 'longitude', 'lng', 'lon') ||
      numberFrom(nested, 'longitude', 'lng', 'lon');
    return latitude && longitude ? [longitude, latitude] : null;
  }

  onMount(() => {
    let destroyed = false;

    if (!env.PUBLIC_MAPBOX_TOKEN) {
      message = 'Add PUBLIC_MAPBOX_TOKEN to display the dispatch map.';
      return;
    }

    async function initialize(): Promise<void> {
      try {
        const module = await import('mapbox-gl');
        if (destroyed) {
          return;
        }
        mapbox = module.default;
        mapbox.accessToken = env.PUBLIC_MAPBOX_TOKEN;
        map = new mapbox.Map({
          container,
          style: 'mapbox://styles/mapbox/streets-v12',
          center: [123.296, 7.825],
          zoom: 12,
          attributionControl: true,
        });
        map.addControl(new mapbox.NavigationControl(), 'top-right');
        message = '';
      } catch {
        message = 'The dispatch map could not be loaded.';
      }
    }

    void initialize();
    return () => {
      destroyed = true;
      markers.forEach((marker) => marker.remove());
      map?.remove();
    };
  });

  $effect(() => {
    if (!map || !mapbox) {
      return;
    }

    markers.forEach((marker) => marker.remove());
    markers = [];

    const points = [
      ...requests.map((record) => ({ record, kind: 'request' })),
      ...trips.map((record) => ({ record, kind: 'trip' })),
    ]
      .map((point) => ({ ...point, coordinates: coordinates(point.record) }))
      .filter(
        (point): point is typeof point & { coordinates: [number, number] } =>
          point.coordinates !== null,
      );

    for (const point of points) {
      const markerElement = document.createElement('span');
      markerElement.className = `map-marker ${point.kind}`;
      markerElement.title = point.kind === 'trip' ? 'Active trip pickup' : 'Open ride request';
      const marker = new mapbox.Marker({ element: markerElement })
        .setLngLat(point.coordinates)
        .addTo(map);
      markers.push(marker);
    }

    if (points.length > 1) {
      const bounds = new mapbox.LngLatBounds();
      points.forEach((point) => bounds.extend(point.coordinates));
      map.fitBounds(bounds, { padding: 56, maxZoom: 14 });
    } else if (points.length === 1) {
      map.easeTo({ center: points[0].coordinates, zoom: 14 });
    }
  });
</script>

<div class="dispatch-map">
  <div class="map-canvas" bind:this={container} aria-label="Map of active trips and open requests"></div>
  {#if message}
    <div class="map-message" role="status">{message}</div>
  {/if}
  <div class="map-legend" aria-label="Map legend">
    <span><i class="request" aria-hidden="true"></i> Open request</span>
    <span><i class="trip" aria-hidden="true"></i> Active trip</span>
  </div>
</div>
