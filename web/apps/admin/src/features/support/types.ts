export type TicketRole = 'Passenger' | 'Driver'

export type TicketCategory = 'QRPh Top-Up' | 'Fare Dispute' | 'App Account' | 'Safety Escalation'

export type TicketPriority = 'High' | 'Normal'

export type TicketStatus = 'Open' | 'In Review' | 'Resolved'

export interface SupportTicket {
  id: string
  user: string
  phone: string
  role: TicketRole
  subject: string
  category: TicketCategory
  priority: TicketPriority
  status: TicketStatus
  lastMessage: string
  operatorReply?: string
  updatedAt: string
}

export interface ReplyToTicketInput {
  status: TicketStatus
  reply: string
}

export type ReviewDirection = 'Driver Review' | 'Passenger Review'

export type ReviewModerationState = 'Published' | 'Flagged for Review' | 'Hidden by Moderator'

export interface ReviewEntry {
  id: string
  tripId: string
  direction: ReviewDirection
  author: string
  subjectParty: string
  rating: number
  comment: string
  tags: string[]
  moderationState: ReviewModerationState
  moderationReason?: string
}

export type LostFoundStatus = 'Searching Driver' | 'Driver Confirmed Found' | 'Returned to Owner'

export interface LostFoundDriverOption {
  label: string
  phone: string
}

export interface LostFoundRecord {
  id: string
  itemDescription: string
  reportedBy: string
  contactPhone: string
  driver: string
  driverPhone: string
  tripId: string
  corridor: string
  status: LostFoundStatus
  handoffNote?: string
}

export interface CreateLostFoundInput {
  itemDescription: string
  reportedBy: string
  contactPhone: string
  tripId: string
  driver: string
}

export type FaqCategory = 'Fare Bidding' | 'Driver Top-Ups' | 'Safety & SOS' | 'Documents & TODA'

export type FaqAudience = 'Passenger' | 'Driver'

export interface FaqArticle {
  id: string
  category: FaqCategory
  audience: FaqAudience
  question: string
  answer: string
  views: number
  isPublished: boolean
}

export interface SaveFaqInput {
  id?: string
  category: FaqCategory
  audience: FaqAudience
  question: string
  answer: string
}

export type SupportActionResult = { ok: true } | { ok: false; error: string }
