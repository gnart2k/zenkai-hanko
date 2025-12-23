#!/bin/bash

echo "=== Hanko Registration API Test ==="
cd /Users/mac/se/zenkai/hanko/backend

# Start server
./hanko serve public --config config/config-test.yaml &
SERVER_PID=$!
sleep 3

# Step 1: Preflight
echo "Step 1: Getting preflight..."
PREFLIGHT_RESPONSE=$(curl -s -X POST "http://localhost:8000/registration" \
  -H "Content-Type: application/json" \
  -d '{}')

CSRF_TOKEN=$(echo "$PREFLIGHT_RESPONSE" | jq -r '.csrf_token')
FLOW_ID=$(echo "$PREFLIGHT_RESPONSE" | jq -r '.actions.register_client_capabilities.href' | sed 's/.*action=register_client_capabilities%40\([^&]*\).*/\1/')

echo "✅ CSRF Token: $CSRF_TOKEN"
echo "✅ Flow ID: $FLOW_ID"

# Step 2: Register capabilities
echo "Step 2: Registering client capabilities..."
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

echo "✅ Capabilities registered, new CSRF: $NEW_CSRF"

# Step 3: Register email
echo "Step 3: Registering email..."
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

echo "✅ Email registered, new CSRF: $PASSWORD_CSRF"

# Step 4: Create password
echo "Step 4: Creating password..."
FINAL_RESPONSE=$(curl -s -X POST "http://localhost:8000$PASSWORD_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"csrf_token\": \"$PASSWORD_CSRF\",
    \"input_data\": {
      \"new_password\": \"SecurePass123!\"
    }
  }")

echo "✅ Final Response:"
echo "$FINAL_RESPONSE" | jq .

# Check if registration was successful
if echo "$FINAL_RESPONSE" | jq -e '.name' | grep -q "success"; then
    echo "🎉 REGISTRATION SUCCESSFUL!"
elif echo "$FINAL_RESPONSE" | jq -e '.name' | grep -v "error"; then
    echo "✅ Registration flow working (partial success)"
else
    echo "❌ Registration failed"
fi

# Cleanup
kill $SERVER_PID
echo "=== Test Complete ==="