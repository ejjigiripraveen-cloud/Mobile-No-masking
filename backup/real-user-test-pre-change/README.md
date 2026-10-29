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
2. Copy `restore-profiles/` (the original values, trimmed to the 29 field settings + 2 class settings only – no user permissions or IP ranges) into a temporary SFDX project (`force-app/main/default/profiles/`).
3. `sf project deploy start -d force-app --target-org Sandbox --test-level NoTestRun` (dry-run first).
4. Confirm: FieldPermissions query / View Summary of a test user → Lead → Phone__c = Read again; classes off.

## Applied (R0.2–R0.7) – 2026-10-29, approved by the owner
- Dry-run 0Afft000000PQvNCAW (2/2, 0 errors), deploy **0Afft000000PQwzCAG** (2/2, Succeeded).
- Applied files: `sandbox-only/real-user-test/profiles/` (29 field settings + 2 class accesses per profile, nothing else).
- Verified: both profiles – 25 phone fields no access; Phone_Entry__c / Secondary_Phone_Entry__c Read+Edit; Phone_Masked__c / Call_To_Masked__c Read; MaskedPhonePanelController + MaskedDialServiceCTI enabled.
Manual parts of the restore (not in metadata):
- App Builder → Sales Lead Record Page (Masked POC) → Activation → remove the rows for Presales outbound / Presales TL.
- Permission Sets → Phone Reveal → remove Swapna.
- Users Ananthi R / Swapna / Deepika G → Mobile / Mcube Phone back to the values you noted before R0.10.
- Delete the Real Test leads.
