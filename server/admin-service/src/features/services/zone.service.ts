export type Position = [number, number];
export type PolygonGeometry = {
  type: 'Polygon';
  coordinates: Position[][];
};
export type MultiPolygonGeometry = {
  type: 'MultiPolygon';
  coordinates: Position[][][];
};
export type ZoneGeometry = PolygonGeometry | MultiPolygonGeometry;

function isPointOnSegment(point: Position, start: Position, end: Position): boolean {
  if (start[0] === end[0] && start[1] === end[1]) {
    return point[0] === start[0] && point[1] === start[1];
  }
  const cross = (point[1] - start[1]) * (end[0] - start[0])
    - (point[0] - start[0]) * (end[1] - start[1]);
  if (Math.abs(cross) > 1e-10) return false;
  const dot = (point[0] - start[0]) * (end[0] - start[0])
    + (point[1] - start[1]) * (end[1] - start[1]);
  if (dot < 0) return false;
  const squaredLength = (end[0] - start[0]) ** 2 + (end[1] - start[1]) ** 2;
  return dot <= squaredLength;
}

function isPointInRing(point: Position, ring: Position[]): boolean {
  let inside = false;
  for (let current = 0, previous = ring.length - 1; current < ring.length; previous = current++) {
    const start = ring[previous];
    const end = ring[current];
    if (isPointOnSegment(point, start, end)) return true;
    const crossesLatitude = (end[1] > point[1]) !== (start[1] > point[1]);
    const longitudeAtLatitude = (
      (start[0] - end[0]) * (point[1] - end[1]) / (start[1] - end[1])
    ) + end[0];
    if (crossesLatitude && point[0] < longitudeAtLatitude) inside = !inside;
  }
  return inside;
}

function isPointInPolygon(point: Position, polygon: Position[][]): boolean {
  if (!polygon[0] || !isPointInRing(point, polygon[0])) return false;
  return !polygon.slice(1).some((hole) => isPointInRing(point, hole));
}

/**
 * Tests a longitude/latitude pair against Polygon or MultiPolygon GeoJSON.
 * Boundary points count as inside so adjacent barangays do not create dead strips.
 */
export function isPointInZone(point: Position, geometry: ZoneGeometry): boolean {
  if (geometry.type === 'Polygon') {
    return isPointInPolygon(point, geometry.coordinates);
  }
  return geometry.coordinates.some((polygon) => isPointInPolygon(point, polygon));
}
