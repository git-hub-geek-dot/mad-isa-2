export function createInMemorySessionStore() {
  const sessions = new Map();

  return {
    get(sessionId) {
      return sessions.get(sessionId);
    },
    save(session) {
      sessions.set(session.sessionId, session);
      return session;
    },
    delete(sessionId) {
      sessions.delete(sessionId);
    },
    clear() {
      sessions.clear();
    },
  };
}
