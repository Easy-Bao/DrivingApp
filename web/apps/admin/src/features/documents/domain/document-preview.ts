import { escapeXml } from '@/shared'
import type { DocumentPreviewInput } from '@/features/documents/types'

export function buildDocumentPreviewSvg(input: DocumentPreviewInput): string {
  const safeSide = input.side ? ` (${input.side} Scan)` : ''
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="600" height="360" viewBox="0 0 600 360">
  <rect width="600" height="360" fill="#f5f5f5"/>
  <rect x="24" y="24" width="552" height="312" fill="#ffffff" stroke="#d4d4d4" stroke-width="2"/>
  <rect x="24" y="24" width="552" height="58" fill="#171717"/>
  <text x="44" y="58" font-family="sans-serif" font-size="16" font-weight="bold" fill="#ffffff">${escapeXml(input.title)}${escapeXml(safeSide)}</text>
  <text x="44" y="114" font-family="sans-serif" font-size="12" fill="#737373">REPUBLIC OF THE PHILIPPINES · PAGADIAN CITY REGULATORY COPY</text>
  <text x="44" y="150" font-family="sans-serif" font-size="18" font-weight="bold" fill="#171717">${escapeXml(input.holder)}</text>
  <text x="44" y="182" font-family="sans-serif" font-size="13" fill="#404040">${escapeXml(input.subtitle || input.authority)}</text>
  <text x="44" y="218" font-family="monospace" font-size="13" font-weight="bold" fill="#171717">REF / FILE: ${escapeXml(input.plateOrRef)}</text>
  <rect x="44" y="250" width="210" height="36" fill="#ecfdf5" stroke="#a7f3d0"/>
  <text x="58" y="273" font-family="monospace" font-size="12" font-weight="bold" fill="#065f46">${escapeXml(input.docId)} · SEAL VERIFIED</text>
</svg>`
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
}
