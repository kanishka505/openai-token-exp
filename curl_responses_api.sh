#!/bin/bash
# Curl request for OpenAI Responses API
# Calls with both Personal and Organization tokens, saves responses to JSON files
# Includes: reasoning summary (via reasoning.summary: "auto") + reasoning.encrypted_content (via include)

set -e
source .env 2>/dev/null || true
: "${OPENAI_API_KEY_PERSONAL:?Set OPENAI_API_KEY_PERSONAL in .env or environment}"
: "${OPENAI_API_KEY_ORG:?Set OPENAI_API_KEY_ORG in .env or environment}"

echo "=== Calling with Personal token ==="
curl -sS -X POST "https://api.openai.com/v1/responses" \
  -H "Authorization: Bearer $OPENAI_API_KEY_PERSONAL" \
  -H "Content-Type: application/json" \
  -d @responses_api_request.json -o response_personal_1.json
echo "Saved to response_personal.json"

echo ""
echo "=== Calling with Organization token ==="
curl -sS -X POST "https://api.openai.com/v1/responses" \
  -H "Authorization: Bearer $OPENAI_API_KEY_ORG" \
  -H "Content-Type: application/json" \
  -d @responses_api_request.json -o response_org_1.json
echo "Saved to response_org.json"

echo ""
echo "Done. Responses saved to response_personal.json and response_org.json"
