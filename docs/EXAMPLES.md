# Examples

WhoopScope includes a deterministic synthetic archive so contributors can
exercise the product without a WHOOP account or personal health records.

## Run the sample app

```bash
mise trust
mise install
mise exec -- tuist install
mise exec -- tuist generate
open WhoopScope.xcworkspace
```

Select the `WhoopScope Demo` scheme and run. The demo:

- Uses an in-memory database.
- Never reads or writes WHOOP tokens or model API keys.
- Never contacts the WHOOP API or authentication broker.
- Never starts the Apple Health receiver.
- Never writes the live desktop-widget snapshot.
- Labels the main window and menu-bar popover as sample data.

You can also launch a built app explicitly:

```bash
open /path/to/WhoopScope.app --args --demo-data
```

## Questions to try

The synthetic archive covers roughly six months and includes cycles, recovery,
sleep, workouts, and complementary Apple Health summaries. Useful prompts
include:

- How did my sleep last week compare with the week before?
- What is my recovery trend over the last 30 days?
- Which days combined strong recovery with high strain?
- Compare my average HRV this month with last month.
- Which workout types appear most often in the last 90 days?
- Did my daily steps change during higher-recovery weeks?

Apple Intelligence answers stay on-device when its model is available.
Selecting OpenAI sends the synthetic evidence and question to OpenAI using the
API key supplied in Settings.

## Reproduce project media

All media in `docs/images` and `docs/media` was captured from the
`WhoopScope Demo` scheme. Before replacing it:

1. Confirm the `Sample Data` badge is visible.
2. Inspect every frame for account names, emails, notifications, and desktop
   content.
3. Keep images readable at GitHub's inline width.
4. Export video as H.264 MP4 without audio.
5. Run the repository secret scan before committing.
