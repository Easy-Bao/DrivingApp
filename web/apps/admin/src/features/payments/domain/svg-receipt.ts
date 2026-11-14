import { escapeXml } from '@/shared'

export { escapeXml }

export function buildReceiptPreviewSvg(params: {
  provider: string
  amountCentavos: number
  reference: string
  recipient: string
  sender: string
  timestamp: string
  accent: string
}): string {
  const safeAccent = /^#[0-9a-fA-F]{3,8}$/.test(params.accent) ? params.accent : '#0f172a'
  const amountText = (params.amountCentavos / 100).toFixed(2)
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="540" height="680" viewBox="0 0 540 680">
  <rect width="540" height="680" fill="#f8fafc"/>
  <rect x="30" y="28" width="480" height="624" fill="#ffffff" stroke="#e2e8f0" stroke-width="2"/>
  <rect x="30" y="28" width="480" height="84" fill="${safeAccent}"/>
  <text x="58" y="68" font-family="sans-serif" font-size="18" font-weight="700" fill="#ffffff">${escapeXml(params.provider)}</text>
  <text x="58" y="92" font-family="sans-serif" font-size="12" fill="#e2e8f0">Official Electronic Fund Transfer Receipt</text>
  <rect x="242" y="148" width="56" height="56" fill="#dcfce7"/>
  <path d="M256 176 l10 10 l18 -20" stroke="#15803d" stroke-width="4" fill="none" stroke-linecap="square" stroke-linejoin="miter"/>
  <text x="270" y="232" text-anchor="middle" font-family="sans-serif" font-size="13" font-weight="700" fill="#15803d">TRANSFER COMPLETED</text>
  <text x="270" y="274" text-anchor="middle" font-family="monospace" font-size="34" font-weight="800" fill="#0f172a">PHP ${escapeXml(amountText)}</text>
  <line x1="58" y1="304" x2="482" y2="304" stroke="#e2e8f0" stroke-dasharray="6 4"/>
  <text x="58" y="344" font-family="sans-serif" font-size="12" fill="#64748b">Recipient Merchant / Account</text>
  <text x="58" y="366" font-family="monospace" font-size="14" font-weight="700" fill="#0f172a">${escapeXml(params.recipient)}</text>
  <text x="58" y="408" font-family="sans-serif" font-size="12" fill="#64748b">Sender Source</text>
  <text x="58" y="430" font-family="monospace" font-size="14" font-weight="600" fill="#1e293b">${escapeXml(params.sender)}</text>
  <text x="58" y="472" font-family="sans-serif" font-size="12" fill="#64748b">Transaction Reference No.</text>
  <text x="58" y="494" font-family="monospace" font-size="15" font-weight="700" fill="#0f172a">${escapeXml(params.reference)}</text>
  <text x="58" y="536" font-family="sans-serif" font-size="12" fill="#64748b">Timestamp (PHT · UTC+8)</text>
  <text x="58" y="558" font-family="monospace" font-size="13" font-weight="600" fill="#334155">${escapeXml(params.timestamp)}</text>
  <rect x="58" y="586" width="424" height="40" fill="#f1f5f9"/>
  <text x="270" y="610" text-anchor="middle" font-family="monospace" font-size="11" fill="#475569">Pagadian City Dispatch Wallet Top-Up</text>
</svg>`
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
}

export function buildQrSvg(merchantCode: string, accentHex: string): string {
  const safeAccent = /^#[0-9a-fA-F]{3,8}$/.test(accentHex) ? accentHex : '#171717'
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" viewBox="0 0 180 180">
  <rect width="180" height="180" fill="#ffffff"/>
  <rect x="8" y="8" width="164" height="164" fill="#ffffff" stroke="#e5e5e5" stroke-width="2"/>
  <rect x="20" y="20" width="38" height="38" fill="none" stroke="${safeAccent}" stroke-width="6"/>
  <rect x="31" y="31" width="16" height="16" fill="#171717"/>
  <rect x="122" y="20" width="38" height="38" fill="none" stroke="${safeAccent}" stroke-width="6"/>
  <rect x="133" y="31" width="16" height="16" fill="#171717"/>
  <rect x="20" y="122" width="38" height="38" fill="none" stroke="${safeAccent}" stroke-width="6"/>
  <rect x="31" y="133" width="16" height="16" fill="#171717"/>
  <rect x="74" y="24" width="10" height="10" fill="#171717"/>
  <rect x="92" y="24" width="14" height="10" fill="${safeAccent}"/>
  <rect x="74" y="42" width="30" height="10" fill="#171717"/>
  <rect x="24" y="74" width="14" height="12" fill="#171717"/>
  <rect x="46" y="74" width="18" height="12" fill="${safeAccent}"/>
  <rect x="74" y="74" width="32" height="32" fill="#171717"/>
  <rect x="82" y="82" width="16" height="16" fill="#ffffff"/>
  <rect x="116" y="74" width="16" height="12" fill="#171717"/>
  <rect x="140" y="74" width="16" height="12" fill="${safeAccent}"/>
  <rect x="74" y="120" width="22" height="12" fill="${safeAccent}"/>
  <rect x="106" y="120" width="20" height="12" fill="#171717"/>
  <rect x="136" y="120" width="18" height="26" fill="#171717"/>
  <rect x="74" y="140" width="44" height="12" fill="#171717"/>
  <text x="90" y="168" font-family="monospace" font-size="9" font-weight="bold" fill="#171717" text-anchor="middle">${escapeXml(merchantCode)}</text>
</svg>`
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`
}
