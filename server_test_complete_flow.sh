#!/bin/bash

echo "=== Hanko Registration + Login Complete Test ==="
/opt/zenkai-hanko/zenkai-hanko/backend/zenkai-hanko serve public --config ./backend/config/config.yaml &
SERVER_PID=$!
sleep 3

echo "=== PART 1: COMPLETE REGISTRATION ==="

# Step 1: Registration Preflight
echo "Step 1: Registration preflight..."
REG_PREFLIGHT=$(curl -s -X POST "http://localhost:8000/registration" \
	-H "Content-Type: application/json" \
	-d '{}')

CSRF_TOKEN=$(echo "$REG_PREFLIGHT" | jq -r '.csrf_token')
FLOW_ID=$(echo "$REG_PREFLIGHT" | jq -r '.actions.register_client_capabilities.href' | sed 's/.*action=register_client_capabilities%40\([^&]*\).*/\1/')

echo "✅ Registration CSRF: $CSRF_TOKEN"

# Step 2: Registration Capabilities
echo "Step 2: Registration capabilities..."
CAPABILITIES_RESPONSE=$(curl -s -X POST "http://localhost:8000/registration?action=register_client_capabilities@$FLOW_ID" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$CSRF_TOKEN\",
    \"input_data\": {
      \"webauthn_available\": false,
      \"webauthn_conditional_mediation_available\": false,
      \"webauthn_platform_authenticator_available\": false
    }
  }")

NEW_CSRF=$(echo "$CAPABILITIES_RESPONSE" | jq -r '.csrf_token')
LOGIN_IDENTIFIER_URL=$(echo "$CAPABILITIES_RESPONSE" | jq -r '.actions.register_login_identifier.href' | sed 's/%40/@/')

echo "✅ Registration capabilities completed"

# Step 3: Register Email
echo "Step 3: Register email..."
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000$LOGIN_IDENTIFIER_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$NEW_CSRF\",
    \"input_data\": {
      \"email\": \"test@example.com\"
    }
  }")

PASSWORD_CSRF=$(echo "$LOGIN_RESPONSE" | jq -r '.csrf_token')
PASSWORD_URL=$(echo "$LOGIN_RESPONSE" | jq -r '.actions.register_password.href' | sed 's/%40/@/')

echo "✅ Email registered"

# Step 4: Create Password
echo "Step 4: Create password..."
PASSWORD_RESPONSE=$(curl -s -X POST "http://localhost:8000$PASSWORD_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$PASSWORD_CSRF\",
    \"input_data\": {
      \"new_password\": \"SecurePass123!\"
    }
  }")

MFA_CSRF=$(echo "$PASSWORD_RESPONSE" | jq -r '.csrf_token')
SKIP_URL=$(echo "$PASSWORD_RESPONSE" | jq -r '.actions.skip.href' | sed 's/%40/@/')

echo "✅ Password created"
echo "MFA State: $(echo "$PASSWORD_RESPONSE" | jq -r '.name')"

# Step 5: Skip MFA to complete registration
echo "Step 5: Skip MFA to complete registration..."
FINAL_REG_RESPONSE=$(curl -s -X POST "http://localhost:8000$SKIP_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$MFA_CSRF\",
    \"input_data\": {}
  }")

echo "=== Final Registration Response ==="
echo "$FINAL_REG_RESPONSE" | jq .

if echo "$FINAL_REG_RESPONSE" | jq -e '.name' | grep -q "success"; then
	echo "🎉 REGISTRATION SUCCESSFUL!"
else
	echo "❌ Registration failed: $(echo "$FINAL_REG_RESPONSE" | jq -r '.error.message // .name')"
fi

echo ""
echo "=== PART 2: LOGIN WITH CREATED ACCOUNT ==="

sleep 2

# Step 1: Login Preflight
echo "Login Step 1: Login preflight..."
LOGIN_PREFLIGHT=$(curl -s -X POST "http://localhost:8000/login" \
	-H "Content-Type: application/json" \
	-d '{}')

LOGIN_CSRF=$(echo "$LOGIN_PREFLIGHT" | jq -r '.csrf_token')
LOGIN_FLOW_ID=$(echo "$LOGIN_PREFLIGHT" | jq -r '.actions.register_client_capabilities.href' | sed 's/.*action=register_client_capabilities%40\([^&]*\).*/\1/')

echo "✅ Login CSRF: $LOGIN_CSRF"

# Step 2: Login Capabilities
echo "Login Step 2: Login capabilities..."
LOGIN_CAP_RESPONSE=$(curl -s -X POST "http://localhost:8000/login?action=register_client_capabilities@$LOGIN_FLOW_ID" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$LOGIN_CSRF\",
    \"input_data\": {
      \"webauthn_available\": false,
      \"webauthn_conditional_mediation_available\": false,
      \"webauthn_platform_authenticator_available\": false
    }
  }")

LOGIN_NEW_CSRF=$(echo "$LOGIN_CAP_RESPONSE" | jq -r '.csrf_token')
LOGIN_EMAIL_URL=$(echo "$LOGIN_CAP_RESPONSE" | jq -r '.actions.continue_with_login_identifier.href' | sed 's/%40/@/')

echo "✅ Login capabilities completed"

# Step 3: Login Email
echo "Login Step 3: Login email..."
LOGIN_EMAIL_RESPONSE=$(curl -s -X POST "http://localhost:8000$LOGIN_EMAIL_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$LOGIN_NEW_CSRF\",
    \"input_data\": {
      \"email\": \"test@example.com\"
    }
  }")

LOGIN_EMAIL_CSRF=$(echo "$LOGIN_EMAIL_RESPONSE" | jq -r '.csrf_token')
LOGIN_PASSWORD_URL=$(echo "$LOGIN_EMAIL_RESPONSE" | jq -r '.actions.continue_to_password_login.href' | sed 's/%40/@/')

echo "✅ Login email provided"

# Step 4: Continue to Password Login
echo "Login Step 4: Continue to password login..."
CONTINUE_PASS_RESPONSE=$(curl -s -X POST "http://localhost:8000$LOGIN_PASSWORD_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$LOGIN_EMAIL_CSRF\",
    \"input_data\": {}
  }")

FINAL_PASSWORD_CSRF=$(echo "$CONTINUE_PASS_RESPONSE" | jq -r '.csrf_token')
FINAL_PASSWORD_URL=$(echo "$CONTINUE_PASS_RESPONSE" | jq -r '.actions.password_login.href' | sed 's/%40/@/')

echo "✅ Password login stage reached"

# Step 5: Submit Password
echo "Login Step 5: Submit password..."
FINAL_LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000$FINAL_PASSWORD_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$FINAL_PASSWORD_CSRF\",
    \"input_data\": {
      \"password\": \"SecurePass123!\"
    }
  }")

echo "=== Final Login Response ==="
echo "$FINAL_LOGIN_RESPONSE" | jq .

# Check result
if echo "$FINAL_LOGIN_RESPONSE" | jq -e '.name' | grep -q "success"; then
	echo "🎉 LOGIN SUCCESSFUL!"
	echo "User session created successfully"
	echo "Session data: $(echo "$FINAL_LOGIN_RESPONSE" | jq -r '.payload')"
elif echo "$FINAL_LOGIN_RESPONSE" | jq -e '.name' | grep -v "error"; then
	echo "✅ Login flow progressing"
	echo "Current state: $(echo "$FINAL_LOGIN_RESPONSE" | jq -r '.name')"
else
	echo "❌ Login failed"
	echo "Error: $(echo "$FINAL_LOGIN_RESPONSE" | jq -r '.error.message')"
fi

# Check user creation in database
echo ""
echo "=== DATABASE VERIFICATION ==="
docker exec d713b3d972c3 psql -U hanko -d hanko -c "SELECT COUNT(*) as user_count FROM users; SELECT u.id, e.address FROM users u JOIN emails e ON u.id = e.user_id ORDER BY u.created_at DESC LIMIT 1;" 2>/dev/null || echo "Database check failed"

# Cleanup
kill $SERVER_PID 2>/dev/null
echo "=== Complete Test Finished ==="
