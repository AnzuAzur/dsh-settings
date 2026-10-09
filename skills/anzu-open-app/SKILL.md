---
name: anzu-open-app
description: Launch installed Windows desktop apps through Anzu_PC, including Chrome, Spotify, HoYoPlay, and Genshin Impact. Use for opening apps or a website in Chrome on the connected Windows PC.
---

# Open Windows apps

Anzu_PC controls its connected Windows PC. Do not silently substitute apps on the Mac hosting Codex.

Open a workspace once and reuse its workspaceId. Use launch_application for desktop launches; do not turn a launch request into a bash command.

The expanded launcher accepts these executable names:
- chrome.exe: no arguments, one HTTP(S) URL, or one existing file within allowed workspace roots.
- spotify.exe: no arguments; opening Spotify does not start a playlist.
- hoyoplay.exe: no arguments; resolves to HoYoPlay's launcher.exe.
- genshinimpact.exe: no arguments; opens the installed game directly.
- notepad.exe, explorer.exe, code.exe, taskslinger.exe: no arguments or one existing path within allowed roots.

Example: to open YouTube in Chrome, pass executable chrome.exe and arguments ["https://www.youtube.com"] with the workspaceId.

Use the live tool schema. If it still lists only the original apps, the server needs a restart and the connector's tool metadata needs refreshing. A skill cannot override a running tool's restrictions.

If Windows denies a game launch with EACCES or EPERM, report it and let the user handle any Windows permission prompt locally. Do not elevate the connector.

A successful result reports process creation and a PID. Do not claim a game has reached its menu, a website loaded, or music is playing without a separate observation. If an app is missing, report the installation-location error; do not install it or substitute a different app without the user's request.

To add another app during plugin development, extend APPLICATION_ALLOWLIST and explicit installation candidates in src/application-launch.ts, define its argument policy, update tests and server descriptions, build, and restart the connector. Keep shell execution disabled and preserve existing app support.
