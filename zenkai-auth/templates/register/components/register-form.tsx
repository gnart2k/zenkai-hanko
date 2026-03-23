"use client";

import { FormEvent, useState } from "react";
import { useRegister } from "../hooks/useRegister";

type RegisterFormProps = {
  onSuccess?: () => void;
};

export function RegisterForm({ onSuccess }: RegisterFormProps) {
  const { register, isLoading, error } = useRegister();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await register({ name, email, password });
    onSuccess?.();
  }

  return (
    <form onSubmit={onSubmit} className="mx-auto w-full max-w-md space-y-4 rounded-2xl border p-6">
      <div>
        <h2 className="text-2xl font-semibold">Create account</h2>
        <p className="text-sm text-zinc-500">Register against auth-service at localhost:8000</p>
      </div>

      <label className="block space-y-1">
        <span className="text-sm">Name</span>
        <input
          type="text"
          value={name}
          onChange={(event) => setName(event.target.value)}
          className="w-full rounded-md border px-3 py-2"
          placeholder="Jane Doe"
          required
        />
      </label>

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
        {isLoading ? "Creating..." : "Create account"}
      </button>
    </form>
  );
}
