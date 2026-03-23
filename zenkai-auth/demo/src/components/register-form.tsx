"use client";

import { useEffect } from "react";
import { useRegister } from "../hooks/useRegister";

type RegisterFormProps = {
  onSuccess?: () => void;
};

export function RegisterForm({ onSuccess }: RegisterFormProps) {
  const { onSessionCreated, isLoading, error } = useRegister();

  useEffect(() => onSessionCreated(() => onSuccess?.()), [onSessionCreated, onSuccess]);

  return (
    <div className="mx-auto w-full max-w-md space-y-4 rounded-2xl border bg-white p-6">
      <div>
        <h2 className="text-2xl font-semibold">Create account or sign in</h2>
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
