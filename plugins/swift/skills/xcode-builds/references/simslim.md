# simslim

`simslim` disables up to 170 background daemons inside an iOS simulator to cut its memory, so more
simulators fit on one Mac. Each disabled category takes a system feature with it, and the app sees
no error when that happens: nothing arrives, nothing updates, and the code path looks correct.

Installed with `brew install mobai-app/tap/simslim`. Behaviour below was checked against 0.10.0 on
an iOS 27.0 runtime. `simslim --help` is the authority when the two disagree.

## Reading a simulator's state

Slim state lives in each simulator's launchd overrides. No project file records it, and it does not
follow the project to another Mac. Read it from the device every time; never from memory or notes.

| Command | Reports | Exit |
|-|-|-|
| `simslim list` | Every simulator; a booted one shows `156/170 slim` beside its state | 0 |
| `simslim list --json` | The same list; `managedDisabled` is present only on booted devices | 0 |
| `simslim status <udid> --dropped` | The disabled daemons, grouped by category, with what each category breaks | 0 |
| `simslim doctor <udid> --requires push,widgets` | `ok` or `BROKEN` for each feature, naming the disabled daemons | 1 if any feature is broken |
| `simslim doctor --list` | Every feature ID `--requires` accepts, with its daemons | 0 |
| `simslim verify <udid> --profile <file>` | Whether the overrides still match a profile exactly | 1 on drift |

**A shut-down simulator reports nothing.** `list` shows no slim count, and `status` fails with
`simulator must be booted to read its state`. It does not mean the device is stock. The simulator
has to be booted before its state can be read.

`doctor` is the useful one when debugging, because it answers the question actually being asked:
does this simulator still run the daemon this feature needs?

## Categories and what they break

From `simslim profiles`. `--except` takes these IDs.

| ID | Disabling it breaks |
|-|-|
| `widgets` | Home and Lock Screen widgets, wallpaper posters, Live Activities |
| `siri` | Siri, speech features, Apple Intelligence services |
| `search` | Spotlight and Settings search |
| `icloud` | iCloud sync, Apple Account, iCloud Keychain, backup |
| `store` | Remote push notifications, StoreKit and App Store testing |
| `pim` | Contacts, Calendar, Reminders, Mail-backed pickers and sync |
| `web` | Universal links, Safari sync, background web services |
| `family` | Family Sharing, Screen Time |
| `health` | HealthKit, HomeKit, Fitness |
| `photos` | The photo picker, Photos-library workflows, media analysis |
| `apps` | News, Weather, Maps background data, game controllers, Game Center |
| `messaging` | iMessage, FaceTime, identity services |
| `connectivity` | AirDrop, Continuity, CarPlay, Watch, Find My |
| `telemetry` | DeviceCheck, analytics, diagnostics |
| `other` | Wallet, merchant and miscellaneous background services |

Push is in `store`, not in a category of its own.

## Commands that change a simulator

Run these only when the user asks. Each changes a device the user may be working on.

| Command | Effect |
|-|-|
| `simslim on <udid> [--profile f \| --except ids]` | Persists the disables and reboots the device. A running app, test run or debug session on it ends |
| `simslim on <udid> --no-reboot` | Stops the daemons for the current boot only. The only mode on iOS 17.x and 18.3, where the state is lost at the next reboot |
| `simslim off <udid>` | Restores stock, and reboots |
| `simslim watch` | Slims every simulator as it boots, until stopped |
| `simslim erase`, `delete`, `disk-clean --confirm` | Destroy data. `disk-clean` is permanent |

`--preserve-boot-state` on `on` and `off` returns a simulator that was shut down to shutdown.

**Parallel-testing clones start stock.** `xcodebuild` clones the destination device for parallel
testing and deletes the clones after the run, so slimming the destination does not slim them. That
is what `simslim watch --set testing` is for.

**Erasing or recreating a device resets it to stock.** `simslim verify` detects this.

## Committing a profile

The categories an app needs are a fact about the project, so they go in a profile committed with it
rather than in a flag someone has to remember:

```json
{ "name": "dev", "except": ["store", "widgets"], "keep": [] }
```

Derive `except` from the code. Guessing produces a profile that quietly breaks the feature someone
works on next.

| Found in the project | Keep |
|-|-|
| `aps-environment` entitlement, or `import StoreKit` | `store` |
| A WidgetKit extension, or `import ActivityKit` | `widgets` |
| `com.apple.developer.icloud-*` or `ubiquity-kvstore-identifier` entitlements | `icloud` |
| `com.apple.developer.associated-domains` entitlement | `web` |
| HealthKit or HomeKit entitlements | `health` |
| `com.apple.developer.siri` entitlement, or `import Speech` | `siri` |
| `com.apple.developer.family-controls` entitlement | `family` |
| `import Contacts`, `ContactsUI`, `EventKit` or `EventKitUI` | `pim` |
| `import Photos` or `PhotosUI` | `photos` |
| `import GameKit` | `apps` |
| `import DeviceCheck` | `telemetry` |
| `import PassKit` | `store` and `other` — `com.apple.passd` is listed in both |

Then confirm on a booted simulator. `doctor --requires` checks the matching features, and
`verify --profile` checks the whole profile:

```bash
simslim on <udid> --profile <profile>        # reboots the device slim
simslim doctor <udid> --requires push,widgets
simslim verify <udid> --profile <profile>
```
