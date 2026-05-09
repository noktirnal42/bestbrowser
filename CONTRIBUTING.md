# Contributing

BestBrowser is still moving quickly, so the most helpful contributions are the ones that improve clarity, reliability, and polish without fighting the current architecture direction.

## Before You Change Things

- Read [README.md](README.md)
- Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Check [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

## Preferred Contribution Style

- Make focused, coherent changes
- Prefer extending the newer store/service/feature structure over reviving monolithic patterns
- Preserve the existing brand palette and UI direction
- Test behavior changes with `swift build`, and `./test.sh` when appropriate

## Local Workflow

```bash
cd /Users/jeremymcvay/dev/bestbrowser-native
swift build
./test.sh
./build.sh
```

## Good Areas for Contribution

- UI consistency and spacing polish
- browser/session reliability
- privacy and compatibility fixes
- media provider behavior
- documentation and release polish

## Areas That Need Extra Care

- authentication and passkey behavior
- WebKit compatibility changes
- ad/tracker blocking rules
- media control logic
- anything that touches scene routing or persistent session state

## Pull Request Guidance

A good PR here usually explains:

- what user-facing problem it fixes
- whether it changes browser behavior, media behavior, or privacy behavior
- how it was verified

If the change affects packaging or release behavior, mention whether `./build.sh` was run successfully.
