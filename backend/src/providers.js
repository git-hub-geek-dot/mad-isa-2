import { HttpError } from './errors.js';

export function createAiProvider(config) {
  if (config.useMockAi) {
    return createMockAiProvider();
  }

  return createOpenAiCompatibleProvider(config);
}

export function createMockAiProvider({ random = Math.random } = {}) {
  return {
    async generateTurn(input) {
      const script = MOCK_SCRIPTS[input.categoryId] ?? MOCK_SCRIPTS.daily_absurdity;

      if (input.mode === 'final') {
        const roast =
          script.roastLines[Math.floor(random() * script.roastLines.length)];
        const lastChoice =
          input.selectedChoiceText?.trim() || 'making an objectively wild choice';

        return {
          scenario:
            'The dust settles, the screenshots stop spreading, and the universe decides you have been embarrassing enough for one session.',
          endingTitle: script.endingTitle,
          roastLine: `${roast} Ending on "${lastChoice}" was the kind of decision that keeps group chats hydrated for weeks.`,
        };
      }

      const beat = script.rounds[(input.round - 1) % script.rounds.length];
      const callback =
        input.mode === 'start'
          ? 'Nobody has ruined this yet, which feels temporary.'
          : `Your previous move was "${input.selectedChoiceText}", so the tension now has receipts.`;

      return {
        scenario: `${beat.scenario} ${callback}`,
        choices: beat.choices,
      };
    },
  };
}

export function createOpenAiCompatibleProvider(config) {
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
        'Avoid hate speech, slurs, graphic violence, sexual assault, minors, explicit sexual content, self-harm encouragement, or illegal instructions.',
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
  const history = input.history.length === 0
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

  if (input.mode === 'start') {
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

  if (input.mode === 'final') {
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

  if (typeof content === 'string') {
    return content;
  }

  if (Array.isArray(content)) {
    return content
        .map((item) => {
          if (typeof item === 'string') {
            return item;
          }

          if (typeof item?.text === 'string') {
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
  if (rawContent != null && typeof rawContent === 'object') {
    return rawContent;
  }

  if (typeof rawContent !== 'string') {
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

const MOCK_SCRIPTS = {
  relationship_chaos: {
    rounds: [
      {
        scenario:
          'Your partner posts a cryptic quote about trust, ignores your message, and likes a suspicious gym selfie from someone named Blaze. Your best friend is already typing dangerous advice, the group chat smells weakness, and the whole situation is one screenshot away from becoming a family issue.',
        choices: [
          'Reply with "interesting" and let dread do the heavy lifting.',
          'Send a calm paragraph that is secretly a legal threat.',
          'Post your own vague quote and act like it is growth.',
        ],
      },
      {
        scenario:
          'Blaze comments "legend" under the post, your cousin forwards a screenshot with eight question marks, and your partner responds with the emotional warmth of a parking ticket. Everyone wants clarity, which is unfortunate because clarity left this story several bad instincts ago.',
        choices: [
          'Call your partner and open with fake maturity.',
          'Text Blaze directly like a detective with no badge.',
          'Ask the cousin to leak strategic misinformation.',
        ],
      },
      {
        scenario:
          'A mutual friend volunteers to mediate despite loving drama more than nutrition. The conversation is now balancing on a folding chair above a swimming pool of screenshots, and every person involved suddenly thinks they are the reasonable one.',
        choices: [
          'Accept mediation and weaponize politeness.',
          'Send an audio note that sounds calm but feels haunted.',
          'Pretend your phone died and blame fate.',
        ],
      },
      {
        scenario:
          'The quote turns out to be copied from a candle brand, but by now relatives have chosen sides and one aunt is praying in the chat. The truth arrived late, underdressed, and far too weak to fix what ego already set on fire.',
        choices: [
          'Admit you overreacted and pivot into self-awareness.',
          'Claim this was a social experiment on loyalty.',
          'Break the tension with a joke reckless enough to reset society.',
        ],
      },
    ],
    endingTitle: 'Mission Complete: Romance Containment',
    roastLines: [
      'You survived because everyone else got exhausted before you got wise.',
      'Your emotional strategy had the grace of a shopping cart with one violent wheel.',
      'You turned miscommunication into performance art, which is impressive and medically unhelpful.',
    ],
  },
  friendship_meltdown: {
    rounds: [
      {
        scenario:
          'Your group chat renames itself "Core Four" while only three people are typing. A deleted message appears, a suspicious inside joke lands, and the friend who always starts trouble is reacting with hearts like that counts as diplomacy.',
        choices: [
          'Send "did I miss something?" with terrifying restraint.',
          'Post a meme about fake friends and wait for self-reporting.',
          'Open a side chat with the weakest link first.',
        ],
      },
      {
        scenario:
          'One friend claims the rename was accidental, which would be stronger if the new photo did not crop you out like a budget villain origin story. Another says everyone is "just busy," the international anthem of organized nonsense.',
        choices: [
          'Demand a voice call and keep receipts open.',
          'Pretend you do not care while caring professionally.',
          'Recruit an outside friend as an unofficial analyst.',
        ],
      },
      {
        scenario:
          'The analyst reports a surprise hangout is being planned and the surprise appears to be your absence. Meanwhile, one guilty party keeps sending heart reactions, which somehow feels more insulting than honest violence.',
        choices: [
          'Crash the hangout with bakery peace offerings.',
          'Expose the evidence and let silence do cardio.',
          'Turn the whole issue into a fake podcast episode.',
        ],
      },
      {
        scenario:
          'The truth finally spills: the group wanted a calm night without your habit of treating board games like military campaigns. This is both unfair and weirdly specific, and now the chat watches your reply like villagers watching someone reach for a cursed lever.',
        choices: [
          'Apologize for the competitive energy and reclaim the room.',
          'Negotiate friendship terms like a tiny union boss.',
          'Reply with a dramatic "understood" and vanish for one minute.',
        ],
      },
    ],
    endingTitle: 'Mission Complete: Group Chat Diplomacy',
    roastLines: [
      'You saved the friendship, but your reputation now travels with a warning label.',
      'Your communication style remains ninety percent instinct and ten percent accidental theater.',
      'You won an argument nobody should have needed to host in the first place.',
    ],
  },
  daily_absurdity: {
    rounds: [
      {
        scenario:
          'You order one iced coffee before work, but the barista writes "good luck" on the cup and hands you a drink the color of unresolved tax issues. Minutes later your manager wants an urgent meeting and your shoe starts making accordion noises.',
        choices: [
          'Drink the coffee and trust chaos as a lifestyle.',
          'Throw it away and start the day suspicious but hydrated.',
          'Take a photo first in case this becomes evidence.',
        ],
      },
      {
        scenario:
          'The urgent meeting is about a printer jam somehow carrying your name despite your long-standing refusal to bond with office machinery. At the same time your landlord texts "call me" and a stranger compliments your "bold" sock choice.',
        choices: [
          'Fix the printer aggressively and chase a legend arc.',
          'Blame Mercury retrograde with executive certainty.',
          'Handle the landlord first and let office folklore grow.',
        ],
      },
      {
        scenario:
          'The landlord only wanted permission to repaint the hallway, but by now your boss has heard a version of the printer story where you challenged technology to a duel. The suspicious coffee kicks in and your thoughts are moving like they owe rent.',
        choices: [
          'Lean into competence and solve everything too fast.',
          'Take a tactical bathroom break and reset your soul.',
          'Narrate your day like a nature documentary.',
        ],
      },
      {
        scenario:
          'The printer works, the hallway becomes beige, and the sock stranger turns out to be a recruiter who thinks you have "presence." Your aggressively unserious day is somehow turning into opportunity, which feels illegal in a spiritual sense.',
        choices: [
          'Accept the weird compliment and walk out composed.',
          'Ask for details and accidentally create a second subplot.',
          'Go home immediately before destiny notices you again.',
        ],
      },
    ],
    endingTitle: 'Mission Complete: Ordinary Day Survival',
    roastLines: [
      'You made it through the day with the confidence of someone who confuses momentum for planning.',
      'Your crisis management style is basically jazz, and somehow it kept billing correctly.',
      'You treated randomness like a co-worker and now it respects you too much.',
    ],
  },
};
