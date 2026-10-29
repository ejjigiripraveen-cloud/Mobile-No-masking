# Backup before the real-user sandbox test (R0.1)

Taken 2026-10-29 from the sandbox (gsquaregroup--prodreplic) by a read-only retrieve. Nothing in the sandbox was changed.

| File | What it holds |
|---|---|
| `profiles/Presales outbound.profile-meta.xml` | Original access of the profile to the 29 phone / entry / masked fields (Lead, Related Source, Call Detail, Task, Event) and to MaskedPhonePanelController / MaskedDialServiceCTI |
| `profiles/Presales TL.profile-meta.xml` | Same for Presales TL |
| `applications/Pre_Sales.app-meta.xml` | Original Lightning page activations of the Gsquare Housing app (reference only – the app cannot be deployed) |
| `retrieve-package.xml` | What was retrieved |
| `restore-package.xml` | What the restore deploys (the 2 profiles only) |
| `SHA256SUMS` | Checksums |

Original state in short: both profiles **can read** Phone__c / Secondary_Phone__c (read-only), most other phone fields read + edit; Presales outbound has **no** access to the entry / masked fields; both classes **off**.

## Restore ("revoke") – only when the owner asks
Deploys the original field and class access of the 2 profiles back. Only the permissions listed in these files are touched (29 fields, 2 classes); nothing else on the profiles changes.

Steps (Claude does them on request):
1. Check `SHA256SUMS` (backup unchanged).
2. Copy `profiles/` into a temporary SFDX project (`force-app/main/default/profiles/`).
3. `sf project deploy start --manifest restore-package.xml --target-org Sandbox --test-level NoTestRun`
4. Confirm: View Summary of a test user → Lead → Phone__c = Read again.
Manual parts of the restore (not in metadata):
- App Builder → Sales Lead Record Page (Masked POC) → Activation → remove the rows for Presales outbound / Presales TL.
- Permission Sets → Phone Reveal → remove Swapna.
- Users Ananthi R / Swapna / Deepika G → Mobile / Mcube Phone back to the values you noted before R0.10.
- Delete the Real Test leads.
