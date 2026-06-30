# Ember Browser

A privacy-focused, fully customizable Chromium-based browser. Part of [The Cinder Project](https://github.com/SabeeirSharrma).

**Status:** v0.1 — Bare Metal (in development)

## What is Ember?

Ember is a browser distro, not a browser product. It's Chromium compiled from source with all Google services stripped, rebuilt with a configurable shell and integrated privacy tools.

- **Auditability** — every component compiled from source, nothing ships as opaque binaries
- **Privacy by default** — no telemetry, no Google services, DuckDuckGo default, DoH enabled
- **Total customization** — every UI element configurable via `ember.toml`

## Architecture

```
Ember Browser
├── Ember Shell (WebUI)     — Custom browser UI, configurable via ember.toml
├── CinderBlock             — Content blocker (uBlock fork), separate project
├── Coalbox                 — Password manager, separate project
├── Ember Config            — ember.toml, hot-reload, profiles
├── DoH Resolver            — Cloudflare/Quad9/custom, browser traffic only
└── Chromium Engine         — Degoogleled, rendering (Blink), JS (V8)
```

## Building from Source

### Prerequisites

- Linux (x86_64 or AArch64)
- `git`, `python3`, `clang`, `lld`, `ninja`
- ~100GB disk space for Chromium source + build
- `depot_tools` in your PATH

### Build

```bash
# Fetch Chromium source (~30 min)
./build.sh --fetch

# Apply Ember patches
./build.sh --patch

# Configure GN build args
./build.sh --configure

# Build (takes a while)
./build.sh --build

# Or all at once
./build.sh --all
```

### Quick Build

```bash
./build.sh --all
```

The binary will be at `chromium/src/out/Default/chrome`.

## Project Structure

```
ember-browser/
├── spec.md                 # Full project specification
├── build.sh                # Main build script
├── cpac.toml               # CPAC package definition
├── patches/
│   ├── degoogle/           # Google service removal patches
│   ├── privacy/            # Privacy hardening patches
│   ├── search/             # Search engine configuration
│   └── shell/              # Ember Shell integration hooks
├── scripts/
│   └── network-audit.sh    # Verify no telemetry connections
├── ci/                     # CI configuration
└── docs/                   # Documentation
```

## Related Projects

| Project | Description |
|---|---|
| [CinderBlock](https://github.com/SabeeirSharrma/CinderBlock) | Content blocking engine (uBlock fork) |
| [Coalbox](https://github.com/SabeeirSharrma/coalbox) | Local-first password manager |
| CPAC | Build verification and distribution (planned) |
| CinderOS | Arch-based Linux distro with Ember (planned) |

## License

BSD 3-Clause — see [LICENSE](LICENSE)

## Part of The Cinder Project
