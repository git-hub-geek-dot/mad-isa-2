import { HttpError } from './errors.js';

export function createAiProvider(config) {
  if (config.useMockAi) {
    return createMockAiProvider();
  }

  return createOpenAiCompatibleProvider(config);
}

function createMockAiProvider() {
  return {
    async generateTurn(input) {
      if (input.mode == 'final') {
        return {
          scenario:
              'The story collapses in a strangely elegant pile of screenshots and bad instincts.',
          endingTitle: 'Mission Complete: Firebase Route',
          roastLine:
              'You navigated chaos with the confidence of a GPS that lost the satellite feed.',
        };
      }

      return {
        scenario:
            'A harmless text message now looks legally suspicious, three people are overreacting, and the universe has decided subtlety is canceled for the day.',
        choices: [
          'Pretend this is strategy.',
          'Escalate with fake maturity.',
          'Ask a chaotic friend for backup.',
        ],
      };
    },
  };
}

function createOpenAiCompatibleProvider(config) {
  return {
    async generateTurn(input) {
      let upstreamResponse;

      try {
        upstreamResponse = await fetch(config.aiApiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${config.aiApiKey}`,
          },
          body: JSON.stringify({
            model: config.aiModel,
            temperature: 1,
            response_format: {
              type: 'json_object',
            },
            messages: buildMessages(input),
          }),
          signal: AbortSignal.timeout(35000),
        });
      } catch {
        throw new HttpError(
          502,
          'ai_unreachable',
          'Could not reach the AI provider.',
        );
      }

      if (!upstreamResponse.ok) {
        const responseText = await upstreamResponse.text();
        throw new HttpError(
          502,
          'ai_upstream_error',
          `AI provider request failed with status ${upstreamResponse.status}.`,
          responseText.slice(0, 400),
        );
      }

      const upstreamJson = await upstreamResponse.json();
      const content = extractAssistantContent(upstreamJson);
      return parseJsonPayload(content);
    },
  };
}

function buildMessages(input) {
  return [
    {
      role: 'system',
      content: [
        'You generate short interactive story turns for a mobile simulation game.',
        'Tone: dark comedy, but safe and PG-13.',
        'Avoid hate speech, slurs, graphic violence, explicit sexual content, minors, self-harm encouragement, or illegal instructions.',
        'Return JSON only. No markdown fences. No extra commentary.',
        'For non-final turns, output exactly: {"scenario":"50-80 words","choices":["choice 1","choice 2","choice 3"]}.',
        'For final turns, output exactly: {"scenario":"20-45 words","endingTitle":"Mission Complete: ...","roastLine":"one humorous roast"}.',
      ].join(' '),
    },
    {
      role: 'user',
      content: buildUserPrompt(input),
    },
  ];
}

function buildUserPrompt(input) {
  const history = input.history.length == 0
      ? 'No prior story.'
      : input.history
          .map((entry) => {
            const lines = [`Round ${entry.round} scenario: ${entry.scenario}`];
            if (entry.selectedChoiceText) {
              lines.push(`Player choice: ${entry.selectedChoiceText}`);
            }
            return lines.join('\n');
          })
          .join('\n\n');

  if (input.mode == 'start') {
    return [
      `Mode: ${input.mode}`,
      `Theme ID: ${input.categoryId}`,
      `Prompt hint: ${input.promptHint || 'none provided'}`,
      `Tone: ${input.tone}`,
      `Round: 1 of ${input.maxRounds}`,
      'Create the opening scenario with exactly three distinct player choices.',
      `Story so far:\n${history}`,
    ].join('\n\n');
  }

  if (input.mode == 'final') {
    return [
      `Mode: ${input.mode}`,
      `Theme ID: ${input.categoryId}`,
      `Prompt hint: ${input.promptHint || 'none provided'}`,
      `Tone: ${input.tone}`,
      `Final resolution after round ${input.round} of ${input.maxRounds}`,
      `Latest player choice: ${input.selectedChoiceText}`,
      'Resolve the story, close the arc, and roast the player. Do not provide choices.',
      `Story so far:\n${history}`,
    ].join('\n\n');
  }

  return [
    `Mode: ${input.mode}`,
    `Theme ID: ${input.categoryId}`,
    `Prompt hint: ${input.promptHint || 'none provided'}`,
    `Tone: ${input.tone}`,
    `Continue with round ${input.round} of ${input.maxRounds}`,
    `Latest player choice: ${input.selectedChoiceText}`,
    'Continue the story with one new scenario and exactly three distinct choices.',
    `Story so far:\n${history}`,
  ].join('\n\n');
}

function extractAssistantContent(payload) {
  const content = payload?.choices?.[0]?.message?.content;

  if (typeof content == 'string') {
    return content;
  }

  if (Array.isArray(content)) {
    return content
        .map((item) => {
          if (typeof item == 'string') {
            return item;
          }

          if (typeof item?.text == 'string') {
            return item.text;
          }

          return '';
        })
        .join('\n');
  }

  throw new HttpError(
    502,
    'invalid_ai_response',
    'AI provider did not return message content in the expected format.',
  );
}

function parseJsonPayload(rawContent) {
  if (rawContent != null && typeof rawContent == 'object') {
    return rawContent;
  }

  if (typeof rawContent != 'string') {
    throw new HttpError(
      502,
      'invalid_ai_response',
      'AI provider content was not a JSON string.',
    );
  }

  const trimmed = rawContent.trim();
  const fenced = trimmed.startsWith('```')
      ? trimmed.replace(/^```(?:json)?/i, '').replace(/```$/, '').trim()
      : trimmed;
  const objectStart = fenced.indexOf('{');
  const objectEnd = fenced.lastIndexOf('}');
  const candidate =
      objectStart >= 0 && objectEnd > objectStart
          ? fenced.slice(objectStart, objectEnd + 1)
          : fenced;

  try {
    return JSON.parse(candidate);
  } catch {
    throw new HttpError(
      502,
      'invalid_ai_response',
      'AI provider returned content that was not valid JSON.',
    );
  }
}
