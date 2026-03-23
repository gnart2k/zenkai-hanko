const path = require("path");
const fs = require("fs-extra");
const { spawnSync } = require("child_process");

function runCli(args, cwd) {
  const result = spawnSync(process.execPath, args, {
    cwd,
    stdio: "inherit",
    env: process.env
  });

  if (result.status !== 0) {
    throw new Error(`Command failed: node ${args.join(" ")}`);
  }
}

async function main() {
  const root = path.resolve(__dirname, "..");
  const demoRoot = path.join(root, "demo");
  const cliPath = path.join(root, "bin", "index.js");
  const authApiUrl = process.env.AUTH_API_URL || "http://localhost:8000";

  if (!(await fs.pathExists(path.join(demoRoot, "package.json")))) {
    throw new Error("Demo project not found. Expected demo/package.json.");
  }

  await fs.ensureDir(path.join(demoRoot, "src"));

  runCli([cliPath, "add", "login", "--force", "--auth-api-url", authApiUrl], demoRoot);
  runCli([cliPath, "add", "register", "--force", "--auth-api-url", authApiUrl], demoRoot);

  console.log(`Demo synced with AUTH_API_URL=${authApiUrl}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
