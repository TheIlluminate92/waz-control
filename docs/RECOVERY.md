# Recovery

WAZ Control changes the Unraid WebUI. Always keep terminal/SSH access available while testing.

## If the WebUI becomes unusable

1. Connect to the server through SSH or the local console.
2. Remove/disable the WAZ Control test plugin using the uninstall method documented with that build.
3. Restart the Unraid WebUI service if required by that build.
4. If files were manually replaced, restore the backed-up originals.
5. Reboot only if normal WebUI recovery does not restore service.

## Development rule

Every installable build must document exactly:

- which paths it installs or changes
- what it stores persistently on the flash drive
- how to uninstall it from shell
- whether a WebUI restart is required
- whether any original files are modified

The preferred design is to inject/add files through the Unraid plugin mechanism and avoid permanent edits to core Unraid files.

## Do not panic-delete

Avoid broad recursive delete commands. Remove only the exact WAZ Control paths documented for the build.

Specific recovery commands will be added once the first rolling `.plg` is committed.
