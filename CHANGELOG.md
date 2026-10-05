# Changelog – Mobile Number Masking

Versioning follows Semantic Versioning. Every version is a git tag in this folder's local-only history (never pushed).

Commands: `Revoke to original` (back to v1.0.0) · `Create checkpoint <name>` · `Revert to <version>`.
Reverting local files is immediate. Reverting the sandbox means redeploying the older metadata and removing newly added components, and happens only after explicit approval.

## v1.1.0 – Foundations (built locally 2026-10-05 · NOT deployed)

- **Commit Version:** v1.1.0
- **Type:** feat
- **Deployed to sandbox 2026-10-05** – quick deploy 0Afft000000LO8zCAG, 44/44 components. Read-only tests 1–2 passed (11/11 masking cases, all settings as expected).
- **Status (before deploy):** built locally and **validated (check-only) in sandbox 2026-10-05** – validation 0Afft000000LMITCA4, 42 tests passed, 0 failures. Nothing saved to the org. Deploy only when told; git tag `v1.1.0` is added after the sandbox test passes.
- **Coverage (validation):** PhoneMaskUtil 100% · MaskedDialService 100% · PhoneMaskingConfig 98.2% · MaskedDialServiceCTI 93.5%
- **Modified Assets (all new – no existing component changed):**
  - Apex: `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI`
  - Apex tests: `PhoneTestDataFactory`, `PhoneMaskingConfigTest`, `PhoneMaskUtilTest`, `MaskedDialServiceTest`, `MaskedDialServiceCTITest`
  - Custom metadata types: `Phone_Masking_Setting__mdt` (8 fields) + record `Default`; `Masked_Phone_Field__mdt` (7 fields) + records `Lead_Phone`, `Lead_Secondary_Phone`
  - Custom object: `Phone_Access_Audit__c` (11 fields, Private sharing, list view "All") + tab
  - Permission set: `Phone_Access_Audit_Viewer` (read-only audit access + tab)
- **Changelog:**
  - Masking engine: `98XXXXXX21` format, removes +91 / 0091 / leading 0, masks numbers inside free text, settings from custom metadata.
  - Secure real-number lookup for dialers: approved-field list, object access + record sharing check, kill switch, bulk-safe (1 query per object, 1 insert), audit of every request with the masked number only.
  - Open CTI entry point (`global webservice`) for the SlashRTC softphone.
- **Changes vs. the plan presented before building:** added `PhoneMaskingConfig` (shared settings reader); kill switch named `Resolve_Enabled__c` ("Real Number Lookup Enabled") – it stops number lookups and never un-masks anything; added `Message__c` to the audit object; added `Phone_Access_Audit_Viewer` permission set instead of editing the existing System Administrator profile.
- **Deploy:** `sf project deploy start --manifest manifest/v1.1.0/package.xml --test-level RunSpecifiedTests --tests PhoneMaskingConfigTest PhoneMaskUtilTest MaskedDialServiceTest MaskedDialServiceCTITest`
- **Validation fixes:** audit object Bulk/Streaming/Sharing flags aligned; plain `Database.insert(rows, false)` for audit rows; test assertion fixes (`===` instead of non-existent `Assert.areSame`, non-null assert messages).
- **Rollback:** `sf project deploy start --manifest manifest/v1.1.0/package-empty.xml --post-destructive-changes manifest/v1.1.0/destructiveChanges.xml` (removes only the new components; audit data, if any, is deleted with the object).

### Access sheet – v1.1.0

| Item | Who | Action |
|---|---|---|
| Apex `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService` | Nobody | Called only by other Apex; no class access needed. |
| Apex `MaskedDialServiceCTI` | Nobody yet | Added to the POC profile in v1.2.0 / v1.3.0, rep profiles at go-live. |
| `Phone_Access_Audit__c` object + tab | System Administrators | Assign permission set **Phone Access Audit Viewer** (read-only, View All). |
| `Phone_Access_Audit__c` | Reps / other users | No access. Audit rows are written by the service in system mode. |
| Custom metadata | Nobody | Read by Apex. Admins edit records in Setup → Custom Metadata Types. |
| Users | — | Only the permission set assignment above (optional until testing). |

## v1.0.0 – ORIGINAL BASELINE (2026-10-03)

- **Type:** baseline
- **Source:** sandbox `gsquaregroup--prodreplic` (org 00Dft000000AiZFEA0), retrieved read-only with `manifest/baseline-package.xml`.
- **Contents:** current state of every component the masking project may change:
  - 44 Apex classes (21 impacted + 23 test classes), 1 trigger (`LeadTrigger`)
  - 12 Aura bundles, 11 LWC bundles, 21 Visualforce pages (incl. MCube and SlashRTC adapters)
  - 4 Lightning pages, 4 Contact quick actions, 3 screen flows
  - 3 call centers (360CTI, SlashRTC, MCube)
  - 38 phone-related field definitions
  - All profiles and permission sets, scoped to the fields and classes above (field-level security and Apex class access)
- **Notes:** two system profiles named "Analytics Cloud Integration User" / "Analytics Cloud Security User" exist twice in the org; only one copy of each was retrieved. They are not affected by this project.
- **Immutable:** do not change this version unless explicitly told to update the baseline.
