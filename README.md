# AI-Based Dynamic Scenario Simulation Game

Flutter mobile game where each run is a short 3-4 round interactive scenario. The app now supports:

- live Groq-backed scenario generation through a Node backend
- anonymous Firebase Authentication
- Firestore history for completed runs
- Firebase Functions + Hosting deployment for the backend API
- Render deployment for the Node backend API

## Project Layout

- `lib/`: Flutter app
- `backend/`: local Node backend used during development
- `functions/`: Firebase Functions deployment target for the same API contract
- `render.yaml`: Render blueprint for deploying the Node backend
- `firebase.json`, `firestore.rules`: Firebase Hosting and Firestore config

## Local Development

### 1. Start the backend

Create `backend/.env` from `backend/.env.example`, then start the server:

```bash
cd backend
node src/index.js
```

Health check:

```bash
curl http://localhost:8787/health
```

### 2. Run Flutter

Without Firebase configured yet, the app still works and simply disables auth/history:

```bash
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

Notes:

- Android emulator uses `http://10.0.2.2:8787`
- iOS simulator and desktop can use `http://localhost:8787`
- Physical devices should use your computer's LAN IP instead of `localhost`

## Firebase Auth + Firestore

The Flutter app uses Firebase only when valid app options are supplied. When configured, it:

- signs users in anonymously on startup
- saves completed runs to Firestore under `users/{uid}/game_history/{sessionId}`
- shows recent saved runs on the home screen

### Firebase Console Setup

1. Create a Firebase project.
2. Enable **Authentication -> Anonymous**.
3. Create a **Cloud Firestore** database.
4. Deploy the included Firestore rules:

```bash
firebase deploy --only firestore:rules
```

### Flutter Firebase Configuration

The repo includes a placeholder [firebase_options.dart](./lib/firebase_options.dart) that reads values from `--dart-define`.

The fastest setup path is:

1. Copy `firebase/flutter_config.example.json` to `firebase/flutter_config.local.json`
2. Fill in your Firebase project values from the Firebase console
3. Run Flutter with `--dart-define-from-file`

Minimum Android run example:

```bash
flutter run --dart-define-from-file=firebase/flutter_config.local.json
```

For Android emulator, keep:

```json
"API_BASE_URL": "http://10.0.2.2:8787"
```

For Windows desktop or iOS simulator, change it to:

```json
"API_BASE_URL": "http://localhost:8787"
```

If you prefer the standard FlutterFire workflow, you can also run `flutterfire configure` later and replace the placeholder options file with the generated one.

## Firebase Functions + Hosting

The `functions/` directory exposes the same API routes as the local backend:

- `POST /game/start`
- `POST /game/continue`
- `GET /health`

Hosting rewrites route `/api/**` to the `api` function, so after deployment your mobile app can target:

```text
https://your-project.web.app/api
```

### Functions Environment

Create `functions/.env` from `functions/.env.example` and add your Groq key:

```env
USE_MOCK_AI=false
AI_API_URL=https://api.groq.com/openai/v1/chat/completions
AI_API_KEY=your_groq_key
AI_MODEL=llama-3.1-8b-instant
DEFAULT_MAX_ROUNDS=4
```

### Firebase Deploy Steps

1. Install Firebase CLI if needed:

```bash
npm install -g firebase-tools
```

2. Log in and pick your project:

```bash
firebase login
copy .firebaserc.example .firebaserc
```

3. Replace the project id inside `.firebaserc`.
4. Build Flutter web if you want Hosting to serve the app shell too:

```bash
flutter build web
```

5. Deploy:

```bash
firebase deploy --only functions,firestore:rules,hosting
```

## Render Deployment

If you want to avoid Firebase Functions billing, deploy the plain Node backend on Render instead.

The repo includes [render.yaml](./render.yaml), which points Render at the `backend/` service and expects the same API contract:

- `POST /game/start`
- `POST /game/continue`
- `GET /health`

### Render Setup

1. Push the repo to GitHub.
2. In Render, create a new **Web Service** from the repo.
3. Set the root directory to `backend` if Render does not pick it up from `render.yaml`.
4. Add the secret env var:

```text
AI_API_KEY=your_groq_key
```

The rest of the environment is already described in `render.yaml`:

- `HOST=0.0.0.0`
- `USE_MOCK_AI=false`
- `AI_API_URL=https://api.groq.com/openai/v1/chat/completions`
- `AI_MODEL=llama-3.1-8b-instant`
- `DEFAULT_MAX_ROUNDS=4`

After deployment, Render will give you a public backend URL like:

```text
https://mad-isa-backend.onrender.com
```

Point Flutter at that URL by changing `API_BASE_URL` in `firebase/flutter_config.local.json`, for example:

```json
"API_BASE_URL": "https://mad-isa-backend.onrender.com"
```

For a physical Android device or APK build, this is the easiest way to avoid local network setup.

## API Contract

`POST /game/start`

```json
{
  "theme": "relationship_chaos",
  "tone": "dark_comedy",
  "maxRounds": 4,
  "promptHint": "boyfriend and girlfriend drama with social-media chaos"
}
```

`POST /game/continue`

```json
{
  "sessionId": "session-id",
  "selectedChoiceId": "a",
  "selectedChoiceText": "Reply with \"interesting\" and let dread do the heavy lifting."
}
```

## Verification

Flutter:

```bash
flutter analyze
flutter test
```

Local backend:

```bash
cd backend
node --test
```

Functions syntax:

```bash
node --check functions/index.js
node --check functions/src/game-service.js
node --check functions/src/providers.js
```
