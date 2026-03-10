import { loadConfig, loadDotEnv } from './config.js';
import { createGameService } from './game-service.js';
import { createAiProvider } from './providers.js';
import { createServer } from './server.js';
import { createInMemorySessionStore } from './session-store.js';

loadDotEnv();
const config = loadConfig();
const aiProvider = createAiProvider(config);
const sessionStore = createInMemorySessionStore();
const gameService = createGameService({
  aiProvider,
  sessionStore,
  defaultMaxRounds: config.defaultMaxRounds,
});
const server = createServer({ gameService });

server.listen(config.port, () => {
  console.log(`Backend listening on http://localhost:${config.port}`);
});
