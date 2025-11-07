# Planning & Proposal

## 1. Project Overview
- **Name:** FamilyStock  
- **Platform:** Native iOS (SwiftUI + SwiftData) with Supabase backend  
- **Purpose:** Centralize household pantry tracking, auto-generate shopping tasks, and record receipts within a single mobile experience.

## 2. Problem Statement
- Busy households often duplicate purchases or miss essentials because inventory is tracked informally.
- Spreadsheet or paper-based workflows are brittle on mobile and hard to share in real time.
- Existing shopping apps rarely connect “inventory → shopping → receipt” into a closed loop.

## 3. Goals
1. Provide an always-current view of pantry stock for every household member.
2. Trigger shopping tasks automatically when stock hits zero, minimizing manual effort.
3. Capture receipt data to analyze spending and replenish stock accurately.
4. Guarantee offline usability with automatic catch-up sync once connectivity returns.

## 4. Target Users
- Dual-income families, parents, or roommates coordinating grocery duties.
- Caregivers monitoring supplies for remote family members.
- Anyone frustrated by buying duplicates or forgetting staples.

## 5. Value Proposition
| Pain Point | FamilyStock Benefit |
| --- | --- |
| Hard to know what’s in stock | Unified, categorized inventory with quantity tracking. |
| Shopping lists require manual upkeep | Automatic list entries when quantities reach zero. |
| Offline environments break cloud apps | Offline-first SwiftData store + retry queue keeps changes safe. |
| Data scattered across tools | Supabase sync shares the same data across devices and accounts. |

## 6. Feature Highlights
1. **Inventory Management:** CRUD operations, categories, archive flag, quantity controls.
2. **Shopping List Automation:** Auto-add zero-stock items or manual adds with quantities/notes.
3. **Receipt Logging:** Convert completed shopping entries into receipts + line items.
4. **Sync Services:** Pull/push pipelines plus conflict resolution with Supabase.
5. **Offline Queue:** `PendingSync` queue with capped retries and manual cleanup.
6. **Settings & Auth:** Supabase authentication, local-only mode, sync status indicators.

## 7. Success Metrics (sample)
- 30-day retention ≥ 40%.
- 70% of surveyed users report fewer shopping mistakes.
- 99% eventual success rate for queued sync jobs.
- ≥30 average tracked items per household.

## 8. Delivery Cadence (example)
| Phase | Duration | Owners | Deliverables |
| --- | --- | --- | --- |
| Discovery | 2 weeks | PM + Design + Lead Eng | Personas, proposal (this doc), KPI targets |
| Design | 3 weeks | Lead Eng + Design | Requirements, architecture, UI mocks |
| Build | 6 weeks | iOS team | App implementation, CI, unit/UI tests |
| Validation | 2 weeks | QA + CS | UAT, TestFlight rollout |
| Launch & Iterate | ongoing | Cross-functional | KPI reviews, backlog grooming |

## 9. Risks & Mitigations
- **Backend incidents:** All writes land in local SwiftData + `PendingSync` for eventual delivery.
- **Future household sharing:** Every model stores `userId`, easing multi-user scenarios.
- **Security & compliance:** Supabase Auth + HTTPS; Secrets managed via plist template.
- **UX regression:** Accessibility identifiers plus UI tests to guard navigation/UI flows.

## 10. Executive Summary
FamilyStock unifies pantry management, shopping, and receipt tracking in a modern offline-first iOS app backed by Supabase. By automating repetitive tasks and safeguarding data across devices, the product aims to eliminate grocery friction and provide actionable visibility into household consumption.***
