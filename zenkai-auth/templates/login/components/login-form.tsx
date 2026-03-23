"use client";

import { FormEvent, useState } from "react";
import { useAuth } from "../hooks/useAuth";

type LoginFormProps = {
  onSuccess?: () => void;
};

export function LoginForm({ onSuccess }: LoginFormProps) {
  const { login, isLoading, error } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await login({ email, password });
    onSuccess?.();
  }

  return (
    <form onSubmit={onSubmit} className="mx-auto w-full max-w-md space-y-4 rounded-lg border p-6">
      <div>
        <h2 className="text-2xl font-semibold">Sign in</h2>
        <p className="text-sm text-zinc-500">Connect to auth-service at localhost:8000</p>
      </div>

      <label className="block space-y-1">
        <span className="text-sm">Email</span>
        <input
          type="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          className="w-full rounded-md border px-3 py-2"
          placeholder="jane@example.com"
          required
        />
      </label>

      <label className="block space-y-1">
        <span className="text-sm">Password</span>
        <input
          type="password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          className="w-full rounded-md border px-3 py-2"
          placeholder="********"
          required
        />
      </label>

      {error ? <p className="text-sm text-red-600">{error}</p> : null}

      <button
        type="submit"
        className="w-full rounded-md bg-black px-3 py-2 text-white disabled:opacity-70"
        disabled={isLoading}
      >
        {isLoading ? "Signing in..." : "Sign in"}
      </button>
    </form>
  );
}
