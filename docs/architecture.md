# Hanko (zenkai-hanko) architecture

This document describes **system** (deployment / runtime topology) and **software** (in-process structure of the Go backend) architecture for this repository. Diagrams use [Mermaid](https://mermaid.js.org/).

---

## System architecture

Typical **local full stack** matches [deploy/docker-compose/quickstart.yaml](../deploy/docker-compose/quickstart.yaml): Postgres, Hanko API (public + admin), static Elements bundle, demo Quickstart app, and an SMTP capture tool for passcodes.

```mermaid
flowchart TB
  subgraph users [Users]
    Browser[Browser]
  end

  subgraph quickstart_stack [Docker_Compose_quickstart]
    Quickstart[quickstart_Go_demo_app:8888]
    Elements[elements_nginx_static:9500]
    Hanko[Hanko_backend:8000_public_8001_admin]
    Migrate[hanko_migrate_one_shot]
    Postgres[(postgresd_Postgres)]
    MailSlurper[mailslurper_SMTP_UI]
  end

  subgraph external [External_on_internet]
    OAuth[OAuth_OIDC_providers]
    UserSMTP[Production_SMTP_optional]
  end

  Browser -->|HTTP| Quickstart
  Browser -->|loads| Elements
  Browser -->|Flow_API_JWT_cookies| Hanko

  Quickstart -->|HANKO_URL_API| Hanko
  Quickstart -->|script_tags| Elements

  Migrate -->|migrate_up| Postgres
  Hanko -->|SQL| Postgres
  Hanko -->|SMTP_passcodes| MailSlurper
  Hanko -.->|when_configured| OAuth
  Hanko -.->|production_config| UserSMTP
```

**Notes**

- **Public API** (default `:8000`) serves registration/login/profile flows, WebAuthn, sessions, well-known JWKS, etc.
- **Admin API** (default `:8001`) serves operator endpoints; it should sit behind access control in production (see [backend/README.md](../backend/README.md)).
- **Quickstart** is a reference app; real integrations use your own frontend with [Hanko Elements](../frontend/elements) and/or the [Frontend SDK](../frontend/frontend-sdk).

---

## Software architecture (Hanko backend)

The backend is a **Go** service using **Cobra** for CLI commands, **Echo** for HTTP, and a **persistence** layer over **PostgreSQL or MySQL**. Two Echo instances are started when running `serve all` ([backend/cmd/serve/all.go](../backend/cmd/serve/all.go), [backend/server/server.go](../backend/server/server.go)).

```mermaid
flowchart TB
  subgraph cli [CLI_entry]
    Main[main.go]
    Cmd[cmd_Execute_Cobra]
    ServeAll[serve_all]
    ServePublic[serve_public]
    ServeAdmin[serve_admin]
    MigrateCmd[migrate_user_import_etc]
  end

  subgraph config [Configuration]
    Cfg[config_Load_YAML_env]
  end

  subgraph servers [HTTP_Echo_servers]
    PublicEcho[PublicRouter_echo]
    AdminEcho[AdminRouter_echo]
  end

  subgraph public_handlers [Public_API_handlers]
    FlowHandler[flow_api_FlowPilotHandler]
    FlowPilot[flowpilot_flow_engine]
    UserH[UserHandler]
    WebauthnH[WebauthnHandler]
    PasscodeH[PasscodeHandler]
    PasswordH[PasswordHandler]
    ThirdH[ThirdPartyHandler]
    WellKnown[WellKnown_JWKS_config]
    Health[Health_alive_ready]
    SamlRoutes[SAML_routes_if_enabled]
  end

  subgraph admin_handlers [Admin_API_handlers]
    UserAdmin[UserAdmin_handlers]
    EmailAdmin[EmailAdmin_handlers]
    SessionAdmin[SessionAdmin_handlers]
  end

  subgraph crosscut [Cross_cutting]
    SessionMgr[session_Manager_JWT_cookies]
    JwkMgr[crypto_jwk_Manager]
    Mailer[mail_SMTP]
    Audit[audit_log]
    Webhooks[webhooks_middleware]
    RateLimit[rate_limiter]
    Middleware[echo_middleware_CORS_logger_metrics]
  end

  subgraph data [Data_access]
    Persister[persistence_Persister]
    DB[(PostgreSQL_or_MySQL)]
  end

  Main --> Cmd
  Cmd --> ServeAll
  Cmd --> MigrateCmd
  ServeAll --> Cfg
  ServeAll --> Persister
  ServeAll --> PublicEcho
  ServeAll --> AdminEcho

  PublicEcho --> Middleware
  PublicEcho --> FlowHandler
  FlowHandler --> FlowPilot
  FlowHandler --> SessionMgr
  FlowHandler --> Persister
  PublicEcho --> UserH
  PublicEcho --> WebauthnH
  PublicEcho --> PasscodeH
  PublicEcho --> PasswordH
  PublicEcho --> ThirdH
  PublicEcho --> WellKnown
  PublicEcho --> Health
  PublicEcho --> SamlRoutes

  AdminEcho --> Middleware
  AdminEcho --> UserAdmin
  AdminEcho --> EmailAdmin
  AdminEcho --> SessionAdmin
  AdminEcho --> Health

  SessionMgr --> JwkMgr
  JwkMgr --> Persister
  UserH --> SessionMgr
  WebauthnH --> Persister
  Mailer --> FlowHandler
  Audit --> Persister
  Webhooks --> Persister

  Persister --> DB
```

**Notes**

- **Flow API** (`POST /registration`, `/login`, `/profile`, ...) is driven by **flowpilot** state machines and returns structured flow states for clients ([backend/handler/public_router.go](../backend/handler/public_router.go)).
- **Legacy-style REST** routes (WebAuthn, emails, users, third-party OAuth callbacks, etc.) coexist on the public router as configured in YAML.
- **Webhooks** can fire on selected lifecycle events; signing uses the same JWK machinery as session tokens where applicable.

---

## Repository map (related components)

```mermaid
flowchart LR
  subgraph repo [zenkai_hanko_repo]
    Backend[backend_Go_Hanko_API]
    Frontend[frontend_Elements_SDK]
    Quickstart[quickstart_demo_app]
    Deploy[deploy_docker_k8s]
    E2E[e2e_Playwright]
  end

  Quickstart --> Backend
  Quickstart --> Frontend
  Deploy --> Backend
  Deploy --> Frontend
  Deploy --> Quickstart
  E2E -.-> Backend
  E2E -.-> Frontend
```

For HTTP details and integration guides, see the official **[docs.hanko.io](https://docs.hanko.io)** API reference (source: [teamhanko/docs](https://github.com/teamhanko/docs)).

