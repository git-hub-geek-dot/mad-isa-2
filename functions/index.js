import { onRequest } from 'firebase-functions/v2/https';

import { HttpError } from './src/errors.js';
import { createGameService } from './src/game-service.js';
import { createAiProvider } from './src/providers.js';
import { createInMemorySessionStore } from './src/session-store.js';

const config = loadConfig();
const gameService = createGameService({
  aiProvider: createAiProvider(config),
  sessionStore: createInMemorySessionStore(),
  defaultMaxRounds: config.defaultMaxRounds,
});

export const api = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (request, response) => {
    try {
      const pathname = normalizePath(request.path ?? '/');

      if (request.method == 'GET' && pathname == '/health') {
        response.status(200).json({ status: 'ok' });
        return;
      }

      if (request.method == 'POST' && pathname == '/game/start') {
        const session = await gameService.startGame(readBody(request));
        response.status(200).json(session);
        return;
      }

      if (request.method == 'POST' && pathname == '/game/continue') {
        const session = await gameService.continueGame(readBody(request));
        response.status(200).json(session);
        return;
      }

      throw new HttpError(404, 'not_found', 'Route not found.');
    } catch (error) {
      const httpError = normalizeError(error);
      response.status(httpError.statusCode).json({
        error: {
          code: httpError.code,
          message: httpError.message,
          details: httpError.details ?? null,
        },
      });
    }
  },
);

function loadConfig(env = process.env) {
  const defaultMaxRounds = clamp(parseInteger(env.DEFAULT_MAX_ROUNDS, 4), 2, 6);
  const useMockAi = parseBoolean(env.USE_MOCK_AI, true);
  const aiApiUrl =
    (env.AI_API_URL ?? 'https://api.openai.com/v1/chat/completions').trim();
  const aiApiKey = (env.AI_API_KEY ?? '').trim();
  const aiModel = (env.AI_MODEL ?? '').trim();

  if (!useMockAi && !aiApiKey) {
    throw new HttpError(
      500,
      'missing_ai_api_key',
      'AI_API_KEY is required when USE_MOCK_AI is false.',
    );
  }

  if (!useMockAi && !aiModel) {
    throw new HttpError(
      500,
      'missing_ai_model',
      'AI_MODEL is required when USE_MOCK_AI is false.',
    );
  }

  return {
    defaultMaxRounds,
    useMockAi,
    aiApiUrl,
    aiApiKey,
    aiModel,
  };
}

function normalizePath(path) {
  if (path.startsWith('/api/')) {
    return path.slice(4);
  }

  if (path == '/api') {
    return '/';
  }

  return path;
}

function readBody(request) {
  if (request.body == null || request.body == '') {
    return {};
  }

  if (typeof request.body == 'string') {
    return JSON.parse(request.body);
  }

  if (Buffer.isBuffer(request.body)) {
    return JSON.parse(request.body.toString('utf8'));
  }

  return request.body;
}

function normalizeError(error) {
  if (error instanceof HttpError) {
    return error;
  }

  return new HttpError(500, 'internal_error', 'Unexpected server error.');
}

function parseInteger(value, fallback) {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseBoolean(value, fallback) {
  if (value == null || value.trim() == '') {
    return fallback;
  }

  return !['0', 'false', 'no', 'off'].includes(value.trim().toLowerCase());
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}
