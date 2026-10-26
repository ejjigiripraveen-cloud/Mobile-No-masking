# Mobile Number Masking – Real-User Sandbox Test (go-live rehearsal, Parts 1–6)

Written for the project owner. Run this **after** the POC tests in `PART_BY_PART_TEST_AND_DEPLOY.md` (Stage 1) and **before** anything goes to production.

Last updated: 2026-10-26 · Sandbox: gsquaregroup--prodreplic

---

## How the two test stages fit together
| Stage | Who is masked | Purpose | Guide |
|---|---|---|---|
| **Stage 1 – POC test** | 3 POC users (profile *POC Masked Rep*) | Prove each part works, safely | `PART_BY_PART_TEST_AND_DEPLOY.md` |
| **Stage 2 – Real-user test (this guide)** | **Real profiles** *Presales outbound* and *Presales TL* in the sandbox | Prove it works for real users **without** the POC profile – exactly what go-live will do | This file |

Masking rule (same code for everyone): **a user who cannot read `Lead.Phone__c` is masked.** Field access = profile **plus** permission sets.

---

## R0. Set-up in the sandbox (sandbox change – needs your approval)

Nothing below is done yet. Either you do it in Setup, or reply **"approve real-user test setup"** and I will (1) back up the current sandbox profiles first (retrieve, read-only), (2) make the changes, (3) record them, (4) restore them after the test if you want.

### R0.1 Real test users (sandbox copies – no production impact)
| Role | User | Profile | Dialer | Permission sets |
|---|---|---|---|---|
| Real rep (SlashRTC) | **Priya J** | Presales outbound | SlashRTC | none (clean test) |
| Real rep (MCube) | **Sharmili** (or Lalitha B / Muralidharan) | Presales outbound | MCube | check – see R0.4 |
| Real rep (360CTI) | one of the 3 Presales outbound 360CTI users | Presales outbound | 360CTI | check |
| Real Team Lead | **Swapna** | Presales TL | MCube | + Phone_Reveal (R0.5) |
| Unchanged user | any **Sales** / CRM profile user | not changed | – | – |
| Admin | you | System Administrator | – | Phone Access Audit Viewer |

⚠️ These are copies of **real employees**: their Mobile / Mcube Phone hold the employee's real phone. Before any test call, set the test user's **Mobile** and **Mcube Phone** to **your own** agent number (MCube rings the agent first), and use dummy customer numbers only.

### R0.2 Profiles *Presales outbound* and *Presales TL* – field access
Setup → Profiles → profile → **Object Settings** → object → Edit:

| Object | Field | Set to |
|---|---|---|
| Lead | Phone__c, Secondary_Phone__c, Phone (standard), MobilePhone, Full_phone_number__c, Phone_with_country_code__c, Secondary_phone_with_country_code__c, Secondary_Phones__c, Secondary_Mobile_No__c, Office_Phone_No__c, Spouse_Number__c, WhatsApp_Number__c, Register_your_WhatsApp_Number__c, Merge_Lead_Phone_No__c | Read ☐ Edit ☐ |
| Related_Source__c | Phone__c, Secondary_Phone__c, Register_your_WhatsApp_Number__c | Read ☐ Edit ☐ |
| Call_Detail__c | Call_To__c, Customer_Contact__c | Read ☐ Edit ☐ |
| Task | Call_From__c, Call_To__c, Caller_number__c | Read ☐ Edit ☐ |
| Event | Call_From__c, Call_To__c, Caller_number__c | Read ☐ Edit ☐ |
| Lead | Phone_Entry__c, Secondary_Phone_Entry__c | Read ☑ Edit ☑ |
| Lead | Phone_Masked__c | Read ☑ |
| Call_Detail__c | Call_To_Masked__c | Read ☑ |

(These are the same 25 fields hidden on the POC profile.)

### R0.3 Profiles – Apex class access
Both profiles → **Apex Class Access** → add **MaskedPhonePanelController**, **MaskedDialServiceCTI**.

### R0.4 Permission sets that would keep users unmasked
These grant Read on `Lead.Phone__c` (sandbox check 2026-10-26): **Sales_All_Access** (112 users), **Messaging_Permission_Set** (154), **sfdc_chatbot_service_permset** (155), **Extended_Access_on_Project_object** (3), Extended_as_to_CP_TL (0). Also check the 19 permission set groups.
- For this test: **use test users who have none of them** (Priya J has none). Check Sharmili / Swapna / the 360CTI user: Setup → Users → user → **Permission Set Assignments**.
- Do **not** change these permission sets now – R8 proves the issue; the fix is part of Part 11.

### R0.5 Reveal
Assign **Phone_Reveal** to **Swapna** (Setup → Permission Sets → Phone Reveal → Manage Assignments).

### R0.6 Lead page with the masked panel
Lightning App Builder → **Sales Lead Record Page (Masked POC)** → Edit → **Activation** → App, Record Type, and Profile → **Assign to Apps, Record Types, and Profiles** → Gsquare Housing / Desktop / **Pre Sales** / profiles **Presales outbound** and **Presales TL** → Save.
(At go-live the panel is added to the real pages instead – this is the rehearsal shortcut.)

### R0.7 Test leads (dummy numbers)
As admin create, owner = each test user, record type Pre Sales:
| Lead | Owner | Phone | Secondary |
|---|---|---|---|
| **Real Test P** | Priya J | 9000100001 | 9000100002 |
| **Real Test M** | Sharmili | 9000200001 | 9000200002 |
| **Real Test C** | 360CTI user | 9000300001 | – |
| **Real Test T** | Swapna | 9000400001 | 9000400002 |

### R0.8 Confirm the switch worked ⭐
Setup → Users → **Priya J** → **View Summary** → Field Permissions → Lead → **Phone__c = no Read**. Same for Sharmili, the 360CTI user and Swapna. If any shows Read → a permission set or group still grants it → fix before testing.

---

## R1. Foundations (Part 1) – no change expected
| # | As | Step | Expected |
|---|---|---|---|
| R1.1 | Admin | Execute Anonymous `scripts/apex/v1.1.0-1-mask-format.apex` | `RESULT: 11 passed, 0 failed` |
| R1.2 | Admin | `scripts/apex/v1.1.0-2-settings.apex` | All values as expected, 2 approved fields |
| R1.3 | Admin | R0.8 done for all 4 test users | Phone__c not readable |

---

## R2. Masked panel and hidden fields (Part 2)
| # | As | Step | Expected |
|---|---|---|---|
| R2.1 ⭐ | Priya J | Gsquare Housing → **Real Test P** | Phone Numbers panel `90XXXXXX01` / `90XXXXXX02`; no phone field visible anywhere (details, highlights, header, compact layout) |
| R2.2 ⭐ | Priya J | F12 → Network → F5 → Ctrl+F `100001` in the `aura` responses | Not found |
| R2.3 | Priya J | Leads tab → her usual list views | Phone columns empty / gone; lists work |
| R2.4 | Priya J | Reports she normally uses (Leads / Calls) | Phone columns empty; report runs |
| R2.5 | Priya J | Lead → related lists: Related Sources, Activities (Tasks / Events), Call Details | Phone / Call To / Caller number columns hidden |
| R2.6 📝 | Priya J | Global search `9000100001` | Found / not found → decides Part 8 |
| R2.7 | Priya J | Open a lead of another record type she can see | Normal page, no panel, phone fields hidden (panel on all pages only at go-live) |
| R2.8 | Sharmili, 360CTI user, Swapna | Their Real Test lead | Same masked panel |
| R2.9 ⭐ | Sales / CRM user (unchanged profile) | Any lead | Exactly as before, full numbers, no panel |
| R2.10 | Priya J | Salesforce mobile app → Real Test P | No full numbers anywhere |

---

## R3. Click-to-call (Part 3)
Phone utility must be ready (📞 not crossed out); test users' Mobile = your agent phone (R0.1).

| # | As | Step | Expected |
|---|---|---|---|
| R3.1 ⭐ | Priya J (SlashRTC) | Log in to SlashRTC → Real Test P → click Primary | Call connects |
| R3.2 ⭐ | Sharmili (MCube) | Real Test M → click Primary, then Secondary | Agent phone, then customer phone; connected |
| R3.3 | Priya J / Sharmili | F12 → Network during the click | Only Id, field, masked value sent; no full number |
| R3.4 📝 | 360CTI user | Real Test C → click Primary | **Expected NOT to dial** until 360 Degree Cloud updates their adapter – record what happens (error / nothing) |
| R3.5 ⭐ | Customer phone | Call the SlashRTC and MCube virtual numbers (lead number = your phone) | Screen pop opens the right lead for Priya J / Sharmili; call log record created |
| R3.6 | Admin | Phone Access Audits | Dial / Success rows for Priya J and Sharmili, masked only |
| R3.7 ⭐ | Sales / CRM user (unchanged) | Click a normal phone field | Calls exactly as before, no audit row |

---

## R4. Lead creation (Part 4)
| # | As | Step | Expected |
|---|---|---|---|
| R4.1 ⭐ | Priya J | Leads → New → `Real Test P2`, Phone 9000100011, Secondary 9000100012 → Save | Saved; panel masked; entry fields empty |
| R4.2 | Priya J | Lead → New Referral Lead → Phone 9000100021 → Save | Saved |
| R4.3 | Priya J | Real Test P2 → Secondary Phone (entry) → 9000100013 → Save | Panel `90XXXXXX13`; entry empty |
| R4.4 | Priya J | Leads → New with Phone 9000100011 (duplicate) | Same duplicate behaviour as today |
| R4.5 | Admin | Script A from the main guide with `LastName LIKE 'Real Test%'` | Real fields filled, entry fields empty |
| R4.6 | Admin | Script B (change primary via entry field) on Real Test P2 | Rejected with the primary-lock message |
| R4.7 | Admin | Round robin: check owner of the new leads | Same assignment behaviour as today |
| R4.8 ⭐ | Integration | A website / portal / API lead arrives (or Script C) | Saved as before, Phone__c filled |
| R4.9 | Sales / CRM user | Leads → New | Old form, unchanged |

---

## R5a. MakeCall and G-Talk
| # | As | Step | Expected |
|---|---|---|---|
| R5a.1 ⭐ | Sharmili | Real Test M → Make call → Select Number → Call (Mcube Phone = your phone) | Masked list; call connects |
| R5a.2 | Priya J | G-Talk utility on Real Test P → Call | Masked numbers; no error |
| R5a.3 | Admin | Audit | MCube (MakeCall) and G-Talk rows |
| R5a.4 | Priya J / Sharmili | **CallPanel / CallPanel_Outbound** (if on their pages) | ⚠️ Still shows the full number – **D1, known gap**, record where it appears |

## R5b. History and logs
| # | As | Step | Expected |
|---|---|---|---|
| R5b.1 | Admin | Edit Real Test P Phone → 9000100003 (creates history) + insert a Call_Detail__c (prep script in main guide, numbers 9000100099 → 9000100003) | – |
| R5b.2 ⭐ | Priya J | History & Activity → Field Updates / Calls | Masked old → new values and call numbers |
| R5b.3 | Admin | After R3.2 call: Script E (log__c) | Newest MCube log: no full number |

## R5c. Update Contact Details and Merge
| # | As | Step | Expected |
|---|---|---|---|
| R5c.1 ⭐ | Priya J | Real Test P → Update Contact Details → change only Email → Save | Success; numbers unchanged (Script F: no X saved) |
| R5c.2 | Priya J | Secondary → 9000100004 → Save; then Phone → 9000100005 → Save | Secondary saved; Phone rejected (locked) |
| R5c.3 | Priya J | Merge Lead → list / search | Masked numbers |

## R5d. Bulk / Yotel push
| # | As | Step | Expected |
|---|---|---|---|
| R5d.1 | Priya J | Leads list → Add Leads to Call List / Create Lead List For Yotel | "Insufficient privileges" – **same as today** (reps never had these) |
| R5d.2 | MIS Extended user | Same buttons → Cancel | Full numbers – MIS profile not changed (go-live decision) |

## R5e. WhatsApp chat
| # | As | Step | Expected |
|---|---|---|---|
| R5e.1 | Priya J | A lead whose page has the WhatsApp chat | Loads without error (no WhatsApp data in the sandbox) |
| R5e.2 ⭐ | Priya J | Anything WhatsApp-related she uses daily (send template, chat list) | Still works – confirms hiding WhatsApp_Number__c does not break messaging |

## R6. Reveal (Part 6)
| # | As | Step | Expected |
|---|---|---|---|
| R6.1 | Priya J | Real Test P | No 👁 icon |
| R6.2 ⭐ | Swapna | Real Test T → 👁 → Management review → Reveal | Real number 30 s, then hidden |
| R6.3 | Swapna | 👁 → Other + comment → Reveal | Shown; audit has the comment |
| R6.4 | Admin | Audit | Reveal rows for Swapna with reasons |

---

## R7. Nothing else broke ⭐
| # | As | Step | Expected |
|---|---|---|---|
| R7.1 | Integration (vendor) | SlashRTC call log push (`slashCallLogAPI`) after R3.1 | Call record created on the lead as before |
| R7.2 | Integration | MCube callback after R3.2 | Call_Detail__c created as before |
| R7.3 | Admin | Reports / dashboards used by management | Run as before (admins keep full access) |
| R7.4 | Sales / CRM / other unchanged profiles | Daily work | No change |
| R7.5 | Priya J | Her normal day: status updates, follow-ups, site visit booking, qualify / push to sales | All work; only numbers are masked |
| R7.6 📝 | Priya J | Anything that shows an error mentioning a phone field | Record screen + error → a component that needs the field (add to go-live list) |

## R8. Permission-set leak check ⭐
| # | As | Step | Expected |
|---|---|---|---|
| R8.1 | Admin | Setup → Permission Sets → **Sales_All_Access** → Manage Assignments → pick a **Presales outbound** user | – |
| R8.2 | That user | Open any lead | **Full numbers visible** – proves permission sets must also be cleaned at go-live (Part 11 step) |
| R8.3 | Same for **Messaging_Permission_Set** | – | Same result expected |

---

## R9. After the test – restore or keep
| Option | What |
|---|---|
| Restore | Put both profiles back (Read on the 25 fields, remove the new access), remove the page activation rows (R0.6), remove Phone_Reveal from Swapna, delete the Real Test leads |
| Keep | Leave as the go-live rehearsal state for UAT |

If I make the set-up, I restore it from the backup I take in R0 (one deploy, sandbox only).

---

## Result sheet
| Section | Pass / Fail | Notes |
|---|---|---|
| R0 Set-up + R0.8 switch confirmed | | |
| R1 Foundations | | |
| R2 Panel + hidden fields (R2.6 search found?) | | |
| R3 Click-to-call (R3.4 360CTI result) | | |
| R4 Lead creation | | |
| R5a MakeCall / G-Talk (R5a.4 CallPanel = D1) | | |
| R5b History / logs | | |
| R5c Update Contact / Merge | | |
| R5d Push buttons | | |
| R5e WhatsApp | | |
| R6 Reveal | | |
| R7 Nothing else broke | | |
| R8 Permission-set leak confirmed | | |
| R9 Restored / kept | | |

**Expected gaps until built:** CallPanel full number (D1), numbers typed in notes / Chatter (Part 7), 360CTI click (vendor), phone-granting permission sets (Part 11).
