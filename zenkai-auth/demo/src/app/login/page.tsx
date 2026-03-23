import Link from "next/link";
import { LoginForm } from "../../components/login-form";

export default function LoginPage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-3xl flex-col items-center justify-center gap-6 px-4 py-10">
      <LoginForm />
      <p className="text-sm text-zinc-500">
        No account yet?{" "}
        <Link href="/register" className="font-medium text-zinc-900 underline underline-offset-4">
          Create one
        </Link>
      </p>
    </main>
  );
}
