import { Hanko, register } from "@teamhanko/hanko-elements";

const AUTH_API_URL = "__AUTH_API_URL__";

let client: Hanko | null = null;

function getClient(): Hanko {
  if (!client) {
    client = new Hanko(AUTH_API_URL);
  }
  return client;
}

async function initialize(): Promise<void> {
  await register(AUTH_API_URL);
}

function onSessionCreated(callback: () => void): () => void {
  const instance = getClient();
  return instance.onSessionCreated(callback);
}

function onUserLoggedOut(callback: () => void): () => void {
  const instance = getClient();
  return instance.onUserLoggedOut(callback);
}

async function logout(): Promise<void> {
  const instance = getClient();
  await instance.logout();
}

export const authClient = {
  initialize,
  onSessionCreated,
  onUserLoggedOut,
  logout
};
