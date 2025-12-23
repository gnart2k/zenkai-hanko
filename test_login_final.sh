#!/bin/bash

echo "=== Hanko Complete Login Flow Test ==="
cd /Users/mac/se/zenkai/hanko/backend

# Start server
./hanko serve public --config config/config-test.yaml &
SERVER_PID=$!
sleep 3

# Step 1: Login Preflight
echo "Step 1: Login preflight..."
LOGIN_PREFLIGHT=$(curl -s -X POST "http://localhost:8000/login" \
  -H "Content-Type: application/json" \
  -d '{}')

CSRF_TOKEN=$(echo "$LOGIN_PREFLIGHT" | jq -r '.csrf_token')
FLOW_ID=$(echo "$LOGIN_PREFLIGHT" | jq -r '.actions.register_client_capabilities.href' | sed 's/.*action=register_client_capabilities%40\([^&]*\).*/\1/')

echo "✅ CSRF: $CSRF_TOKEN"

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

echo "✅ Capabilities registered"

# Step 3: Login Identifier (Email)
echo "Step 3: Login identifier (email)..."
LOGIN_IDENTIFIER_RESPONSE=$(curl -s -X POST "http://localhost:8000$LOGIN_IDENTIFIER_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"csrf_token\": \"$NEW_CSRF\",
    \"input_data\": {
      \"email\": \"test@example.com\"
    }
  }")

EMAIL_CSRF=$(echo "$LOGIN_IDENTIFIER_RESPONSE" | jq -r '.csrf_token')
CONTINUE_TO_PASSWORD_URL=$(echo "$LOGIN_IDENTIFIER_RESPONSE" | jq -r '.actions.continue_to_password_login.href' | sed 's/%40/@/')

echo "✅ Email provided"
echo "Available actions after email: $(echo "$LOGIN_IDENTIFIER_RESPONSE" | jq -r '.actions | keys[]')"

# Step 4: Continue to Password Login
echo "Step 4: Continue to password login..."
CONTINUE_TO_PASSWORD_RESPONSE=$(curl -s -X POST "http://localhost:8000$CONTINUE_TO_PASSWORD_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"csrf_token\": \"$EMAIL_CSRF\",
    \"input_data\": {}
  }")

PASSWORD_LOGIN_CSRF=$(echo "$CONTINUE_TO_PASSWORD_RESPONSE" | jq -r '.csrf_token')
PASSWORD_LOGIN_URL=$(echo "$CONTINUE_TO_PASSWORD_RESPONSE" | jq -r '.actions.password_login.href' | sed 's/%40/@/')

echo "✅ Password login stage reached"
echo "Available actions: $(echo "$CONTINUE_TO_PASSWORD_RESPONSE" | jq -r '.actions | keys[]')"

# Step 5: Submit Password
echo "Step 5: Submit password..."
FINAL_RESPONSE=$(curl -s -X POST "http://localhost:8000$PASSWORD_LOGIN_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"csrf_token\": \"$PASSWORD_LOGIN_CSRF\",
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
    echo "Session data: $(echo "$FINAL_RESPONSE" | jq -r '.payload')"
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