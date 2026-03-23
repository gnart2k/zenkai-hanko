import Link from "next/link";
import { RegisterForm } from "../../components/register-form";

export default function RegisterPage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-3xl flex-col items-center justify-center gap-6 px-4 py-10">
      <RegisterForm />
      <p className="text-sm text-zinc-500">
        Already registered?{" "}
        <Link href="/login" className="font-medium text-zinc-900 underline underline-offset-4">
          Sign in
        </Link>
      </p>
    </main>
  );
}
