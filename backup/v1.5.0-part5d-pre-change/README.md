# Backup – existing components before Part 5d (Bulk push + Yotel push)

Retrieved **read-only** from the sandbox on 2026-10-07, before any change. Checksums: `SHA256SUMS` (29 files).
Restore: `sf project deploy start --metadata-dir backup/v1.5.0-part5d-pre-change --target-org <org>` (trim `package.xml` first).

| Component | Type | vs baseline | 5d plan |
|---|---|---|---|
| `LeadBulkPushController` | Apex | Identical | `getSelectedLeads`: customer mobile masked for masked users (1 line). Push reads numbers on the server – unchanged |
| `LeadYotelBulkPushController` | Apex | Identical | `getSelectedLeads`: customer mobile masked for masked users (1 line); debug line no longer logs the full number. Push unchanged |
| `LeadBulkPushControllerTest`, `LeadYotelBulkPushControllerTest` | Apex tests | Identical | No change (re-run) |
| `leadBulkPush`, `leadYotelPush` | LWC | Identical | **No change** |
| `leadBulkPushApp`, `LeadYotelPushApp`, `leadBulkPushWrapper`, `leadYotelPushWrapper` | Aura (wrappers) | Not in baseline – first backed up here | **No change** |
| `BulkLeadPUSHpage`, `BulkLeadPushYotel` | Visualforce (list buttons host) | Not in baseline – first backed up here | **No change** |
