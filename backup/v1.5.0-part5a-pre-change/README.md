# Backup – existing components before Part 5a (Calling)

Retrieved **read-only** from the sandbox (gsquaregroup--prodreplic) on 2026-10-06, before any change.
All 33 files are identical to baseline v1.0.0. Checksums: `SHA256SUMS`.
Restore: `sf project deploy start --metadata-dir backup/v1.5.0-part5a-pre-change --target-org <org>` (trim `package.xml` first).

| Component | Type | 5a plan |
|---|---|---|
| `MakeCallController` | Apex | Change: masked list for masked users; resolve masked number on the server in `callCustomer` |
| `MakeCallControllerTest` | Apex test | No change (re-run) |
| `MakeCall` | Aura | **No change** – it shows whatever `readContacts` returns and sends it back |
| `OfflineCallAppAPI` | Apex | Change: masked numbers for masked users in `getLeadPhone` / `getOppPhone`; resolve masked number in `triggerCall` |
| `OfflineCallAppAPITest` | Apex test | No change (re-run) |
| `utilityCallComponent`, `offlineCallQuickActionCmp` | LWC (G-Talk) | **No change** – they send the number back to `triggerCall` |
| `CallPanel`, `CallPanel_Outbound` | Aura | Change: show `Phone_Masked__c` for masked users (Phone__c shows blank for them) |
