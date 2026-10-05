---
name: tailscale-split-tunnel
description: Manage Tailscale split tunneling (bypass/allowlist apps) on Android via root configuration. Use when checking Tailscale split tunnel rules, adding or removing apps from bypass lists, or inspecting current routing states.
---

# Tailscale Split Tunnel Manager

Manage and automate Android Tailscale split tunneling configuration directly through shared_prefs.

## Core Facts

- **Config Path**: `/data_mirror/data_ce/null/0/com.tailscale.ipn/shared_prefs/unencrypted.xml`
- **Key Setting**:
  - `allowSelectedApps = false`: Bypass/Exclude mode (disallowedApps bypass Tailscale and direct connect).
  - `allowSelectedApps = true`: Allowlist mode (only selected apps use Tailscale).
  - `<set name="disallowedApps">`: String set of package names.
- **Process Restart**: Changes to `unencrypted.xml` require stopping Tailscale (`am force-stop com.tailscale.ipn`) and launching it again (`monkey -p com.tailscale.ipn -c android.intent.category.LAUNCHER 1`).

## Helper Script

The bundled script provides atomic updates and handles service restarts safely:

```sh
SCRIPT="/data/data/io.github.mangi.eta/files/skills/tailscale-split-tunnel/scripts/manage_split.sh"

# 1. View current status and all configured packages
sh "$SCRIPT" list

# 2. Add packages to bypass (auto restarts Tailscale)
sh "$SCRIPT" add com.example.app1 com.example.app2

# 3. Remove packages from bypass (auto restarts Tailscale)
sh "$SCRIPT" remove com.example.app1

# 4. Save/update local snapshot
sh "$SCRIPT" snapshot

# 5. Restart Tailscale service
sh "$SCRIPT" restart
```

## References

- `references/disallowed_apps.txt`: Snapshot of all currently excluded package names.
- `references/snapshot.json`: Snapshot metadata including timestamp and mode.
- `references/unencrypted_snapshot.xml`: Exact copy of the shared_prefs configuration.
