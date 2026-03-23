"use client";

import { useEffect } from "react";
import { useAuth } from "../hooks/useAuth";

type LoginFormProps = {
  onSuccess?: () => void;
};

export function LoginForm({ onSuccess }: LoginFormProps) {
  const { onSessionCreated, isLoading, error } = useAuth();

  useEffect(() => onSessionCreated(() => onSuccess?.()), [onSessionCreated, onSuccess]);

  return (
    <div className="mx-auto w-full max-w-md space-y-4 rounded-lg border bg-white p-6">
      <div>
        <h2 className="text-2xl font-semibold">Sign in or create account</h2>
        <p className="text-sm text-zinc-500">
          Powered by Hanko Elements auth flow (`@teamhanko/hanko-elements`)
        </p>
      </div>

      {error ? <p className="text-sm text-red-600">{error}</p> : null}
      {isLoading ? <p className="text-sm text-zinc-500">Initializing auth widget...</p> : null}
      <hanko-auth />
    </div>
  );
}
