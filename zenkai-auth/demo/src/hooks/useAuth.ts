import { useEffect, useState } from "react";
import { authClient } from "../lib/auth-client";

export function useAuth() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setIsLoading(true);
    authClient
      .initialize()
      .catch((err) => {
        const message = err instanceof Error ? err.message : "Unable to initialize auth.";
        setError(message);
      })
      .finally(() => {
        setIsLoading(false);
      });
  }, []);

  function onSessionCreated(callback: () => void): () => void {
    return authClient.onSessionCreated(callback);
  }

  function onUserLoggedOut(callback: () => void): () => void {
    return authClient.onUserLoggedOut(callback);
  }

  async function logout() {
    try {
      await authClient.logout();
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unable to logout.";
      setError(message);
      throw err;
    }
  }

  return {
    onSessionCreated,
    onUserLoggedOut,
    logout,
    isLoading,
    error
  };
}
