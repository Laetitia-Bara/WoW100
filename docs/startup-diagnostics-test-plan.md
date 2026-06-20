# Startup Diagnostics Test Plan

Use this after installing a Release build on a real iPhone or iPad.

## Prepare The Mac

Do not validate an iOS relaunch from the home-screen icon with the default
`flutter run` command. That command installs a Debug build, which uses the
Flutter debugging connection and can request Local Network access on first
launch. A Debug build closing when launched independently from its icon is not
representative of the App Store Release build.

If Flutter reports that `iproxy` was built for the wrong architecture on an
Apple Silicon Mac, install Rosetta once:

```text
sudo softwareupdate --install-rosetta --agree-to-license
```

Then test a Release build, not the default Debug build:

```text
flutter devices
flutter run --release -d <device-id>
```

When the Release app is running, press `d` in the Flutter terminal to detach
without terminating the app. Do not press `q`, which terminates it. Force-close
the app on the device, then relaunch it from the icon.

For a launch test that does not depend on the Flutter debug connection, also
install the Release build and launch it from the app icon:

```text
flutter install --release -d <device-id>
```

## Expected Console Markers

Open the Xcode device console and filter for `startup-native`, `WoW100Startup`,
or `[startup]`.

Expected sequence:

```text
[startup-native] app didFinishLaunching started
[startup-native] app didFinishLaunching finished
[startup-native] scene connection started
[startup-native] plugin registration started
[startup-native] plugin registration finished
[startup-native] Flutter scene connected
[startup-native] scene channels configured
app started
Flutter initialized
runApp called
first screen rendered
ads init started
ads init finished
```

If AdMob blocks startup for too long, the app should now continue after the timeout and show:

```text
ads init timed out
runApp called
first screen rendered
```

If AdMob fails immediately, the app should now continue and show:

```text
ads init failed
runApp called
first screen rendered
```

## Launch Checks

- Delete the app from the device.
- Install the Release build.
- Launch with internet enabled.
- Force quit, then relaunch 5 times.
- Launch once in Airplane Mode.
- Launch once after switching back to internet.
- Repeat once with ads disabled to isolate the Google Mobile Ads SDK:

```text
flutter run --release --dart-define=DISABLE_ADS=true -d <device-id>
```

- Repeat on iPad if available.

## What To Capture

- A short screen recording of the first launch.
- A screenshot if the app stops on the splash screen, a blank screen, or another visible screen.
- The Xcode console lines around the last `WoW100Startup` or `[startup]` marker.

## Interpretation

- Last marker is `ads init started`: AdMob startup is hanging before the timeout or native code is blocking.
- Last marker is `ads init timed out`: AdMob did not finish within 8 seconds, but the app should still render.
- Last marker is `runApp called`: Flutter started building the app, but the first frame did not render.
- Last marker is `first screen rendered`: startup completed; any later freeze is inside the app UI flow.
- No `startup-native` marker: inspect the iOS crash report because the process failed before the app delegate ran.
- Last native marker is `plugin registration started`: a native Flutter plugin is crashing during registration.
- Release works only with `DISABLE_ADS=true`: Google Mobile Ads initialization is the likely trigger.
