# Backup – existing components before Part 5e (WhatsApp chat)

Retrieved **read-only** from the sandbox on 2026-10-07, before any change. All 9 files identical to baseline v1.0.0.
Checksums: `SHA256SUMS`. Restore: `sf project deploy start --metadata-dir backup/v1.5.0-part5e-pre-change --target-org <org>` (trim `package.xml` first).

| Component | Type | 5e plan |
|---|---|---|
| `LeadMsgConversationController` | Apex | `getConversationViaConnectApi`: for masked users, numbers inside `message`, `rawJson` (raw Messaging data incl. the customer's WhatsApp number) and `senderName` are masked before the list goes to the screen |
| `LeadMsgConversationControllerTest` | Apex test | No change (re-run) |
| `leadMsgConversationLWC` | LWC (on 4 Lead pages + Sales utility bar) | **No change** |

Not changed: `WhatsAppMediaQueue`, `WhatsAppLeadChecker`, `WhatsAppLeadVerifier` (server side). Session lookup by `Full_phone_number__c` stays on the server.
