# zenkai-auth

`zenkai-auth` is a shadcn-style CLI that copies editable auth UI source files into your app.
It does **not** ship a component library from `node_modules`.

## Features

- Copies real source files into your project (`components`, `hooks`, `lib`)
- Adds ready-to-use Next.js App Router pages (`app/login/page.tsx`, `app/register/page.tsx`)
- Safe merge by default (no overwrite unless `--force`)
- Extensible item system (`login`, `register`, more later)
- Optional remote template source from GitHub
- Placeholder injection for API base URL
- Auth flow compatible with Hanko auth-service endpoints on `http://localhost:8000`

## Project structure

```txt
zenkai-auth/
├─ bin/
│  └─ index.js
├─ src/
│  ├─ cli.js
│  ├─ items.js
│  ├─ installers/
│  │  └─ addItem.js
│  └─ utils/
│     ├─ logger.js
│     └─ templateSource.js
├─ templates/
│  ├─ login/
│  │  ├─ app/login/page.tsx
│  │  ├─ components/login-form.tsx
│  │  ├─ hooks/useAuth.ts
│  │  └─ lib/auth-client.ts
│  └─ register/
│     ├─ app/register/page.tsx
│     ├─ components/register-form.tsx
│     ├─ hooks/useRegister.ts
│     └─ lib/auth-client.ts
└─ package.json
```

## CLI usage

```bash
npx zenkai-auth add login
npx zenkai-auth add register
```

### Options

```bash
# overwrite existing files
npx zenkai-auth add login --force

# preview only
npx zenkai-auth add login --dry-run

# inject API URL into template placeholders
npx zenkai-auth add login --auth-api-url https://api.example.com

# fetch templates from remote GitHub repo
npx zenkai-auth add login --remote your-org/zenkai-auth-templates#main
```

### Logging behavior

The CLI prints clear status logs like:

- `Detected project root: ...`
- `Creating components...`
- `Creating hooks...`
- `Creating lib...`
- `Installing login UI...`
- `Done!`

## Auth-service compatibility

Generated templates use the same backend route pattern used in this repository:

- Authentication UI is implemented with `@teamhanko/hanko-elements`
- The component follows the same flow used in `frontend/examples/*`:
  - `register(hankoApi)` to register web components
  - `<hanko-auth />` as the auth UI
  - `new Hanko(hankoApi)` session event listeners (`onSessionCreated`, `onUserLoggedOut`)

Install required dependency in consuming apps:

```bash
npm install @teamhanko/hanko-elements
```

## Next.js architecture behavior

- If the target project has `next` in dependencies, the CLI also ensures `app/` exists.
- If the target project uses a `src/` directory, files are installed under `src/` (for example `src/app/login/page.tsx`, `src/components/login-form.tsx`).

## Local development

From `zenkai-auth/`:

```bash
npm install
npm link
```

Then from any target app:

```bash
zenkai-auth add login
```

To remove global link:

```bash
npm unlink -g zenkai-auth
```

## Local demo app (pre-publish testing)

You can test templates live inside this package without publishing:

```bash
# once
cd zenkai-auth/demo
npm install

# back to package root
cd ..
npm run demo:sync
npm run demo:dev
```

What this does:

- `demo:sync` runs local CLI commands against `zenkai-auth/demo`:
  - `add login --force`
  - `add register --force`
- Generated files are written into `demo/src/*` and always reflect your latest templates.

Set custom backend URL:

```bash
AUTH_API_URL=http://localhost:8000 npm run demo:sync
```

## Publish to npm

From `zenkai-auth/`:

```bash
npm version patch
npm publish --access public
```

## How to add new templates

1. Create a new template folder in `templates/<name>/`
2. Add your source files (for example `components`, `hooks`, `lib`)
3. Register it in `src/items.js`

That is all; `zenkai-auth add <name>` will work automatically.
