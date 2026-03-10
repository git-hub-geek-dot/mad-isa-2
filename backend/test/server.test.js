import assert from 'node:assert/strict';
import { once } from 'node:events';
import test from 'node:test';

import { createGameService } from '../src/game-service.js';
import { createMockAiProvider } from '../src/providers.js';
import { createServer } from '../src/server.js';
import { createInMemorySessionStore } from '../src/session-store.js';

test('POST /game/start returns an opening round with choices', async () => {
  await withServer(async (baseUrl) => {
    const { response, json } = await postJson(`${baseUrl}/game/start`, {
      theme: 'relationship_chaos',
      tone: 'dark_comedy',
      maxRounds: 4,
      promptHint: 'social media chaos',
    });

    assert.equal(response.status, 200);
    assert.equal(typeof json.sessionId, 'string');
    assert.equal(json.categoryId, 'relationship_chaos');
    assert.equal(json.round, 1);
    assert.equal(json.maxRounds, 4);
    assert.equal(json.isFinal, false);
    assert.equal(json.choices.length, 3);
  });
});

test('POST /game/continue reaches a final ending after the configured rounds', async () => {
  await withServer(async (baseUrl) => {
    let current = await startSession(baseUrl, 'daily_absurdity', 3);

    assert.equal(current.json.round, 1);

    current = await continueWithFirstChoice(baseUrl, current.json);
    assert.equal(current.response.status, 200);
    assert.equal(current.json.round, 2);
    assert.equal(current.json.isFinal, false);

    current = await continueWithFirstChoice(baseUrl, current.json);
    assert.equal(current.response.status, 200);
    assert.equal(current.json.round, 3);
    assert.equal(current.json.isFinal, false);

    current = await continueWithFirstChoice(baseUrl, current.json);
    assert.equal(current.response.status, 200);
    assert.equal(current.json.round, 3);
    assert.equal(current.json.isFinal, true);
    assert.equal(typeof current.json.endingTitle, 'string');
    assert.equal(typeof current.json.roastLine, 'string');
    assert.equal(current.json.choices.length, 0);
  });
});

test('POST /game/start validates required fields', async () => {
  await withServer(async (baseUrl) => {
    const { response, json } = await postJson(`${baseUrl}/game/start`, {
      tone: 'dark_comedy',
    });

    assert.equal(response.status, 400);
    assert.equal(json.error.code, 'invalid_request');
    assert.match(json.error.message, /theme is required/i);
  });
});

async function withServer(run) {
  const gameService = createGameService({
    aiProvider: createMockAiProvider({ random: () => 0 }),
    sessionStore: createInMemorySessionStore(),
    defaultMaxRounds: 4,
  });
  const server = createServer({
    gameService,
    logger: { error() {} },
  });

  server.listen(0, '127.0.0.1');
  await once(server, 'listening');

  const address = server.address();
  const baseUrl = `http://127.0.0.1:${address.port}`;

  try {
    await run(baseUrl);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

async function startSession(baseUrl, theme, maxRounds) {
  return postJson(`${baseUrl}/game/start`, {
    theme,
    tone: 'dark_comedy',
    maxRounds,
    promptHint: 'test prompt',
  });
}

async function continueWithFirstChoice(baseUrl, session) {
  return postJson(`${baseUrl}/game/continue`, {
    sessionId: session.sessionId,
    selectedChoiceId: session.choices[0].id,
    selectedChoiceText: session.choices[0].text,
  });
}

async function postJson(url, payload) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  return {
    response,
    json: await response.json(),
  };
}
