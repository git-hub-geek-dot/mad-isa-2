import crypto from 'node:crypto';

import { HttpError } from './errors.js';

export function createGameService({
  aiProvider,
  sessionStore,
  defaultMaxRounds = 4,
}) {
  return {
    async startGame(payload) {
      const theme = readRequiredRequestString(payload?.theme, 'theme');
      const tone = readOptionalString(payload?.tone) ?? 'dark_comedy';
      const promptHint = readOptionalString(payload?.promptHint) ?? '';
      const maxRounds = clamp(
        readOptionalInteger(payload?.maxRounds) ?? defaultMaxRounds,
        2,
        6,
      );

      const session = {
        sessionId: crypto.randomUUID(),
        categoryId: theme,
        tone,
        promptHint,
        maxRounds,
        currentRound: 1,
        history: [],
        lastChoices: [],
      };

      const turn = normalizeTurn(
        await aiProvider.generateTurn({
          mode: 'start',
          categoryId: session.categoryId,
          tone: session.tone,
          promptHint: session.promptHint,
          maxRounds: session.maxRounds,
          round: 1,
          history: session.history,
        }),
        { expectedFinal: false },
      );

      session.history.push({
        round: 1,
        scenario: turn.scenario,
      });
      session.lastChoices = toChoiceOptions(turn.choices);
      sessionStore.save(session);

      return toResponse(session, turn);
    },

    async continueGame(payload) {
      const sessionId = readRequiredRequestString(payload?.sessionId, 'sessionId');
      const selectedChoiceId = readOptionalString(payload?.selectedChoiceId);
      const session = sessionStore.get(sessionId);

      if (!session) {
        throw new HttpError(
          404,
          'session_not_found',
          'Session not found. Start a new game.',
        );
      }

      const selectedChoice = session.lastChoices.find(
        (choice) => choice.id === selectedChoiceId,
      );
      const selectedChoiceText =
        readOptionalString(payload?.selectedChoiceText) ?? selectedChoice?.text;

      if (!selectedChoiceText) {
        throw new HttpError(
          400,
          'invalid_choice',
          'selectedChoiceText or a valid selectedChoiceId is required.',
        );
      }

      const activeRound = session.history.at(-1);
      if (activeRound) {
        activeRound.selectedChoiceId = selectedChoice?.id ?? selectedChoiceId ?? '';
        activeRound.selectedChoiceText = selectedChoiceText;
      }

      const expectedFinal = session.currentRound >= session.maxRounds;
      const turn = normalizeTurn(
        await aiProvider.generateTurn({
          mode: expectedFinal ? 'final' : 'continue',
          categoryId: session.categoryId,
          tone: session.tone,
          promptHint: session.promptHint,
          maxRounds: session.maxRounds,
          round: expectedFinal ? session.currentRound : session.currentRound + 1,
          history: session.history,
          selectedChoiceText,
        }),
        { expectedFinal },
      );

      if (turn.isFinal) {
        sessionStore.delete(session.sessionId);
        return toResponse(session, turn, {
          round: session.maxRounds,
        });
      }

      session.currentRound += 1;
      session.history.push({
        round: session.currentRound,
        scenario: turn.scenario,
      });
      session.lastChoices = toChoiceOptions(turn.choices);
      sessionStore.save(session);

      return toResponse(session, turn);
    },
  };
}

function normalizeTurn(payload, { expectedFinal }) {
  if (payload == null || typeof payload !== 'object' || Array.isArray(payload)) {
    throw new HttpError(
      502,
      'invalid_ai_response',
      'AI provider returned an invalid payload.',
    );
  }

  const scenario = readRequiredAiString(payload.scenario, 'scenario');

  if (expectedFinal) {
    return {
      scenario,
      choices: [],
      isFinal: true,
      endingTitle: readRequiredAiString(payload.endingTitle, 'endingTitle'),
      roastLine: readRequiredAiString(payload.roastLine, 'roastLine'),
    };
  }

  if (!Array.isArray(payload.choices) || payload.choices.length !== 3) {
    throw new HttpError(
      502,
      'invalid_ai_response',
      'AI provider must return exactly three choices for non-final turns.',
    );
  }

  const choices = payload.choices.map((choice, index) =>
    readRequiredAiString(choice, `choices[${index}]`),
  );

  return {
    scenario,
    choices,
    isFinal: false,
    endingTitle: null,
    roastLine: null,
  };
}

function toChoiceOptions(choices) {
  return choices.map((text, index) => ({
    id: String.fromCharCode(97 + index),
    text,
  }));
}

function toResponse(session, turn, overrides = {}) {
  return {
    sessionId: session.sessionId,
    categoryId: session.categoryId,
    round: overrides.round ?? session.currentRound,
    maxRounds: session.maxRounds,
    scenario: turn.scenario,
    choices: turn.isFinal ? [] : session.lastChoices,
    isFinal: turn.isFinal,
    endingTitle: turn.endingTitle,
    roastLine: turn.roastLine,
  };
}

function readRequiredRequestString(value, fieldName) {
  const normalized = readOptionalString(value);
  if (!normalized) {
    throw new HttpError(
      400,
      'invalid_request',
      `${fieldName} is required.`,
    );
  }

  return normalized;
}

function readRequiredAiString(value, fieldName) {
  const normalized = readOptionalString(value);
  if (!normalized) {
    throw new HttpError(
      502,
      'invalid_ai_response',
      `AI response field ${fieldName} is required.`,
    );
  }

  return normalized;
}

function readOptionalString(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed === '' ? null : trimmed;
}

function readOptionalInteger(value) {
  if (typeof value === 'number' && Number.isInteger(value)) {
    return value;
  }

  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) ? parsed : null;
  }

  return null;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}
