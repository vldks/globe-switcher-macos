# Security Policy

## Supported Versions

| Version | Supported |
| :--- | :---: |
| Latest (`main`) | ✅ |

## Security Model & Auditing

- **Zero-TCC Architecture:** `globe-switcher` does not request or require macOS Accessibility (`kTCCServiceAccessibility`) or Input Monitoring (`kTCCServiceListenEvent`) permissions.
- **No Network Access:** The background `LaunchAgent` (`GlobeSwitcher.swift`) makes zero network connections and links only against system frameworks (`AppKit`, `Carbon`, `CoreFoundation`, `CoreGraphics`, `SkyLight`).
- **Reproducible Source:** The entire daemon is contained in a single human-readable file ([`GlobeSwitcher.swift`](GlobeSwitcher.swift)) and can be compiled locally with `swiftc`.

## Reporting a Vulnerability

If you discover a security issue or unexpected behavior, please report it by opening a [GitHub Issue](https://github.com/vldks/globe-switcher-macos/issues) or contacting the author via [vladkas.com](https://vladkas.com/blog/globe-switcher-shortcut/).
