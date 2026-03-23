import { useState } from "react";
import { authClient } from "../lib/auth-client";

type RegisterInput = {
  name: string;
  email: string;
  password: string;
};

export function useRegister() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function register(input: RegisterInput) {
    setIsLoading(true);
    setError(null);

    try {
      await authClient.register(input);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unable to register.";
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }

  return {
    register,
    isLoading,
    error
  };
}
