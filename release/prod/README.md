# Production Release Bundle – Parts 1 and 2

Deploy-ready copies (Metadata API format) of the exact source that was deployed and tested in the
sandbox. At the end of the project, deploy these folders to production in the order below, after any
later parts that change them have been rebuilt (see "Rebuild").

| Folder | Part | For | Sandbox deploy (tested) |
|---|---|---|---|
| `part1-foundations/` | Part 1 – v1.1.0 | **Production – everyone** | 0Afft000000LO8zCAG · 42 tests · 93.5–100% |
| `part2-panel/` | Part 2 – v1.2.0 | **Production – everyone** | 0Afft000000LRq1CAG · 11 tests · 100% |
| `part2-pilot/` | Part 2 – v1.2.0 | **Production pilot only** (removed after go-live) | 0Afft000000LRq1CAG (page) · 0Afft000000LRzhCAG (profile) |

Checksums of every file: `SHA256SUMS`. Full component list and order: `docs/Mobile_Masking_Component_Register.xlsx` → sheet *Prod Deployment List*.

---

## What is in each folder

### part1-foundations (deploy first)
| Type | Components |
|---|---|
| Custom metadata types | `Phone_Masking_Setting__mdt` (8 fields), `Masked_Phone_Field__mdt` (7 fields) |
| Custom metadata records | `Phone_Masking_Setting.Default`, `Masked_Phone_Field.Lead_Phone`, `Masked_Phone_Field.Lead_Secondary_Phone` |
| Custom object | `Phone_Access_Audit__c` (11 fields, list view All) + tab |
| Apex | `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI` |
| Apex tests | `PhoneTestDataFactory`, `PhoneMaskingConfigTest`, `PhoneMaskUtilTest`, `MaskedDialServiceTest`, `MaskedDialServiceCTITest` |
| Permission set | `Phone_Access_Audit_Viewer` |

### part2-panel (deploy second)
| Type | Components |
|---|---|
| Apex | `MaskedPhonePanelController` + `MaskedPhonePanelControllerTest` |
| LWC | `maskedPhonePanel` (Jest tests are excluded – they never deploy) |

### part2-pilot (only for the production pilot)
| Type | Components | Before deploying |
|---|---|---|
| Lightning page | `Sales_Lead_Record_Page_Masked_POC` | – |
| Profile overlay | `POC Masked Rep` (25 phone fields hidden, panel class access) | **Clone `Presales outbound` → `POC Masked Rep` in Setup first** |

---

## Pre-checks in production
1. Lead fields `Phone__c`, `Secondary_Phone__c` exist.
2. Apex class `Utility` has `public static Boolean bypassLeadTrigger` (used by the tests).
3. Profiles **Standard User** and **Minimum Access - Salesforce** exist (used by the tests).
4. Deployment user has "Modify All Data" / "Author Apex".

## Deploy commands (Salesforce CLI)
Replace `<prod>` with the production org alias. Always **validate first**, then quick-deploy the validation.

```bash
# 1. Part 1 – validate, then quick deploy
sf project deploy validate --metadata-dir release/prod/part1-foundations --target-org <prod> \
  --test-level RunSpecifiedTests --tests PhoneMaskingConfigTest --tests PhoneMaskUtilTest --tests MaskedDialServiceTest --tests MaskedDialServiceCTITest
sf project deploy quick --job-id <validation id> --target-org <prod>

# 2. Part 2 panel – validate, then quick deploy
sf project deploy validate --metadata-dir release/prod/part2-panel --target-org <prod> \
  --test-level RunSpecifiedTests --tests MaskedPhonePanelControllerTest
sf project deploy quick --job-id <validation id> --target-org <prod>

# 3. Pilot only – after cloning the POC profile in Setup
sf project deploy start --metadata-dir release/prod/part2-pilot --target-org <prod> --test-level NoTestRun
```

Without the CLI: build an outbound change set in the sandbox with the same components (list in the Excel register), test level **Run specified tests** with the test classes above.

## Manual steps after deploy
| # | Step | Where |
|---|---|---|
| 1 | Assign **Phone Access Audit Viewer** to the admins who review audits | Setup → Permission Sets |
| 2 | (Pilot) Activate `Sales_Lead_Record_Page_Masked_POC` for app *Gsquare Housing*, Desktop, record type *Pre Sales*, profile *POC Masked Rep* | Lightning App Builder → Activation |
| 3 | (Pilot) Assign the pilot users to *POC Masked Rep* | Setup → Users |

The `Pre_Sales` app cannot be deployed by metadata (two pairs of same-named "Analytics Cloud" profiles), so step 2 is always manual.

## Check after deploy
Run `scripts/apex/v1.1.0-1-mask-format.apex` and `v1.1.0-2-settings.apex` in Execute Anonymous (read-only) → `RESULT: 11 passed, 0 failed` and all settings as expected. Full test steps: `DEPLOYMENT_v1.1.0.md`, `TEST_PLAN.md`.

## Rollback
```bash
# Part 2 panel (remove from any Lightning page first)
sf project deploy start --manifest release/prod/package-empty.xml --post-destructive-changes release/prod/part2-panel-rollback-destructiveChanges.xml --target-org <prod>
# Part 1
sf project deploy start --manifest release/prod/package-empty.xml --post-destructive-changes release/prod/part1-foundations-rollback-destructiveChanges.xml --target-org <prod>
```
Pilot: deactivate the page in App Builder, move pilot users back to their profile, delete the page and the POC profile.

## Rebuild
Later parts change some of these components (for example Part 6 adds Reveal to `maskedPhonePanel`). Before the production deployment, rebuild from the final code:

```bash
bash scripts/release/build-prod-release.sh
```
Each new part adds its own folder (`part3-…`, `part4-…`) and a line to that script.
