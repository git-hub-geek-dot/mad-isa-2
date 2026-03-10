import http from 'node:http';

import { HttpError } from './errors.js';

export function createServer({ gameService, logger = console }) {
  return http.createServer(async (request, response) => {
    try {
      applyCors(response);

      if (request.method === 'OPTIONS') {
        response.writeHead(204);
        response.end();
        return;
      }

      const url = new URL(request.url ?? '/', 'http://localhost');

      if (request.method === 'GET' && url.pathname === '/health') {
        sendJson(response, 200, { status: 'ok' });
        return;
      }

      if (request.method === 'POST' && url.pathname === '/game/start') {
        const body = await readJsonBody(request);
        const session = await gameService.startGame(body);
        sendJson(response, 200, session);
        return;
      }

      if (request.method === 'POST' && url.pathname === '/game/continue') {
        const body = await readJsonBody(request);
        const session = await gameService.continueGame(body);
        sendJson(response, 200, session);
        return;
      }

      throw new HttpError(404, 'not_found', 'Route not found.');
    } catch (error) {
      const httpError = normalizeError(error);

      if (httpError.statusCode >= 500) {
        logger.error(httpError);
      }

      sendJson(response, httpError.statusCode, {
        error: {
          code: httpError.code,
          message: httpError.message,
          details: httpError.details ?? null,
        },
      });
    }
  });
}

async function readJsonBody(request) {
  const chunks = [];
  let size = 0;

  for await (const chunk of request) {
    size += chunk.length;
    if (size > 1024 * 1024) {
      throw new HttpError(413, 'payload_too_large', 'Request body is too large.');
    }

    chunks.push(chunk);
  }

  const rawBody = Buffer.concat(chunks).toString('utf8').trim();
  if (rawBody == '') {
    return {};
  }

  try {
    return JSON.parse(rawBody);
  } catch {
    throw new HttpError(400, 'invalid_json', 'Request body must be valid JSON.');
  }
}

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(payload));
}

function applyCors(response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  response.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
}

function normalizeError(error) {
  if (error instanceof HttpError) {
    return error;
  }

  return new HttpError(
    500,
    'internal_error',
    'Unexpected server error.',
  );
}
