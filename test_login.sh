#!/bin/bash

echo "=== Hanko Login API Test ==="
cd /Users/mac/se/zenkai/hanko/backend

# Start server
./hanko serve public --config config/config-test.yaml &
SERVER_PID=$!
sleep 3

# Test login with the account we created
# Step 1: Login Preflight
echo "Step 1: Login preflight..."
LOGIN_PREFLIGHT=$(curl -s -X POST "http://localhost:8000/login" \
	-H "Content-Type: application/json" \
	-d '{}')

CSRF_TOKEN=$(echo "$LOGIN_PREFLIGHT" | jq -r '.csrf_token')
FLOW_ID=$(echo "$LOGIN_PREFLIGHT" | jq -r '.actions.register_client_capabilities.href' | sed 's/.*action=register_client_capabilities%40\([^&]*\).*/\1/')

echo "✅ CSRF: $CSRF_TOKEN"
echo "✅ Flow ID: $FLOW_ID"

# Step 2: Login Capabilities
echo "Step 2: Login capabilities..."
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
LOGIN_IDENTIFIER_URL=$(echo "$CAPABILITIES_RESPONSE" | jq -r '.actions.continue_with_login_identifier.href' | sed 's/%40/@/')

echo "✅ Capabilities registered, new CSRF: $NEW_CSRF"

# Step 3: Login Identifier
echo "Step 3: Login identifier..."
LOGIN_IDENTIFIER_RESPONSE=$(curl -s -X POST "http://localhost:8000$LOGIN_IDENTIFIER_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$NEW_CSRF\",
    \"input_data\": {
      \"email\": \"test@example.com\"
    }
  }")

PASSWORD_CSRF=$(echo "$LOGIN_IDENTIFIER_RESPONSE" | jq -r '.csrf_token')
PASSWORD_URL=$(echo "$LOGIN_IDENTIFIER_RESPONSE" | jq -r '.actions.password_login.href' | sed 's/%40/@/')

echo "✅ Email provided, new CSRF: $PASSWORD_CSRF"

# Step 4: Password Login
echo "Step 4: Password login..."
FINAL_RESPONSE=$(curl -s -X POST "http://localhost:8000$PASSWORD_URL" \
	-H "Content-Type: application/json" \
	-d "{
    \"csrf_token\": \"$PASSWORD_CSRF\",
    \"input_data\": {
      \"password\": \"SecurePass123!\"
    }
  }")

echo "=== Final Login Response ==="
echo "$FINAL_RESPONSE" | jq .

# Check result
if echo "$FINAL_RESPONSE" | jq -e '.name' | grep -q "success"; then
	echo "🎉 LOGIN SUCCESSFUL!"
	echo "User session created successfully"
elif echo "$FINAL_RESPONSE" | jq -e '.name' | grep -v "error"; then
	echo "✅ Login flow progressing"
	echo "Current state: $(echo "$FINAL_RESPONSE" | jq -r '.name')"
else
	echo "❌ Login failed"
	echo "Error: $(echo "$FINAL_RESPONSE" | jq -r '.error.message')"
fi

# Cleanup
kill $SERVER_PID 2>/dev/null
echo "=== Login Test Complete ==="
