# zenkai-auth

`zenkai-auth` is a shadcn-style CLI that copies editable auth UI source files into your app.
It does **not** ship a component library from `node_modules`.

## Features

- Copies real source files into your project (`components`, `hooks`, `lib`)
- Safe merge by default (no overwrite unless `--force`)
- Extensible item system (`login`, `register`, more later)
- Optional remote template source from GitHub
- Placeholder injection for `AUTH_API_URL`
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
│  │  ├─ components/login-form.tsx
│  │  ├─ hooks/useAuth.ts
│  │  └─ lib/auth-client.ts
│  └─ register/
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

# inject API URL into AUTH_API_URL placeholders
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

- Login: `POST /user` (resolve `user_id` from email) then `POST /password/login`
- Register: `POST /users` then `PUT /password`
- All requests use `credentials: "include"` for session cookies

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
