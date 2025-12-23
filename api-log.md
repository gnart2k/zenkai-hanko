# Hanko API Testing - Registration Flow

## Environment
- Hanko Server: http://localhost:8000
- Database: PostgreSQL on port 5433
- Configuration: config/config.yaml

## Test 1: Initial Registration Request
**Request:**
```bash
curl -i -X POST http://localhost:8000/registration \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json
Vary: Origin
X-Request-Id: PRxgqVQdglWNTBRRNqCdWbSUOynLpNZq
Date: Sat, 20 Dec 2025 16:27:53 GMT
Content-Length: 703

{"name":"preflight","status":200,"payload":{},"csrf_token":"stKmg8KsvPoBjb4GzrzEEjMAssTCREVm","actions":{"register_client_capabilities":{"href":"/registration?action=register_client_capabilities%40a3440940-7baa-4f22-bce7-db23175c2755","inputs":{"webauthn_available":{"name":"webauthn_available","type":"boolean","required":true,"hidden":true},"webauthn_conditional_mediation_available":{"name":"webauthn_conditional_mediation_available","type":"boolean","hidden":true},"webauthn_platform_authenticator_available":{"name":"webauthn_platform_authenticator_available","type":"boolean","hidden":true}},"action":"register_client_capabilities","description":"Send computers capabilities."}},"links":null}
```

**Status:** ✅ SUCCESS - Preflight completed, received CSRF token

---

## Test 2: Client Capabilities Registration
**Request:**
```bash
curl -i -X POST "http://localhost:8000/registration?action=register_client_capabilities" \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: stKmg8KsvPoBjb4GzrzEEjMAssTCREVm" \
  -d '{}'
```

**Response:**
```http
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
Vary: Origin
X-Request-Id: qiFMLWRDXSlGxRRlMPlPkyjUTqdzvsjV
Date: Sat, 20 Dec 2025 16:27:58 GMT
Content-Length: 141

{"name":"error","status":500,"csrf_token":"","actions":{},"error":{"code":"technical_error","message":"Something went wrong."},"links":null}
```

**Status:** ❌ FAILED - Internal Server Error

---

## Test 3: Simple Registration (Email + Password)
**Request:**
```bash
curl -i -X POST http://localhost:8000/registration \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json
Vary: Origin
X-Request-Id: EOFPomGdLUEwzyEuVHPRhBkUXQSVkkkm
Date: Sat, 20 Dec 2025 16:28:01 GMT
Content-Length: 703

{"name":"preflight","status":200,"payload":{},"csrf_token":"yksBUYiyVNEAyaphqfnscu8x0WIDs0th","actions":{"register_client_capabilities":{"href":"/registration?action=register_client_capabilities%4055bf372b-730b-4898-89f6-eb2df71209aa","inputs":{"webauthn_available":{"name":"webauthn_available","type":"boolean","required":true,"hidden":true},"webauthn_conditional_mediation_available":{"name":"webauthn_conditional_mediation_available","type":"boolean","hidden":true},"webauthn_platform_authenticator_available":{"name":"webauthn_platform_authenticator_available","type":"boolean","hidden":true}},"action":"register_client_capabilities","description":"Send computers capabilities."}},"links":null}
```

**Status:** ✅ SUCCESS - Preflight completed, received new CSRF token

---

## Test 4: Create Password Credential
**Request:**
```bash
curl -i -X POST "http://localhost:8000/registration?action=create_password_credential" \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: yksBUYiyVNEAyaphqfnscu8x0WIDs0th" \
  -d '{
    "password": "SecurePass123!"
  }'
```

**Response:**
```http
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
Vary: Origin
X-Request-Id: HaomOVUHaiATKJYvpPdPEXvEFrEanxGq
Date: Sat, 20 Dec 2025 16:28:14 GMT
Content-Length: 141

{"name":"error","status":500,"csrf_token":"","actions":{},"error":{"code":"technical_error","message":"Something went wrong."},"links":null}
```

**Status:** ❌ FAILED - Internal Server Error

---

## Test 5: Create User
**Request:**
```bash
curl -i -X POST "http://localhost:8000/registration?action=create_user" \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: yksBUYiyVNEAyaphqfnscu8x0WIDs0th" \
  -d '{
    "email": "test@example.com"
  }'
```

**Response:**
```http
HTTP/1.1 500 Internal Server Error
Content-Type: application/json
Vary: Origin
X-Request-Id: aqGqaLxyLtETBTpEkWNUpewZyaJBJfTV
Date: Sat, 20 Dec 2025 16:28:19 GMT
Content-Length: 141

{"name":"error","status":500,"csrf_token":"","actions":null,"error":{"code":"technical_error","message":"Something went wrong."},"links":null}
```

**Status:** ❌ FAILED - Internal Server Error

---

## Summary

### Working:
- ✅ Server is running on localhost:8000
- ✅ Health endpoints respond (JWKS endpoint working)
- ✅ Initial registration preflight requests succeed
- ✅ CSRF token generation works

### Issues:
- ❌ All credential creation and user creation actions result in 500 Internal Server Error
- ❌ Likely missing email delivery configuration (SMTP server on localhost:2500)
- ❌ Server logs needed for detailed error analysis

### Next Steps:
1. Configure SMTP server or disable email verification
2. Check server logs for detailed error messages
3. Try registration with email verification disabled
4. Test complete registration flow with proper email delivery setup
