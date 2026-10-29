# Mobile Number Masking – Real-User Sandbox Test (Parts 1–6)

Written for the project owner. Run after the POC tests and before production. Sandbox: https://gsquaregroup--prodreplic.sandbox.my.salesforce.com

Masking rule: **a user who cannot read `Lead.Phone__c` is masked.** Access = profile **plus** all permission sets.
⚠️ 146 of 246 Presales outbound users have a permission set that grants the phone fields (Messaging_Permission_Set, Chatbot, Sales_All_Access) – they stay unmasked until go-live fixes those sets (shown in R8).

## Test users
| User | Profile | Dialer | Use |
|---|---|---|---|
| **Priya J** | Presales outbound | SlashRTC | Real rep (no phone permission sets) |
| **Ananthi R** (backup Janani M) | Presales outbound | MCube | Real rep (no phone permission sets) |
| **Deepika G** | Presales outbound | 360CTI | Real rep, 360CTI |
| **Swapna** | Presales TL | MCube | Real Team Lead (Reveal) |
| **Sharmili** | Presales outbound | MCube | Has Messaging + Chatbot permission sets → leak example |
| Any Sales / CRM Team user | unchanged | – | Must see no change |
| You | System Administrator | – | Admin checks |

---

# R0 – Set-up for the real-user test

### R0A. Components changed in the sandbox for this test
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| Presales outbound | Profile | **Update (existing)** | Remove Read on 25 phone fields; add Read+Edit on Phone_Entry__c / Secondary_Phone_Entry__c, Read on Phone_Masked__c / Call_To_Masked__c; class access MaskedPhonePanelController, MaskedDialServiceCTI. **This is the go-live switch for this profile** |
| Presales TL | Profile | **Update (existing)** | Same changes as Presales outbound |
| Gsquare Housing (Pre_Sales app) – page activation | Lightning App assignment | **Update (existing)** | 2 new rows: Pre Sales / Desktop / Presales outbound and Presales TL → Sales Lead Record Page (Masked POC) |
| Sales_Lead_Record_Page_Masked_POC | Lightning Page | Update (ours) | Only its activation changes – page content unchanged |
| Phone_Reveal | Permission set assignment | New assignment | Assigned to Swapna |
| Ananthi R, Swapna, Deepika G | User (data) | Update | Mobile + Mcube Phone = **tester's** phone (they are copies of real employees) |
| Real Test P / M / C / T / S | Lead (data) | New | Test leads with dummy numbers |
| Code (Apex, LWC, Aura, VF) | – | **No change** | Nothing is deployed for this test |

### R0B. Steps
| # | Step | Detail | Expected |
|---|---|---|---|
| R0.1 | Back up | Setup → Profiles → Presales outbound → screenshot Field-Level Security of Lead, Related Source, Call Detail, Task, Event + Apex Class Access. Same for Presales TL | Screenshots saved (or reply "approve real-user test setup" and I back up by retrieve) |
| R0.2 | Lead fields | Profiles → **Presales outbound** → Object Settings → **Leads** → Edit → untick **Read**: Phone__c, Secondary_Phone__c, Phone, MobilePhone, Full_phone_number__c, Phone_with_country_code__c, Secondary_phone_with_country_code__c, Secondary_Phones__c, Secondary_Mobile_No__c, Office_Phone_No__c, Spouse_Number__c, WhatsApp_Number__c, Register_your_WhatsApp_Number__c, Merge_Lead_Phone_No__c · tick **Read+Edit**: Phone_Entry__c, Secondary_Phone_Entry__c · tick **Read**: Phone_Masked__c → Save | Saved |
| R0.3 | Related Source | Object Settings → **Related Sources** → Edit → untick Read: Phone__c, Secondary_Phone__c, Register_your_WhatsApp_Number__c → Save | Saved |
| R0.4 | Call Detail | **Call Details** → Edit → untick Read: Call_To__c, Customer_Contact__c · tick Read: Call_To_Masked__c → Save | Saved |
| R0.5 | Task / Event | **Tasks** and **Events** → Edit → untick Read: Call_From__c, Call_To__c, Caller_number__c → Save | Saved |
| R0.6 | Classes | Profile → **Apex Class Access** → Edit → add MaskedPhonePanelController, MaskedDialServiceCTI → Save | Saved |
| R0.7 | Presales TL | Repeat R0.2–R0.6 on profile **Presales TL** | Saved |
| R0.8 | Reveal | Setup → Permission Sets → **Phone Reveal** → Manage Assignments → Add → **Swapna** → Assign | Assigned |
| R0.9 | Page | Setup → Lightning App Builder → **Sales Lead Record Page (Masked POC)** → Edit → Activation → App, Record Type, and Profile → Assign → **Gsquare Housing** → **Desktop** → **Pre Sales** → profiles **Presales outbound** + **Presales TL** → Save | 2 rows added |
| R0.10 | Phones ⚠️ | Setup → Users → **Ananthi R**, **Swapna**, **Deepika G** → Edit → Mobile = your agent phone, Mcube Phone = same → Save (write down the old values to restore) | Saved |
| R0.11 | Leads | As admin create (record type Pre Sales, then change owner): **Real Test P** (Priya J, 9000100001 / 9000100002), **Real Test M** (Ananthi R, 9000200001 / 9000200002), **Real Test C** (Deepika G, 9000300001), **Real Test T** (Swapna, 9000400001 / 9000400002), **Real Test S** (Sharmili, 9000500001). Copy the Ids | 5 leads |
| R0.12 ⭐ | Confirm switch | Setup → Users → each user → **View Summary** → Lead → **Phone__c** | Priya J, Ananthi R, Swapna, Deepika G: **no Read** · Sharmili: **Read** (permission sets) |

---

# R1 – Part 1 Foundations

### R1A. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| PhoneMaskUtil, PhoneMaskingConfig | Apex Class | New | Masking engine and settings |
| MaskedDialService, MaskedDialServiceCTI | Apex Class | New | Server-side real-number lookup + audit |
| Phone_Masking_Setting__mdt, Masked_Phone_Field__mdt | Custom Metadata | New | Settings and approved fields |
| Phone_Access_Audit__c | Custom Object | New | Audit log |
| Existing components | – | None | – |

### R1B. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R1.1 | Admin | Gear → Developer Console → Debug → Open Execute Anonymous → paste `scripts/apex/v1.1.0-1-mask-format.apex` → Open Log → Execute → Debug Only | `RESULT: 11 passed, 0 failed` |
| R1.2 | Admin | Same with `v1.1.0-2-settings.apex` | 2 / 2 / X / 91 / 30 / 365, switches true, 2 approved fields |

---

# R2 – Part 2 Masked panel and hidden fields

### R2A. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| maskedPhonePanel | LWC | New | Phone Numbers panel (masked) |
| MaskedPhonePanelController | Apex Class | New | Returns masked numbers only |
| Sales_Lead_Record_Page_Masked_POC | Lightning Page | New | Page with the panel (now active for the real profiles) |
| Presales outbound / Presales TL | Profile | Update (existing, R0) | Phone fields hidden |

### R2B. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R2.1 ⭐ | Priya J | Setup → Users → Priya J → **Login** → App Launcher → Gsquare Housing → Leads → **Real Test P** | Panel top-left: Primary `90XXXXXX01`, Secondary `90XXXXXX02`; no phone field in details, highlights or header |
| R2.2 ⭐ | Priya J | F12 → Network → filter `aura` → F5 → open responses → Ctrl+F `100001` | Not found |
| R2.3 | Priya J | Leads tab → each list view she uses | Phone columns empty / gone; lists work |
| R2.4 | Priya J | Reports → a Lead report and a Call report she uses → Run | Runs; phone columns empty |
| R2.5 | Priya J | Real Test P → related lists Related Sources, Activity, Call Details | No phone / Call To / Caller number values |
| R2.6 📝 | Priya J | Top search → `9000100001` → Enter | Write down found / not found (decides Part 8) |
| R2.7 | Priya J | Lead of another record type (if any) | Normal page, no panel, fields hidden |
| R2.8 | Priya J | Mobile app → Real Test P (optional) | No full numbers |
| R2.9 | Ananthi R, Deepika G, Swapna | Login → their Real Test lead | Same masked panel |
| R2.10 ⭐ | Sales / CRM user | Login → any lead | Exactly as before: full numbers, no panel |

---

# R3 – Part 3 Click-to-call (MCube + SlashRTC)

### R3A. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| mcubeSoftphoneCTIAddOn | Visualforce Page | **Update (existing)** | Masked-click branch in the MCube softphone |
| McubeSoftphoneAddOnController | Apex Class | **Update (existing)** | New method clickToCallMasked |
| slashPhone (slashPhoneHelper.js) | Aura | **Update (existing)** | Masked-click step in the SlashRTC softphone |
| MaskedDialService, MaskedDialServiceCTI | Apex Class | Update (ours) | Resolve real number on the server, audit |
| 360CTI adapter (tdc_360CTI) | Managed package | No change (vendor) | Expected not to dial masked numbers yet |

### R3B. Steps (📞 crossed out → bottom bar Phone → wait ready → F5)
| # | As | Step | Expected |
|---|---|---|---|
| R3.1 ⭐ | Priya J | Phone utility → log in to SlashRTC → Real Test P → click **Primary** | Call connects via SlashRTC |
| R3.2 ⭐ | Ananthi R | Phone utility ready → Real Test M → click **Primary** | Your phone rings, then the customer phone; connected |
| R3.3 | Ananthi R | Click **Secondary** | Same |
| R3.4 | Priya J / Ananthi R | F12 → Network → Preserve log → click again | Only Id, field, masked value sent; no full number |
| R3.5 📝 | Deepika G | Real Test C → click Primary | Expected not to dial (vendor) – write down what happens |
| R3.6 ⭐ | "Customer" phone | As admin put your phone on a Real Test lead → call the SlashRTC / MCube virtual number while Priya J / Ananthi R is ready | Screen pop opens the right lead; call record created |
| R3.7 | Admin | App Launcher → Phone Access Audits → All → newest | Dial / Success rows for Priya J, Ananthi R; masked only |
| R3.8 ⭐ | Sales / CRM user | Click a normal phone field | Calls as before; no audit row |

---

# R4 – Part 4 Lead creation

### R4A. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| Phone_Entry__c, Secondary_Phone_Entry__c | Custom Field (Lead) | New | Entry fields, empty after save |
| LeadPhoneEntryHandler | Apex Class | New | Copies entry → real field, locks primary |
| LeadTrigger | Apex Trigger | **Update (existing)** | One call at the top |
| NewLeadCmp | Aura | **Update (existing)** | Lead New form – entry inputs for masked users |
| NewRefLeadCmp | Aura | **Update (existing)** | New Referral Lead – same |

### R4B. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R4.1 ⭐ | Priya J | Leads → New → Last name `Real Test P2`, Phone 9000100011, Secondary 9000100012, other required fields → Save | Saved, no "Phone required"; panel `90XXXXXX11` / `90XXXXXX12` |
| R4.2 | Priya J | Any lead → New Referral Lead → `Real Test P3`, Phone 9000100021 → Save | Saved |
| R4.3 | Priya J | Real Test P2 → Secondary Phone (entry) → 9000100013 → Save | Panel `90XXXXXX13`; entry empty |
| R4.4 | Priya J | New lead with Phone 9000100011 again | Same duplicate behaviour as today |
| R4.5 | Admin | Script A (main guide) with `LIKE 'Real Test%'` | Real fields filled, entry fields empty |
| R4.6 | Admin | Script B on Real Test P2 | Saved: false + primary-lock message |
| R4.7 | Admin | Owners of the new leads | Round robin as today |
| R4.8 ⭐ | Admin | Script C (integration-style insert, rolled back) | Saved: true, entry empty |
| R4.9 | Sales / CRM user | Leads → New | Old form, unchanged |

---

# R5a – MakeCall and G-Talk

### R5aA. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| MakeCallController | Apex Class | **Update (existing)** | Masked list; real number resolved on the server |
| OfflineCallAppAPI | Apex Class | **Update (existing)** | G-Talk masked; triggerCall resolves |
| PhoneDisplayService | Apex Class | New | Masked-user rule for all screens |
| MakeCall, utilityCallComponent ("Offline Call") | Aura / LWC | No change | Show what Apex returns |
| CallPanel, CallPanel_Outbound | Aura | Not changed (D1) | Will show the full number |
| gTalkAPIDurationCMP ("Call Log Update Issue") | LWC | No change | External G-Talk page – check |

### R5aB. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R5a.1 ⭐ | Ananthi R | Real Test M → **Make call** → Select Number | `+91 90XXXXXX01` style |
| R5a.2 | Ananthi R | Pick → Call | Your phone, then the customer; connected |
| R5a.3 | Priya J | Bottom bar → **Offline Call** → Call | Masked; no error |
| R5a.4 | Admin | Phone Access Audits | MCube (MakeCall) and G-Talk rows |
| R5a.5 📝 | Priya J | Bottom bar → CallPanel / CallPanel_Outbound | Full number visible = D1 (known) |
| R5a.6 📝 | Priya J | Bottom bar → Call Log Update Issue | Write down if a number is shown |

# R5b – History and logs

### R5bA. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| LeadHistoryandActivityController | Apex Class | **Update (existing)** | History & Activity masked |
| mCubeController | Apex Class | **Update (existing)** | Call list masked; log__c masked for everyone |
| Call_To_Masked__c | Formula field | New | Masked call number |

### R5bB. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R5b.1 | Admin | Real Test P → Edit Phone → 9000100003 → Save | History created |
| R5b.2 ⭐ | Priya J | Real Test P → History & Activity → Field Updates | `90XXXXXX01 → 90XXXXXX03` |
| R5b.3 | Priya J | History & Activity → Calls | Call numbers masked |
| R5b.4 | Admin | After R3.2: Script E | Newest MCube log has no full number |

# R5c – Update Contact Details and Merge

### R5cA. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| updateContactDetails | Apex Class | **Update (existing)** | Masked; masked values never saved; primary locked |
| LeadMergeController | Apex Class | **Update (existing)** | Merge lists masked |

### R5cB. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R5c.1 | Priya J | Real Test P → Update Contact Details | Masked |
| R5c.2 ⭐ | Priya J | Change only Email → Save; then Script F | Success; X saved: false |
| R5c.3 | Priya J | Secondary → 9000100004 → Save | Saved |
| R5c.4 | Priya J | Phone → 9000100005 → Save | Rejected (locked) |
| R5c.5 | Priya J | Merge Lead → list / search "Real Test" → close | Masked |

# R5d – Push buttons

### R5dA. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| LeadBulkPushController, LeadYotelBulkPushController | Apex Class | **Update (existing)** | Masked selection list (only users with access) |

### R5dB. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R5d.1 | Priya J | Leads list → tick a lead → Add Leads to Call List | "Insufficient privileges" – same as today |
| R5d.2 | MIS Extended user | Same → Cancel | Full numbers (not changed) |

# R5e – WhatsApp

### R5eA. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| LeadMsgConversationController | Apex Class | **Update (existing)** | Conversation masked for masked users |

### R5eB. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R5e.1 | Priya J | A lead with the WhatsApp chat | Loads without error |
| R5e.2 ⭐ | Priya J | WhatsApp actions she uses daily | Still work; write down any error |

---

# R6 – Part 6 Reveal

### R6A. Components tested
| Component name | Component type | New/Update | What it is / comments |
|---|---|---|---|
| PhoneRevealService | Apex Class | New | Reveal with reason, 30 s, audit |
| Reveal_Phone_Number / Phone_Reveal | Custom Permission / Permission Set | New | Who can reveal (Swapna) |
| maskedPhonePanel | LWC | Update (ours) | 👁 button and reason window |

### R6B. Steps
| # | As | Step | Expected |
|---|---|---|---|
| R6.1 | Priya J | Real Test P | No 👁 |
| R6.2 ⭐ | Swapna | Real Test T → 👁 → "Dialer down, manual call needed" → Reveal | Real number 30 s, then hidden |
| R6.3 | Swapna | 👁 → Other, empty comment → then comment `real user test` → Reveal | Disabled until comment; then shown |
| R6.4 | Admin | Phone Access Audits | 2 Reveal rows for Swapna, masked only |

---

# R7 – Nothing else broke
| # | As | Step | Expected |
|---|---|---|---|
| R7.1 | Admin | After R3.1: Real Test P → SlashRTC call record | Created as before |
| R7.2 | Admin | After R3.2: Real Test M → Call Details | MCube record created |
| R7.3 | Priya J | Normal day: status, follow-up, site visit, qualify / push to sales | All work; note any error naming a phone field |
| R7.4 | Swapna | Team views / dashboards | Work; phone columns empty |
| R7.5 | Admin / Sales / CRM | Reports, daily work | Unchanged |

# R8 – Permission-set leak
| # | As | Step | Expected |
|---|---|---|---|
| R8.1 ⭐ | Sharmili | Login → Real Test S | Full number, no masking (permission sets grant the fields) |
| R8.2 | Admin | Record result | Go-live must also remove the phone fields from those permission sets |

# R9 – After the test
| Option | What |
|---|---|
| Restore | Reverse R0.2–R0.10 (re-tick Read, remove new access, remove the 2 activation rows, remove Phone Reveal from Swapna, restore user phones), delete the Real Test leads |
| Keep | Keep as the go-live rehearsal for UAT |

## Result sheet
| Section | Pass / Fail | Notes |
|---|---|---|
| R0 set-up (R0.12 confirmed) | | |
| R1 | | |
| R2 (R2.6 found?) | | |
| R3 (R3.5 360CTI, R3.6 screen pop) | | |
| R4 | | |
| R5a (R5a.5 D1, R5a.6 G-Talk page) | | |
| R5b | | |
| R5c | | |
| R5d | | |
| R5e | | |
| R6 | | |
| R7 | | |
| R8 | | |
| R9 | | |

**Known gaps (not failures):** CallPanel (D1) · typed numbers in notes (Part 7) · 360CTI (vendor) · permission-set users (Part 11) · G-Talk / Yotel external screens (vendors).
