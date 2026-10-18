# HandTech frontend/backend integration handoff

This document describes the current Flutter frontend contract and the work
needed to connect it to the HandTech backend and sign-language AI. It is
intended to be shared with the backend maintainer or pasted into Claude along
with the backend repository.

## Current frontend behavior

- Google Sign-In works on Android and Web. The frontend does not currently send
  a Google ID token to any backend endpoint.
- Translation on Android and iOS uses on-device Google ML Kit. The frontend
  only uses the remote translation endpoint on platforms without that plugin
  (currently Web and desktop). Do not assume that changing the remote endpoint
  will switch Android/iOS away from ML Kit.
- Guest translations are not saved. A signed-in user's translation history is
  stored locally on that device, keyed by Google account email, with a maximum
  of 100 entries. The history is not synchronized to the backend.
- The camera currently displays a local preview. It does not capture or upload
  frames, and no sign-language recognition model or API is wired in.
- Camera audio capture is disabled.

## Existing translation API contract

The Flutter service is `lib/services/google_translation_service.dart`.

Configure the full HTTPS endpoint in the Flutter build using the public
`TRANSLATION_API_URL` Dart define, for example:

```powershell
flutter build web --release "--dart-define=TRANSLATION_API_URL=https://api.example.com/translate"
```

The client sends a JSON POST request:

```http
POST /translate
Content-Type: application/json
```

```json
{
  "q": "Bonjour",
  "source": "fr",
  "target": "en",
  "format": "text"
}
```

The successful response must be JSON with a non-empty `translatedText` string:

```json
{
  "translatedText": "Hello"
}
```

The currently implemented backend is under `backend/translation_api`:

- `GET /health` returns `{"status":"ok"}`.
- `POST /translate` accepts `q`, `source`, and `target`; it forwards
  `format: "text"` to LibreTranslate and returns `translatedText`.
- Supported language codes are `de`, `en`, `es`, `fr`, `it`, and `pt`.
- Text is limited to 5,000 characters; the Flutter request timeout is 30
  seconds.
- The Web client sends no authentication header. CORS allows `POST` and
  `OPTIONS`, and currently allows only the `Content-Type` request header.
- Errors use a non-2xx HTTP status and a JSON `error` message. The Flutter
  client displays the HTTP status but does not parse the backend error body.

Do not change this contract without coordinating a matching frontend change.
If bearer authentication is introduced, update the backend CORS allow-list to
include `Authorization` and coordinate token handling with the frontend.

## Nolan assistant chat integration

The Flutter chat is connected to `https://nolan-a89w.onrender.com/api/chat`
through `lib/services/nolan_chat_service.dart`. Chat is available to guests and
signed-in users; the client sends no authentication header:

```http
POST /api/chat
Content-Type: application/json
```

```json
{
  "message": "How can I make this service more accessible?",
  "history": [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi! How can I help?"}
  ]
}
```

The request message and each history message are limited to 4,000 characters;
history contains at most 20 messages. The client expects a successful JSON
response with a non-empty `reply` string:

```json
{"reply": "Here are some ways to improve accessibility..."}
```

The API's OpenAPI document defines the request fields and limits; the success
response is documented as a JSON object containing a non-empty `reply` string.
Since the API is unauthenticated, its owner should apply server-side abuse
protections such as rate limiting as appropriate. The Flutter Web request only
requires CORS access for `POST` and the `Content-Type` header.

## Proposed sign-language AI integration

There is no existing recognition endpoint or client contract. Before
implementing the route, agree on:

1. Input modality and size: a captured still image, a short video, or a stream
   of frames. The current preview alone is not sent to the server.
2. Request encoding, accepted MIME types, maximum payload, frame rate, and
   processing timeout.
3. Response schema, for example recognized phrase, confidence, language, and
   request/recognition ID. Define how “no sign detected” differs from an error.
4. Whether recognition is allowed for guests and whether any data is retained.
   The current frontend does not persist recognition history.
5. Authentication and rate limits, plus behavior when the network or model is
   unavailable.

Prefer a versioned route such as `POST /api/v1/sign-language/recognitions`,
but agree on the final path and schema before implementing either side.
Never send camera audio; audio capture is disabled in the current app.

## Google identity and backend authentication

Google sign-in currently establishes a frontend account only. To protect
backend user-specific routes, the backend must verify a Google ID token; it
must not trust an email or user ID supplied in request JSON.

Agree on the mechanism before coding. A typical flow is:

1. The frontend retrieves the signed-in account's Google `idToken`.
2. It sends the ID token in the HTTP `Authorization` header using the `Bearer`
   scheme to protected API routes over HTTPS.
3. The backend verifies the token's signature, issuer, expiry, and audience
   against the Web OAuth client ID, then uses the verified `sub` claim as the
   stable user key.

The frontend does not currently implement this flow, and translation is
currently unauthenticated. Do not put OAuth client secrets, AI provider keys,
or other backend secrets in Flutter, `.env` values compiled into Dart, or
mobile assets.

## Suggested task for Claude

Give Claude this document and access to the backend repository, then ask:

> Read `docs/BACKEND_INTEGRATION_HANDOFF.md` and inspect the existing backend
> before changing code. First report the current routes, authentication,
> storage, AI model interface, and deployment approach. Preserve the existing
> `POST /translate` contract unless you identify a concrete incompatibility
> and propose a coordinated migration. Do not invent a sign-language model or
> claim recognition works unless a model/service is actually available.
>
> Propose a versioned sign-language recognition API contract for review before
> implementing it. Include input modality and size limits, response/error
> schemas, authentication, guest behavior, privacy/retention, timeouts, and
> rate limits. Do not wire camera streaming or persist history without an
> explicit product decision.
>
> For any authenticated route, verify Google ID tokens server-side (signature,
> issuer, expiry, audience) and key accounts by the verified `sub` claim. Never
> trust client-supplied identity fields. Keep all server credentials in the
> backend's secret manager/environment and out of source control and Flutter
> assets.
>
> Add API documentation and automated tests for success, invalid payloads,
> unauthorized requests, size limits, upstream/model failures, and CORS where
> relevant. Report the exact environment variables and deployment steps, but
> do not print secret values. Do not change the Flutter repository or its API
> contract until the proposed contract is approved by both frontend and backend
> maintainers.
