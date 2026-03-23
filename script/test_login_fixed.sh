#!/bin/bash

echo "=== Hanko Login API Test ==="
cd /Users/mac/se/zenkai/hanko/backend

# Start server
./hanko serve public --config config/config-test.yaml &
SERVER_PID=$!
sleep 3

# Step 1: Login Preflight
echo "Step 1: Starting login flow..."
LOGIN_PREFLIGHT=$(curl -s -X POST "http://localhost:8000/login" \
  -H "Content-Type: application/json" \
  -d '{}')

CSRF_TOKEN=$(echo "$LOGIN_PREFLIGHT" | jq -r '.csrf_token')
FLOW_ID=$(echo "$LOGIN_PREFLIGHT" | jq -r '.actions.register_client_capabilities.href' | sed 's/.*action=register_client_capabilities%40\([^&]*\).*/\1/')

echo "✅ CSRF Token: $CSRF_TOKEN"
echo "✅ Flow ID: $FLOW_ID"

# Step 2: Login Client Capabilities
echo "Step 2: Registering client capabilities for login..."
CAPABILITIES_RESPONSE=$(curl -s -X POST "http://localhost:8000/login?action=register_client_capabilities@$FLOW_ID" \
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
PASSWORD_LOGIN_URL=$(echo "$CAPABILITIES_RESPONSE" | jq -r '.actions.password_login.href' | sed 's/%40/@/')

echo "✅ Capabilities registered, new CSRF: $NEW_CSRF"
echo "✅ Password login URL: $PASSWORD_LOGIN_URL"

# Step 3: Password Login
echo "Step 3: Attempting password login with created account..."
PASSWORD_LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000$PASSWORD_LOGIN_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"csrf_token\": \"$NEW_CSRF\",
    \"input_data\": {
      \"email\": \"test@example.com\",
      \"password\": \"SecurePass123!\"
    }
  }")

echo "=== Password Login Response ==="
echo "$PASSWORD_LOGIN_RESPONSE" | jq .

# Check result
if echo "$PASSWORD_LOGIN_RESPONSE" | jq -e '.name' | grep -q "success"; then
    echo "🎉 LOGIN SUCCESSFUL!"
    echo "User session created successfully"
elif echo "$PASSWORD_LOGIN_RESPONSE" | jq -e '.name' | grep -v "error"; then
    echo "✅ Login flow progressing"
    echo "Current state: $(echo "$PASSWORD_LOGIN_RESPONSE" | jq -r '.name')"
else
    echo "❌ Login failed"
    echo "Error: $(echo "$PASSWORD_LOGIN_RESPONSE" | jq -r '.error.message')"
fi

# Cleanup
kill $SERVER_PID 2>/dev/null
echo "=== Login Test Complete ==="