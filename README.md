# 🐾 Pet Connect

Welcome to **Pet Connect**, a premium platform linking pet owners, adoption shelters, and veterinary services seamlessly. Built to unify and elevate pet management, this app provides dedicated workflows uniquely tailored for community engagement, daily health tracking, and professional adoption logistics.

---

## ✨ Features

- **Premium Interface (`Phase 3 Polished`)**: An elegant, dynamic, and glassmorphic UI driven heavily by responsive `CustomScrollView` cards and `SliverAppBar` transitions for an effortless, delightful user experience.
- **Centralized Pet Profiles**: Keep robust, expandable cards detailing age, diet, preferred traits, weight, and vaccination history via unified Add/Edit gateways.
- **Live Notification Hub**: An active, WebSocket-subscribed bell keeps Shelters and Users in sync with real-time adoption and query alerts.
- **Shelter Operations**: Dedicated shelter hubs allow instantaneous listing of animals and robust analytics viewing without sacrificing architectural cleanliness.
- **Unified Health Calendars**: Granular tracking grids to log wellness metrics right out of your pocket.

---

## 🛠 Tech Stack

- **Frontend Environment**: [Flutter](https://flutter.dev/) & Dart
- **Backend & State Architecture**: [Supabase](https://supabase.com/) (PostgreSQL, DB Subscriptions, Cloud Buckets, Edge Functions)
- **Aesthetic Core**: High-fidelity Google `Poppins` Font styling & integrated modern pastel shadows.

---

## 🚀 Environment Setup

If cloning locally, configure your workspace:

1. Validate you are working from the `main` or `Amay` branch (`main` is a fast-forward replica of `Amay`).
2. Run standard initialization:
   ```bash
   flutter clean
   flutter pub get
   ```
3. Establish your secrets. Inside `lib/utils` or equivalent environment configs, store your Supabase keys (`supabaseUrl`, `supabaseAnonKey`).
4. Boot the simulator:
   ```bash
   flutter build ios # or android, flutter run
   ```

---

## 🤝 Project State
`main` operates as the primary stable branch and accurately reflects the completion of all **Phase 3 UI Overhauls** (including proper Edit/Delete flows and premium widget consolidations).
