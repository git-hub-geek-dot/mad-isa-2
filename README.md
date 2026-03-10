# AI-Based Dynamic Scenario Simulation Game

Flutter mobile game where each run is a short 3-4 round interactive scenario. The app supports both a local mock AI flow and a real backend API.

## Project Layout

- `lib/`: Flutter app
- `backend/`: lightweight Node backend with `/game/start` and `/game/continue`

## Flutter App

Run the app in local mock mode:

```bash
flutter run
```

Run the app against the backend:

```bash
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

Notes:

- Android emulator uses `http://10.0.2.2:8787`
- iOS simulator and desktop can use `http://localhost:8787`
- Physical devices should use your computer's LAN IP instead of `localhost`

## Backend

The backend is dependency-free and uses:

- in-memory session storage for the MVP
- mock AI mode for local development
- an OpenAI-compatible chat completions endpoint for live generation

### Start The Backend

Mock mode:

```bash
cd backend
node src/index.js
```

Live AI mode:

1. Create `backend/.env`
2. Add:

```env
PORT=8787
USE_MOCK_AI=false
AI_API_URL=https://api.openai.com/v1/chat/completions
AI_API_KEY=your_api_key
AI_MODEL=your_model_name
DEFAULT_MAX_ROUNDS=4
```

3. Start the server:

```bash
cd backend
node src/index.js
```

Health check:

```bash
curl http://localhost:8787/health
```

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

Backend:

```bash
cd backend
node --test
```
