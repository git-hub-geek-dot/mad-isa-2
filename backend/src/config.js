import fs from 'node:fs';

import { HttpError } from './errors.js';

export function loadDotEnv(
  env = process.env,
  fileUrl = new URL('../.env', import.meta.url),
) {
  if (!fs.existsSync(fileUrl)) {
    return;
  }

  const content = fs.readFileSync(fileUrl, 'utf8');
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (line === '' || line.startsWith('#')) {
      continue;
    }

    const separatorIndex = line.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith('\'') && value.endsWith('\''))
    ) {
      value = value.slice(1, -1);
    }

    if (!(key in env) || env[key] === '') {
      env[key] = value;
    }
  }
}

export function loadConfig(env = process.env) {
  const port = parseInteger(env.PORT, 8787);
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
    port,
    defaultMaxRounds,
    useMockAi,
    aiApiUrl,
    aiApiKey,
    aiModel,
  };
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
