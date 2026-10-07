# Backup – existing components before Part 5c (Lead Merge + Update Contact Details)

Retrieved **read-only** from the sandbox on 2026-10-07, before any change. All 22 files identical to baseline v1.0.0.
Checksums: `SHA256SUMS`. Restore: `sf project deploy start --metadata-dir backup/v1.5.0-part5c-pre-change --target-org <org>` (trim `package.xml` first).

| Component | Type | 5c plan |
|---|---|---|
| `LeadMergeController` | Apex | `getLeads` / `getSearchLeads`: mask phone numbers in the results for masked users. `mergeLead`: no change (works with record Ids) |
| `LeadMergeControllerTest` | Apex test | No change (re-run) |
| `LeadMergeCmp` | Aura | **No change** |
| `updateContactDetails` | Apex | `getcontactdetails`: masked for masked users. `savecontactdetails`: a masked value from the screen is never saved (kept as the stored number); primary locked for masked users |
| `updateContactDetailsTest` | Apex test | No change (re-run) |
| `UpdateContactDetails` | Aura | **No change** |

Existing issues noticed (not changed): `LeadMergeController.getLeads` returns every Lead except the current one with no limit; the class has no sharing keyword, so the merge list shows all Leads.
