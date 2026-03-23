import Link from "next/link";

export default function HomePage() {
  return (
    <main
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px"
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "680px",
          background: "white",
          border: "1px solid #e5e7eb",
          borderRadius: "12px",
          padding: "24px",
          display: "grid",
          gap: "16px"
        }}
      >
        <h1 style={{ margin: 0, fontSize: "28px" }}>zenkai-auth local demo</h1>
        <p style={{ margin: 0, color: "#6b7280" }}>
          Use this page to validate generated templates before publishing.
        </p>
        <div style={{ display: "flex", gap: "12px", flexWrap: "wrap" }}>
          <Link href="/login" style={{ padding: "10px 14px", borderRadius: "8px", border: "1px solid #d1d5db" }}>
            Go to Login
          </Link>
          <Link href="/register" style={{ padding: "10px 14px", borderRadius: "8px", border: "1px solid #d1d5db" }}>
            Go to Register
          </Link>
        </div>
      </div>
    </main>
  );
}
