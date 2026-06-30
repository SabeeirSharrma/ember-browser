# Ember Patches

Git patch series applied against upstream Chromium source. Each patch is a single logical change.

## Patch Order

Patches are applied in directory order, then alphabetically within each directory:

1. **`degoogle/`** — Removal of Google services, API keys, and endpoints
2. **`privacy/`** — Privacy hardening (telemetry, safe browsing, fingerprinting)
3. **`search/`** — Default search engine configuration (DuckDuckGo)
4. **`shell/`** — Ember Shell hooks and WebUI integration points

## Creating Patches

```bash
# From inside chromium/src
git diff > /path/to/ember/patches/degoogle/001-remove-google-api-keys.patch
```

Patch naming convention: `NNN-short-description.patch`

## Patch Requirements

- One logical change per patch
- Must apply cleanly against the target Chromium tag
- Must not break the build (each patch should leave Chromium in a buildable state)
- Versioned against specific Chromium tags in `build.sh`

## Updating Patches

When rebasing to a new Chromium version:

1. Update `CHROMIUM_VERSION` in `build.sh`
2. Re-apply each patch, resolving conflicts
3. Update or regenerate patches that no longer apply
4. Test that the full build completes
