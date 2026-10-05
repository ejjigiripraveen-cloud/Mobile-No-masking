# v1.1.0 Foundations – Manual Deployment & Test Guide

For: the Salesforce admin deploying v1.1.0 by change set (sandbox → production) and testing it with Execute Anonymous.

> Order agreed in the roadmap: deploy and test in the **sandbox first**, then production.
> v1.1.0 adds new components only. **No existing component is changed. Users see no difference.**

---

## 1. Is there any UI in v1.1.0?

**No user-facing UI.** Reps, TLs and the Lead page are unchanged.

Admin-only screens:

| Where | What |
|---|---|
| App Launcher → **Phone Access Audits** | Audit tab + "All" list view (visible after assigning the *Phone Access Audit Viewer* permission set) |
| Setup → **Custom Metadata Types** → *Phone Masking Setting* / *Masked Phone Field* → **Manage Records** | Masking settings and the approved field list |

The first user-facing UI (masked phone panel on the Lead page) comes in **v1.2.0**.

---

## 2. Components to deploy (change set list)

Add these to an **outbound change set** in the sandbox. 45 items in total.

| # | Change set component type | Component | Count |
|---|---|---|---|
| 1 | Apex Class | `PhoneMaskingConfig`, `PhoneMaskUtil`, `MaskedDialService`, `MaskedDialServiceCTI` | 4 |
| 2 | Apex Class (tests) | `PhoneTestDataFactory`, `PhoneMaskingConfigTest`, `PhoneMaskUtilTest`, `MaskedDialServiceTest`, `MaskedDialServiceCTITest` | 5 |
| 3 | Custom Metadata Type | `Phone_Masking_Setting__mdt`, `Masked_Phone_Field__mdt` | 2 |
| 4 | Custom Field (on *Phone Masking Setting*) | `Visible_Prefix_Digits__c`, `Visible_Suffix_Digits__c`, `Mask_Character__c`, `Country_Code_To_Strip__c`, `Reveal_Seconds__c`, `Audit_Retention_Days__c`, `Resolve_Enabled__c`, `Audit_Enabled__c` | 8 |
| 5 | Custom Field (on *Masked Phone Field*) | `Object_API_Name__c`, `Field_API_Name__c`, `Display_Label__c`, `Sort_Order__c`, `Allow_Dial__c`, `Allow_Reveal__c`, `Active__c` | 7 |
| 6 | Phone Masking Setting (custom metadata record) | `Default` | 1 |
| 7 | Masked Phone Field (custom metadata record) | `Lead_Phone`, `Lead_Secondary_Phone` | 2 |
| 8 | Custom Object | `Phone_Access_Audit__c` | 1 |
| 9 | Custom Field (on *Phone Access Audit*) | `Action__c`, `Outcome__c`, `User__c`, `Record_Id__c`, `Object_Name__c`, `Field_Key__c`, `Masked_Number__c`, `Channel__c`, `Reason__c`, `Message__c`, `Event_Time__c` | 11 |
| 10 | List View | `Phone_Access_Audit__c.All` | 1 |
| 11 | Tab | `Phone Access Audits` | 1 |
| 12 | Permission Set | `Phone_Access_Audit_Viewer` | 1 |
| | | **Do not add any profile or any other existing component** | |

Tip: in the change set, use **View/Add Dependencies** to confirm nothing is missing. It should list only standard Lead / User fields as dependencies.

### Pre-checks in the target org (production)

| Check | Why |
|---|---|
| Lead fields `Phone__c` and `Secondary_Phone__c` exist | Approved field list and tests use them |
| Apex class `Utility` exists with `public static Boolean bypassLeadTrigger` | Tests use it to switch off the existing Lead trigger for test data |
| Profiles **Standard User** and **Minimum Access - Salesforce** exist | Tests create users with them |
| Deployment connection sandbox → production allows inbound change sets | Setup → Deployment Settings |

### Deploy settings

| Setting | Value |
|---|---|
| Test option | **Run specified tests** |
| Tests | `PhoneMaskingConfigTest`, `PhoneMaskUtilTest`, `MaskedDialServiceTest`, `MaskedDialServiceCTITest` |
| Expected | 42 tests pass · coverage PhoneMaskUtil 100%, MaskedDialService 100%, PhoneMaskingConfig 98.2%, MaskedDialServiceCTI 93.5% (sandbox validation 0Afft000000LMITCA4) |

Recommended: **Validate** the inbound change set first, then **Quick Deploy**.

---

## 3. After deployment (access)

| Step | Where |
|---|---|
| Assign **Phone Access Audit Viewer** to the admins who review audits | Setup → Permission Sets → Phone Access Audit Viewer → Manage Assignments |
| No other access needed | Apex classes are not called by any screen yet |

---

## 4. Testing step by step

### Step 1 – Deployment succeeded
Setup → **Deployment Status** → the change set deployment shows **Succeeded** and 42 tests passed.

### Step 2 – Components are present
1. Setup → **Apex Classes** → the 9 classes are listed.
2. Setup → **Custom Metadata Types** → *Phone Masking Setting* → **Manage Records** → `Default` (2, 2, X, 91, 30, 365, both checkboxes ticked).
3. Setup → **Custom Metadata Types** → *Masked Phone Field* → **Manage Records** → `Lead_Phone`, `Lead_Secondary_Phone` (Active, Allow Dial, Allow Reveal ticked).
4. Setup → **Object Manager** → *Phone Access Audit* → 11 custom fields.
5. App Launcher → **Phone Access Audits** → tab opens (after Step 3 assignment), list is empty.

### Step 3 – Execute Anonymous tests
Developer Console → **Debug** → **Open Execute Anonymous Window** → paste the script → tick **Open Log** → **Execute** → in the log tick **Debug Only**.

| Script (in `scripts/apex/`) | Writes data? | Expected result |
|---|---|---|
| `v1.1.0-1-mask-format.apex` | No | `RESULT: 11 passed, 0 failed` and `PASS | null stays null` |
| `v1.1.0-2-settings.apex` | No | Values match the "expected" text on every line; 2 approved fields |
| `v1.1.0-3-dial-service.apex` – first put a **test Lead Id** in line 7 | Yes – 4 audit rows | 3a **Success**, masked like `98XXXXXX21`, `real number matches record: true` · 3b **Success** (or **Not Found** if no secondary) · 3c **Denied**, `number released: false` · 3d `"success":true`, `real number matches record: true` · 3e **Denied**, "Invalid record id." |
| `v1.1.0-4-audit-check.apex` | No | 4 rows: Dial / Success, Dial / Success or Not Found, Dial / Denied, Dial / Success · `Masked_Number__c` masked or empty – never a full number |
| `v1.1.0-5-cleanup-test-audits.apex` (optional) | Yes – deletes the test rows | "Deleted N test audit rows" |

The scripts never print a real phone number – they only check that the returned number matches the record.

Note: Execute Anonymous always runs as **you** (admin). Rep / no-access behaviour is proven by the unit tests (`runAs` a Standard User and a Minimum Access user); rep screens are tested from v1.2.0.

### Step 4 – Nothing changed for users
1. Open any Lead as yourself → page, `Phone__c` and click-to-dial exactly as before.
2. Login as a normal rep → open a Lead → exactly as before.

---

## 5. Rollback

Removes only the v1.1.0 components (nothing existing is touched). Audit rows are deleted with the object.

- **CLI:** `sf project deploy start --manifest manifest/v1.1.0/package-empty.xml --post-destructive-changes manifest/v1.1.0/destructiveChanges.xml --target-org <org>`
- **Manual:** delete in this order – permission set → tab → test classes → `MaskedDialServiceCTI` → `MaskedDialService` → `PhoneMaskUtil` → `PhoneMaskingConfig` → custom metadata records → custom metadata types → `Phone_Access_Audit__c`.
