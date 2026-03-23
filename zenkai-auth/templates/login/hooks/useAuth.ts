import { useState } from "react";
import { authClient } from "../lib/auth-client";

type LoginInput = {
  email: string;
  password: string;
};

export function useAuth() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function login(input: LoginInput) {
    setIsLoading(true);
    setError(null);

    try {
      await authClient.login(input);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unable to sign in.";
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }

  return {
    login,
    isLoading,
    error
  };
}
