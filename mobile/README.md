# NAWAFETH Mobile

## API environment setup

The app now reads API configuration from `--dart-define` values.

Supported keys:
- `API_TARGET=auto|local|render`
- `API_BASE_URL=https://example.com` (highest priority if provided)
- `API_LOCAL_BASE_URL=http://192.168.1.10:8000` (optional local override)
- `API_RENDER_BASE_URL=https://nawafeth-2290.onrender.com` (optional render override)

Default behavior:
- Uses production backend (`https://nawafeth-2290.onrender.com`) unless overridden via `--dart-define`.

## Run commands

Use local backend API:

```bash
flutter run -d emulator-5554 --dart-define=API_TARGET=local
```

Use Render backend API:

```bash
flutter run -d emulator-5554 --dart-define=API_TARGET=render
```

Force a specific API URL (local or remote):

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://nawafeth-2290.onrender.com
```
