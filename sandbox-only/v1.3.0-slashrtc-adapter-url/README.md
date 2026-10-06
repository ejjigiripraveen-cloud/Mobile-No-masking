# SANDBOX ONLY – never deploy to production

The SlashRTC call center in the sandbox still points to the **production** adapter page
(`https://gsquaregroup.lightning.force.com/apex/index`), so the sandbox softphone runs production code.
This copy changes only the adapter URL to the org-relative `/apex/index` (same style as the MCube call center),
so the sandbox softphone loads the sandbox page with the v1.3.0 change.

- Original: `backup/v1.3.0-pre-change/callCenters/SlashRTCAdapter.callCenter`
- Deploy (sandbox): `sf project deploy start --metadata-dir sandbox-only/v1.3.0-slashrtc-adapter-url --target-org Sandbox`
- Revert (sandbox): deploy the original from the backup folder.
