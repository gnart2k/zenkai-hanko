import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "zenkai-auth demo",
  description: "Local demo app for zenkai-auth templates"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
