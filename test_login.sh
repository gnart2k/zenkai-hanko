#!/bin/bash

echo "=== Hanko Login API Test ==="
cd /Users/mac/se/zenkai/hanko/backend

# Start server
./hanko serve public --config config/config-test.yaml &
SERVER_PID=$!
sleep 3

# Test login with the account we created
echo "Step 1: Starting login flow..."
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/login" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "=== Login Preflight Response ==="
echo "$LOGIN_RESPONSE" | jq .

# Extract credentials
CSRF_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.csrf_token')
FLOW_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.actions.password_login.href' | sed 's/.*action=password_login%40\([^&]*\).*/\1/')

echo "CSRF Token: $CSRF_TOKEN"
echo "Flow ID: $FLOW_ID"

if [ "$CSRF_TOKEN" = "null" ] || [ "$CSRF_TOKEN" = "" ]; then
    echo "❌ Failed to get login flow started"
    kill $SERVER_PID
    exit 1
fi

# Step 2: Try password login with the created account
echo "Step 2: Attempting password login..."
PASSWORD_LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/login?action=password_login@$FLOW_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"csrf_token\": \"$CSRF_TOKEN\",
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