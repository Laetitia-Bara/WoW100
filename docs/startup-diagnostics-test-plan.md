# Startup Diagnostics Test Plan

Use this after installing a Release build on a real iPhone or iPad.

## Expected Console Markers

Open the Xcode device console and filter for either `WoW100Startup` or `[startup]`.

Expected sequence:

```text
app started
Flutter initialized
ads init started
ads init finished
runApp called
first screen rendered
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

