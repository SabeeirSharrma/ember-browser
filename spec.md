# EMBER_SPEC.md
# Ember Browser — Project Specification
# The Cinder Project

**Status:** Planning
**Version:** 0.1-spec
**Maintainer:** The Cinder Project

---

## 1. Philosophy

Ember exists because pre-built binaries are not transparent. Every major browser today ships as an opaque binary from a corporation with conflicting incentives — telemetry, ad revenue, proprietary sync services, and update mechanisms that phone home constantly.

Ember is built on three principles:

- **Auditability** — every component is compiled from source. Users (or CPAC) build Ember themselves. Nothing ships as a pre-built binary that cannot be inspected.
- **Privacy by default** — no telemetry, no Google services, no tracking of any kind. DuckDuckGo is the default and only built-in search engine. DNS queries go through DoH by default.
- **Total customization** — Ember is a browser distro, not a browser product. The entire UI is a configurable shell. Layout, typography, keybinds, blocking behavior, panels — everything is exposed and changeable via a human-readable config file.

Ember is Linux-first. Windows and macOS are future targets.

---

## 2. Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                      Ember Browser                       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │                 Ember Shell (WebUI)                │  │
│  │  Custom browser UI layer — fully configurable      │  │
│  │  via ember.toml. Tabs, toolbar, sidebar, panels,   │  │
│  │  new tab, PiP, reader mode, screenshot tool,       │  │
│  │  notes panel — all part of the shell.              │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─────────────────────┐  ┌─────────────────────────┐    │
│  │    CinderBlock      │  │       Coalbox           │    │
│  │  Content blocking   │  │   Password manager      │    │
│  │  (uBlock fork)      │  │   (.emberkeys vault)    │    │
│  └─────────────────────┘  └─────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  ┌──────────────────┐  ┌───────────────────────┐   │  │
│  │  │  Ember Config    │  │    DoH Resolver       │   │  │
│  │  │  (ember.toml,    │  │  (Cloudflare/Quad9/   │   │  │
│  │  │  hot-reload,     │  │   custom, browser-    │   │  │
│  │  │  profiles)       │  │   traffic only)       │   │  │
│  │  └──────────────────┘  └───────────────────────┘   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Chromium Engine (degoogled)           │  │
│  │  Rendering (Blink), JS (V8), networking,           │  │
│  │  security sandbox, DevTools, PDF viewer            │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Chromium Base

Ember is built on Chromium source, compiled from scratch via GN + Ninja. The engine is not modified for rendering or JS behavior — the patch series targets only the removal of Google services and the addition of Ember-specific hooks.

### 3.1 Stripped from Chromium

- All Google API keys and service endpoints
- Google Sync / Sign-in
- Chrome Web Store integration
- Google Safe Browsing (replaced by CinderBlock's malware/phishing lists)
- Crash reporting (breakpad/crashpad)
- UMA metrics and field trials
- Google Update / Omaha
- Google Now / Feed
- WebRTC IP leak behavior (hardened)
- Widevine DRM
- Chrome's built-in password manager (replaced by Coalbox)

### 3.2 Kept

- V8 JavaScript engine
- Blink rendering engine
- Chromium's process isolation and sandboxing model
- DevTools
- PDF viewer
- WebGL, WebGPU, WebAssembly
- Native Picture-in-Picture API (extended by Ember Shell — see Section 5.4)

### 3.3 Build System

- **Build system:** GN + Ninja (Chromium's native toolchain)
- **Patch management:** Git patch series versioned against upstream Chromium tags
- **Languages:** C++ (engine patches), TypeScript + HTML + CSS (Ember Shell)
- **Distribution:** Source tarball, verified build via CPAC
- **Primary platform:** Linux (x86_64, AArch64)
- **Future platforms:** Windows, macOS

---

## 4. Ember Shell

Ember Shell is the entire browser UI, built as a custom Chromium WebUI layer in HTML, CSS, and TypeScript. It replaces Chrome's default UI entirely.

Every element of the shell is configurable. The shell reads `ember.toml` on launch and hot-reloads on config change. There is no hardcoded layout.

### 4.1 Config File

All user preferences are stored in a single human-readable TOML file:

```
~/.config/ember/ember.toml
```

Fully version-controllable and shareable. Hot-reloads without a browser restart where possible.

### 4.2 Layout Configuration

```toml
[layout]
tab_bar = "top"                    # top | bottom | sidebar-left | sidebar-right | hidden
toolbar = "top"                    # top | bottom | hidden
sidebar = false                    # true | false
sidebar_default = "bookmarks"      # bookmarks | history | downloads | notes
new_tab = "blank"                  # blank | clock | bookmarks | custom
new_tab_custom_path = ""           # path to custom HTML file
```

### 4.3 Appearance Configuration

```toml
[appearance]
theme = "dark"                     # dark | light | system | custom
accent_color = "#E05C2A"
custom_css_path = ""               # custom CSS injected into the shell

[typography]
ui_font = "system"                 # system | any installed font name
ui_font_size = 14
page_font_override = false
page_font = ""
page_font_size = 16
```

### 4.4 Toolbar Configuration

Every toolbar element is individually toggleable and reorderable:

```toml
[toolbar]
back = true
forward = true
reload = true
home = false
home_url = "about:newtab"
bookmarks_bar = false
cinderblock_button = true          # CinderBlock dedicated toolbar button
coalbox_button = true              # Coalbox lock/unlock indicator
downloads_button = true
screenshot_button = true
pip_button = true
reader_mode_button = true
notes_button = true
```

### 4.5 Keybinds

Every browser action is remappable. Defined in `ember.toml` under `[keybinds]`:

```toml
[keybinds]
new_tab = "Ctrl+T"
close_tab = "Ctrl+W"
reopen_tab = "Ctrl+Shift+T"
next_tab = "Ctrl+Tab"
prev_tab = "Ctrl+Shift+Tab"
focus_address = "Ctrl+L"
reload = "F5"
hard_reload = "Ctrl+Shift+R"
find = "Ctrl+F"
devtools = "F12"
new_window = "Ctrl+N"
private_window = "Ctrl+Shift+N"
bookmark = "Ctrl+D"
history = "Ctrl+H"
downloads = "Ctrl+J"
zoom_in = "Ctrl+="
zoom_out = "Ctrl+-"
zoom_reset = "Ctrl+0"
fullscreen = "F11"
pip_toggle = "Alt+P"
reader_mode = "Alt+R"
screenshot = "Ctrl+Shift+S"
notes_panel = "Ctrl+Shift+N"
cinderblock = ""                   # toolbar button only, no default shortcut
coalbox_autofill = "Ctrl+Shift+F"
```

A **Vim preset** is available:

```toml
[keybinds]
preset = "vim"                     # vim | default | custom
```

### 4.6 Privacy Configuration

```toml
[privacy]
doh_enabled = true
doh_provider = "cloudflare"        # cloudflare | quad9 | custom
doh_custom_url = ""
fingerprint_resistance = "standard" # off | standard | strict
webrtc_policy = "disable_non_proxied_udp"
https_only = true
global_privacy_control = true
referrer_policy = "strict-origin"
```

### 4.7 Ember Profiles

Profiles are shareable `ember.toml` presets distributed as `.emberprofile` files. Applied via CLI or from within the browser. Community profiles are installable via CPAC.

**Built-in profiles:**

| Profile | Description |
|---|---|
| `ember-default` | Balanced defaults, dark theme, DDG, CinderBlock on |
| `ember-minimal` | No sidebar, blank newtab, toolbar stripped to essentials |
| `ember-power` | Vertical tabs, bookmark sidebar, full toolbar |
| `ember-privacy` | Strict fingerprint resistance, HTTPS-only, JS off by default |
| `ember-vim` | Vim keybind preset + minimal layout |

---

## 5. Ember Shell Features

### 5.1 Tab Management

**Tab bar modes** (set in `ember.toml`):
- Top bar (default)
- Bottom bar
- Sidebar left / right (vertical tabs)
- Hidden (keyboard-only tab switching)

**Tab Groups:**
- Named groups with color + letter coding (e.g. 🔴 W for Work, 🔵 P for Personal)
- Nested groups supported
- Collapsible in sidebar mode — group name becomes a collapsible section header
- In top bar mode — groups shown as colored underlines with collapse toggle
- Groups persist across sessions
- Keyboard shortcut to create group from selected tabs

### 5.2 Sidebar Panels

The sidebar is modular. Any panel can be pinned to the sidebar or opened as a floating overlay:

| Panel | Description |
|---|---|
| **Bookmarks** | Full bookmark tree, folders, search |
| **History** | Browsing history, searchable, clearable per-domain |
| **Downloads** | Active and past downloads, open/reveal in files |
| **Notes** | Persistent scratchpad (see Section 5.6) |
| **Coalbox** | Full password vault panel (see Section 6.2) |

### 5.3 Reader Mode

Activated via toolbar button or `Alt+R`. Strips the page to content only — no ads, no sidebars, no navigation chrome.

Reader mode respects the active Ember theme and typography config:
- Uses `ember.toml` font settings for body text
- Dark/light/system follows the active theme
- Additional reader-specific controls: font size slider, line width, text spacing
- Reader mode state persists per-URL (remembered on revisit)

### 5.4 Picture-in-Picture (PiP)

Ember's PiP is a first-class feature, built to be the best PiP in any browser.

**Features:**
- Works on any `<video>` element on any page
- Triggered via toolbar button, right-click on video, or `Alt+P`
- Always-on-top across all workspaces and virtual desktops
- Survives tab switches, workspace changes, and browser minimize
- Freely resizable with no minimum size restriction
- **Persists position and size across sessions** — PiP window opens where you left it
- Custom PiP overlay controls: play/pause, seek bar, volume, mute, close, expand back to tab
- Keyboard shortcuts functional while PiP is focused
- Works on YouTube, Twitch, and any site with a standard video element

### 5.5 Screenshot Tool

Activated via toolbar button or `Ctrl+Shift+S`. Three capture modes:

- **Viewport** — captures the visible area of the current tab
- **Full page** — captures the entire scrollable page
- **Region** — snip tool, click and drag to select area

Output options: save to file (PNG/JPEG), copy to clipboard. Filename includes site name and timestamp by default.

### 5.6 Notes Panel

A persistent scratchpad built into the browser.

**Features:**
- Plain text and Markdown supported
- Notes are local, stored in `~/.config/ember/notes/`
- Multiple named notes (like tabs within the panel)
- Search across all notes
- **Sticky note mode** — pin a note to the new tab page. Sticky notes appear as a draggable card on the homepage. Position is saved.
- Notes persist across sessions and are not cleared with history

### 5.7 New Tab Page

Configurable in `ember.toml`:
- **Blank** — truly empty, just the address bar
- **Clock** — minimal clock, date, optional greeting
- **Bookmarks** — bookmark grid
- **Custom** — user-supplied HTML file
- **Sticky notes** — if sticky notes are active, they appear on any new tab mode as a draggable overlay

---

## 6. Integrated Components

CinderBlock and Coalbox are **independent projects** — separate repositories, separate build pipelines, separate versioning, separate maintainers (even though that's currently just you). Each builds and runs standalone with zero dependency on Ember.

Ember does not vendor or compile their source as part of its own build. Integration happens at the **binary/IPC level**: Ember Shell talks to a running CinderBlock and Coalbox process the same way any third-party consumer could. This is what keeps both projects usable outside of Ember and auditable independently — a security review of Coalbox doesn't require touching Ember's codebase, and vice versa.

What "integrated" means in practice:
- Ember Shell ships UI hooks (toolbar buttons, panels, prompts) that call into CinderBlock/Coalbox via their own APIs (IPC for CinderBlock, local socket/IPC for Coalbox Core)
- CPAC packages CinderBlock and Coalbox as **separate packages**, with Ember declaring them as dependencies — same model as any Linux distro packaging a browser alongside its own libraries
- Version compatibility between Ember and each component is tracked explicitly (see compatibility table below), not assumed by shipping in lockstep
- A bug or vulnerability in Coalbox does not require an Ember rebuild — only a Coalbox update via CPAC

### 6.0 Version Compatibility

| Ember version | Min CinderBlock | Min Coalbox |
|---|---|---|
| v0.3+ | v0.3 | — |
| v0.7+ | v0.7 | — |
| v0.9+ | v0.7 | v0.7 |
| v1.0 | v1.0 | v1.0 |

This table is maintained as both projects evolve. Ember Shell checks installed component versions at launch and warns if a minimum is not met.

### 6.1 CinderBlock

CinderBlock is Ember's built-in content blocking engine, forked from uBlock Origin. Fully documented in `github.com/sabeeirsharrma/cinderblock`.

**Ember Shell integration:**
- Dedicated toolbar button (no default keyboard shortcut, remappable)
- Dashboard accessible at `ember://cinderblock`
- Blocking stats visible in toolbar button tooltip
- Per-site toggle available from toolbar button dropdown

CinderBlock has its own repository, its own release cadence, and its own CPAC package. It does **not** ship bundled inside Ember releases — it's a declared dependency that CPAC installs alongside Ember. Filter lists update independently within the browser on a configurable schedule.

**Default filter lists:** AdGuard Base, AdGuard Tracking Protection, AdGuard Annoyances, EasyList, EasyPrivacy, Peter Lowe's, uBlock Filters, uBlock Annoyances, Dan Pollock's hosts, PhishTank, HAGEZI Multi Pro, StevenBlack Adware+Malware, oisd big. Gambling and adult content lists available as opt-in.

### 6.2 Coalbox

Coalbox is Ember's built-in password manager. Fully documented in `github.com/sabeeirsharrma/coalbox`.

**Ember Shell integration:**
- Dedicated toolbar button — lock/unlock state indicator
- Full vault accessible as a sidebar panel
- Autofill prompt appears below address bar when a login form is detected
- Address bar padlock icon when saved credentials exist for current site
- Save credential prompt after successful login detected
- TOTP autofill alongside username/password in one action
- Password generator accessible inline from any password field (right-click)
- Never autofills on HTTP — HTTPS only

Coalbox has its own repository, its own release cadence, and its own CPAC package — same as CinderBlock. Coalbox Core runs as a separate process from the browser entirely; Ember Shell is a client of it, not a host for it. A browser crash cannot corrupt the vault, and a Coalbox update never requires rebuilding Ember.

---

## 7. DNS over HTTPS

DoH is enabled by default and applies to browser traffic only. No system DNS is modified.

| Provider | URL | Notes |
|---|---|---|
| Cloudflare | `https://1.1.1.1/dns-query` | Default |
| Quad9 | `https://dns.quad9.net/dns-query` | Malware blocking at DNS level |
| Custom | User-defined | Supports NextDNS, AdGuard DNS, etc. |

DoH can be disabled in `ember.toml` for users who manage DNS at the system or router level.

---

## 8. Extension Model

Ember supports sideloading `.crx` files only. No built-in extension store, no Chrome Web Store connection.

Users source extensions themselves, audit them, and sideload them manually or via a watched directory:

```toml
[extensions]
sideload_dir = "~/.config/ember/extensions"
```

Any `.crx` dropped into this directory is loaded on next launch.

---

## 9. Search

DuckDuckGo is the default and only built-in search engine. Additional engines can be added manually in `ember.toml`:

```toml
[search]
default_engine = "duckduckgo"
show_suggestions = true
instant_search = false

[[search.engines]]
name = "Startpage"
url = "https://www.startpage.com/search?q=%s"
shortcut = "sp"
```

No search engine is added without explicit user action.

---

## 10. Build & Distribution

- **Build system:** GN + Ninja
- **Patch management:** Git patch series against upstream Chromium tags
- **CPAC integration:** Ember distributed as a source build via CPAC. CPAC handles source fetch, checksum verification, and building on the user's machine.
- **Component packaging:** CinderBlock and Coalbox are separate CPAC packages, declared as Ember dependencies. Each builds from its own repository with its own toolchain (CinderBlock: JS/dashboard build, Coalbox: Rust/Cargo). Neither is vendored into the Ember source tree.
- **Filter list updates:** Handled within the running browser, independent of CPAC
- **Component updates:** CinderBlock and Coalbox update on their own release schedules via CPAC, independent of Ember's release schedule. Ember Shell targets a minimum compatible version of each (see Section 6.0) rather than a pinned exact version.

---

## 11. Versioned Roadmap

### v0.1 — Bare Metal
- Chromium degoogled (all Google services stripped)
- DuckDuckGo as default search
- DoH enabled by default (Cloudflare)
- Builds reproducibly from source via GN + Ninja
- No telemetry confirmed via network audit
- CPAC package definition

### v0.2 — Ember Shell
- Custom WebUI shell replaces default Chromium UI
- Basic `ember.toml` config system (layout, appearance, typography)
- Dark/light/system theme
- Blank and clock new tab options
- Hot-reload on config change

### v0.3 — CinderBlock Integration
- CinderBlock (separate project/repo) declared as a CPAC dependency, minimum version pinned
- Ember Shell ships UI hooks: toolbar button, dashboard launcher, per-site toggle
- All default filter lists bundled and active (CinderBlock-side config)
- Opt-in lists available (gambling, adult)
- Custom list URL support
- 24-hour auto-update for lists

### v0.4 — Full Customization
- Complete layout customization (tab bar position, sidebar, toolbar)
- Full keybind remapping system including Vim preset
- Custom CSS injection
- All toolbar elements individually toggleable and reorderable

### v0.5 — Profiles + Extensions
- `.emberprofile` format defined
- Built-in profiles shipped (minimal, power, privacy, vim)
- CPAC community profile support
- Extension sideloading via directory

### v0.6 — DoH + Privacy Hardening
- Full DoH provider selection (Cloudflare, Quad9, custom)
- Fingerprint resistance levels (off, standard, strict)
- WebRTC policy controls
- Global Privacy Control header
- HTTPS-only mode

### v0.7 — CinderBlock Power Features
- Element picker
- Network logger
- Dynamic filtering
- Per-site rules
- Full CinderBlock dashboard

### v0.8 — Shell Features
- Tab groups (nested, color + letter coded, collapsible in sidebar)
- Reader mode
- Picture-in-Picture (persistent position/size, always-on-top, custom controls)
- Screenshot tool (viewport, full page, region)
- Notes panel + sticky note mode

### v0.9 — Coalbox Integration
- Coalbox (separate project/repo) declared as a CPAC dependency, minimum version pinned
- Ember Shell ships UI hooks: toolbar button, sidebar panel, autofill prompt
- TOTP autofill
- Inline password generator
- Address bar credential indicator

### v0.10 — Performance Pass
- Build size audit and reduction
- Startup time optimization
- Memory usage profiling
- Lazy-load non-critical shell components

### v0.11 — Stability + Docs
- Full `ember.toml` reference documentation
- Profile authoring guide
- Build-from-source guide
- CinderBlock and Coalbox integration docs
- Bug fix sprint, no new features

### v1.0 — Stable Release
- All features stable and documented
- CPAC package stable
- Community profile repository live
- Windows build target begins

---

## 12. Future Considerations

- **Windows / macOS builds** — post-v1.0, same source base, platform-specific shell adjustments
- **Ember Sync** — self-hosted only, encrypted, for bookmarks and settings across devices
- **CinderBlock rule sharing** — community per-site rule sets installable via CPAC
- **Reader mode enhancements** — text-to-speech, estimated reading time, print-optimized output
- **Per-profile containers** — tab containers with isolated storage (like Firefox Multi-Account Containers)
- **Native vertical tab group enhancements** — drag-and-drop reordering across groups, group export as bookmark folder
- **Coalbox SSH key storage** — store SSH keys in the vault, integrate with ssh-agent

---

## 13. Project Ecosystem

Each project below is independently developed, versioned, repo'd, and built. "Integrated into Ember" means Ember Shell provides UI hooks that consume the project's API at runtime — not that the project is compiled as part of Ember.

| Project | Role | Repo | Spec |
|---|---|---|---|
| **Ember** | The browser | TBD (Cinder org) | This document |
| **CinderBlock** | Content blocking engine (uBlock fork) | https://github.com/SabeeirSharrma/CinderBlock | `CINDERBLOCK_SPEC.md` |
| **Coalbox** | Password manager | https://github.com/SabeeirSharrma/CoalBox | `COALBOX_SPEC.md` |
| **CPAC** | Build verification + distribution | — | Separate spec |
| **CinderOS** | Arch-based Linux distro, ships Ember as default browser | — | Separate spec |

---

## 14. Project Info

**Repository:** TBD (The Cinder Project org)
**License:** TBD (BSD-compatible, to align with Chromium's license)
**Part of:** The Cinder Project
**Related projects:** CinderBlock, Coalbox, CPAC, CinderOS
