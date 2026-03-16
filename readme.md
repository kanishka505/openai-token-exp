# OpenAI Token & Reasoning Experiment

POC to verify access to OpenAI reasoning tokens/traces and compare responses between Personal and Organization API tokens.

## Key Finding

**Both Personal and Organization tokens return the same reasoning response structure.** ZDR (Zero Data Retention) enable/disable does not affect whether reasoning appears in the response.

To get reasoning in the API response, pass this in the request:

```json
"reasoning": {
  "effort": "medium",
  "summary": "auto"
}
```

Optionally include `"include": ["reasoning.encrypted_content"]` to receive the encrypted reasoning content.

## Project Structure

```
├── responses_api_request.json   # Request payload (model, input, reasoning config)
├── curl_responses_api.sh       # Runs API calls with both tokens, saves responses
├── response_personal.json      # Response from Personal token
├── response_org.json           # Response from Organization token
├── response_5_4_O.json         # Sample Organization response (historical)
├── response_5_4_P.json         # Sample Personal response (historical)
├── .env                        # API keys (OPENAI_API_KEY_PERSONAL, OPENAI_API_KEY_ORG)
└── requirements.txt
```

## Setup

1. Create `.env` with your API keys:
   ```
   OPENAI_API_KEY_PERSONAL=sk-proj-...
   OPENAI_API_KEY_ORG=sk-proj-...
   ```

2. Ensure `responses_api_request.json` exists with the reasoning config.

## Running the Experiment

```bash
bash curl_responses_api.sh
```

This calls the OpenAI Responses API twice (Personal token, then Organization token) and saves each response to `response_personal.json` and `response_org.json`.

## Response Structure

Both token types return identical structure. The `output` array contains alternating items:

### Reasoning Block

```json
{
  "id": "rs_...",
  "type": "reasoning",
  "encrypted_content": "gAAAAAB...",
  "summary": [
    {
      "type": "summary_text",
      "text": "**Exploring shell interaction**\n\nI'm considering how to..."
    }
  ]
}
```

- **encrypted_content**: Full reasoning (Fernet-encrypted, not readable)
- **summary**: Optional array of human-readable summaries. Some blocks have `summary: []`, others have one or more `summary_text` entries.

### Message Block

```json
{
  "id": "msg_...",
  "type": "message",
  "status": "completed",
  "content": [...],
  "phase": "commentary" | "final_answer",
  "role": "assistant"
}
```

### Top-Level Reasoning Config (in response)

```json
"reasoning": {
  "effort": "medium",
  "summary": "detailed"
}
```

(Response may show `"detailed"` even when request used `"auto"`.)

## Personal vs Organization Comparison

| Aspect | Personal | Organization |
|--------|----------|--------------|
| **billing.payer** | `"openai"` | `"developer"` |
| **store** | `true` | `false` |
| **Reasoning structure** | Same | Same |
| **Output format** | Same | Same |

Token usage can vary per run (Personal sometimes produces longer/shorter responses). Both return the same reasoning schema: `type`, `encrypted_content`, `summary`.

## Chat Completions API vs Responses API — Reasoning Support

### Key Finding

**The Chat Completions API does NOT return reasoning summaries or encrypted content.** Only the Responses API exposes the full reasoning trace. Chat Completions only provides the `reasoning_tokens` count in usage details.

### What Chat Completions gives you

- `reasoning_effort` parameter in the request (`low`, `medium`, `high`, `minimal`, `none` depending on model)
- `reasoning_tokens` count in `usage.completion_tokens_details.reasoning_tokens`

### What Chat Completions does NOT give you

- No reasoning **summary** text
- No `encrypted_content`
- No reasoning text/content in the response body — reasoning is hidden
- Reasoning is **discarded after every request** (stateless, no carry-over between turns)

### Chat Completions Response Structure (reasoning model)

```json
{
  "choices": [{
    "message": {
      "content": "...",
      "role": "assistant"
    }
  }],
  "usage": {
    "completion_tokens": 2919,
    "prompt_tokens": 29,
    "completion_tokens_details": {
      "reasoning_tokens": 1792
    }
  }
}
```

Note: reasoning tokens are billed but their content is not exposed.

### Responses API Response Structure (for comparison)

```json
{
  "output": [
    {
      "type": "reasoning",
      "encrypted_content": "gAAAAAB...",
      "summary": [{"type": "summary_text", "text": "..."}]
    },
    {
      "type": "message",
      "content": [...]
    }
  ]
}
```

### Comparison Table

| Feature | Chat Completions API | Responses API |
|---|---|---|
| `reasoning_effort` | Yes | Yes |
| `reasoning_tokens` count | Yes | Yes |
| Reasoning **summary** text | **No** | Yes |
| `encrypted_content` | **No** | Yes |
| Reasoning persisted across turns | **No** (stateless) | Yes (with `store: true`) |
| Recommended by OpenAI | Legacy | Preferred |

### Sources

- [Reasoning models | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
- [encrypted_content support for Chat Completions API? - OpenAI Community](https://community.openai.com/t/reasoning-encrypted-content-support-for-chat-completions-api/1287547)
- [Azure OpenAI reasoning models - Microsoft Learn](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/reasoning)

## Background

An OpenAI account exec indicated ZDR prevents receiving reasoning tokens. This experiment confirms that **reasoning tokens are returned regardless of token type** when the `reasoning` config is passed. The main difference is billing attribution (`openai` vs `developer`) and `store` value.
