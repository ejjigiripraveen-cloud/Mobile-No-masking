# Backup – existing components before Part 4 (v1.4.0)

Original code of every existing component Part 4 changes or depends on, retrieved **read-only** from the
sandbox before any change.

| | |
|---|---|
| Retrieved | 2026-10-06 |
| Org | gsquaregroup--prodreplic (sandbox, 00Dft000000AiZFEA0) |
| Format | Metadata API format – restore with `sf project deploy start --metadata-dir backup/v1.4.0-pre-change` (trim `package.xml` first) |
| Checksums | `SHA256SUMS` |

| Component | Type | vs baseline v1.0.0 | Part 4 plan |
|---|---|---|---|
| `LeadTrigger` | Apex trigger | Identical | Change: one call at the top (before-save entry-field copy) |
| `NewLeadCmp` | Aura (Lead "New" override, desktop + mobile) | Identical | Change: entry-field inputs for masked users |
| `NewRefLeadCmp` | Aura (quick action New Referral Lead) | Identical | Change: entry-field inputs for masked users |
| `RelatedSourceHandler` | Apex (number formatting + duplicate check, called by LeadTrigger) | Not in baseline – first backed up here | No change |
| `LeadTriggerHandler`, `LeadTriggerHandlerTest`, `LeadTriggerTest` | Apex | Identical | No change (existing tests re-run) |
| `New_Lead_Page`, `New_Lead_Page1_sales` | Lightning pages | **Changed since baseline** (+8 lines, tab display "Tabs"; no field change) | No change in Part 4 (Part 11) |
| `Lead.New_Referral_Lead` | Quick action | Not in baseline – first backed up here | No change |
