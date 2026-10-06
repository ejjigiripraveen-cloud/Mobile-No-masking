# Backup – existing components before Part 5b (Call history + logs)

Retrieved **read-only** from the sandbox on 2026-10-06, before any change. Checksums: `SHA256SUMS` (23 files).
Restore: `sf project deploy start --metadata-dir backup/v1.5.0-part5b-pre-change --target-org <org>` (trim `package.xml` first).

| Component | Type | vs baseline | 5b plan |
|---|---|---|---|
| `mCubeController` (1,969 lines) | Apex | Identical | `callRecords`: mask call numbers for masked users. `makeCall` / `makeCallZetta`: mask numbers in `log__c` Request / Response |
| `mCubeController_Test`, `mCubeControllerTestExtended` | Apex tests | Identical | No change (re-run) |
| `LeadHistoryandActivityController` | Apex | Identical | `GetData`: mask phone values in field history (Phone__c / Secondary_Phone__c are history-tracked) and call numbers, for masked users |
| `LeadHistoryandActivityControllerTest` | Apex test | Identical | No change (re-run) |
| `mCubeLightningPage` | Aura (call history list) | Identical | **No change** – shows what Apex returns |
| `LeadHistoryandActivityCmp` | Aura (history & activity, on 4 Lead pages) | Not in baseline – first backed up here | **No change** – shows what Apex returns |
