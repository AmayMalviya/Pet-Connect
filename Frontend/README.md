# pet_connect_app

A new Flutter project.

## Getting Started

This project uses HERE Maps (Raster Tile API) + HERE Search (Discover API) on the map screen.

### Configure HERE API key

To run without any extra flags (like before), create a local `.env` file:

```bash
cd Frontend
cp .env.example .env
```

Then set `HERE_API_KEY=` inside `.env`, and just run:

```bash
flutter run
```

### Alternative: pass at run-time (no files)

You can also run with `--dart-define`:

```bash
flutter run --dart-define=HERE_API_KEY="<YOUR_HERE_API_KEY>"
```

Or create a local JSON define file (not committed) based on `.env/example.json`:

```bash
cp .env/example.json .env/dev.json
```

Then run:

```bash
flutter run --dart-define-from-file=.env/dev.json
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
