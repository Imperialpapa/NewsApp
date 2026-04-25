# NewsApp — Flutter (Android first)

Morning financial news digest client. Reads `digests` + `articles` from Supabase, renders them with Korean/English toggle. Push notifications and AdMob come in later phases.

## Setup (first run)

### 1. Enable Anonymous Sign-In in Supabase

Supabase → your project → **Authentication** → **Sign In / Up** (or **Providers**) → enable **"Allow anonymous sign-ins"**. This is **off by default**. The app uses anonymous auth so users don't need an email on first launch.

### 2. Get the Publishable (anon) key

Supabase → **Project Settings** → **API Keys** → copy the **Publishable key** (green badge, format: `sb_publishable_...`).

⚠️ **Not the Secret key** — that's for backend only. The Publishable key is designed for client apps and is safe to ship in the APK.

### 3. Fill in `app/.env`

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...
```

### 4. Run on your Android device

Enable **USB debugging** on your phone (Settings → About phone → tap Build Number 7 times → Developer Options → USB debugging), plug in via USB, then:

```bash
cd app
flutter devices      # confirm your phone is listed
flutter run          # or pick the device with -d <id>
```

First build takes 3–5 minutes. Hot reload (`r` in terminal) after that.

## What's in it now (Phase 2 MVP)

- Anonymous auth on launch (Supabase)
- **Today's Market** screen: ordered list of top 3–5 stories
- Tap card → opens original article in browser
- Bloomberg/FT cards show headline only (link icon), others show summary
- **Settings** screen:
  - Language toggle (한국어 / English)
  - Notification time picker (KST)
  - Source on/off toggles
- Material 3 light/dark theme

## What's NOT in yet

| Feature | Phase |
|---|---|
| Local notifications at configured time | 2b |
| FCM push from server | 2c |
| AdMob banner | 2d |
| Email/Google sign-in (account sync across devices) | 3 |
| iOS build polish | 4 |

## Common issues

- **"SUPABASE_URL null"** → `.env` missing or unreadable. Check `assets: [.env]` in `pubspec.yaml`.
- **auth 403 on first load** → anonymous sign-in not enabled in Supabase (see step 1).
- **empty digest view** → backend pipeline didn't run yet. From project root: `python -m backend.main`.
- **Korean text shows as boxes** → phone missing Korean fonts? Unlikely, but add `google_fonts` + Noto Sans KR if needed.

## Package ID

`com.nolgaemi.todaysmarket` — set via `android/app/build.gradle.kts` (`applicationId` and `namespace`). Matches the Play Console-issued package name. Changing after Play Store publish is painful.
