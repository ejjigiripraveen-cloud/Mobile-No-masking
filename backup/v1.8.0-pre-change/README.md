# Backup before adding the "Find by Number" utility item (v1.8.0)

Taken 2026-10-30 from the sandbox (gsquaregroup--prodreplic) by a read-only retrieve. Nothing in the sandbox was changed.

| File | What it holds |
|---|---|
| `applications/Pre_Sales.app-meta.xml` | Gsquare Housing app (Pre_Sales): tabs, page activations, utility bar reference |
| `flexipages/Pre_Sales_UtilityBar.flexipage-meta.xml` | The app's utility bar – **utility items live here** (9 today: Yotel softphone, leadEngagementAlert, OmniOfflineNotifier, Open CTI softPhone, Omni widget, gTalkAPIDurationCMP, utilityCallComponent "Offline Call", CallPanel_Outbound, CallPanel) |

## Restore (only when the owner asks)
- Easiest: App Manager → Gsquare Housing → Edit → Utility Items → remove **Find by Number** → Save.
- Or deploy the utility bar back: copy `flexipages/` into a temporary SFDX project and run
  `sf project deploy start -m "FlexiPage:Pre_Sales_UtilityBar" --target-org Sandbox --test-level NoTestRun` (dry-run first).
- The app file is reference only (the utility bar change does not change it).
