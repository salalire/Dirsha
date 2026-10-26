# Dirsha AI integration

## Hackathon scope decision

Although FR-AI-01 through FR-AI-05 are P2 and optional in the SRS, the hackathon demo includes a read-only MVP: authenticated `POST /ai/chat` and an in-app Flutter chat screen. This does not change SRS priority.

## Providers

| `AI_PROVIDER` | When to use | Required env |
|---|---|---|
| `mock` (default) | Backend tests, CI, and offline demo | none |
| `gemini` | Live hackathon demo | `GEMINI_API_KEY`; optional `GEMINI_MODEL_ID` |
| `bedrock` | Optional AWS path | `AI_MODEL_ID` and `AWS_REGION` |

Keys never enter Flutter. Do not commit real API keys. Copy `backend/.env.example` to `backend/.env` locally.

`AI_ALLOW_MOCK_FALLBACK=true` lets a Gemini or Bedrock failure fall back to mock answers (always labelled `simulated: true`). Leave it `false` when a provider outage should show `AI_UNAVAILABLE`.

## Flutter mock vs live

| `DIRSHA_USE_MOCKS` | AI repository | Answers come from |
|---|---|---|
| `true` | `MockAiRepository` | Local canned educational text. Banner says this is simulated. |
| `false` (app default) | `LiveAiRepository` | Backend `POST /ai/chat`, using the configured mock, Gemini, or Bedrock provider. |

Do not mix mock auth with live AI (a mock token would 401 and kick the user out).

## Safety and grounding

- Prefilter refuses buy/sell/subscribe/transfer and private wallet/document requests **before** any model call.
- IPO facts come only from `listIpos` / `getIpo` (visibility rules unchanged). Money is integer santim, rendered as ETB for the model.
- System prompt separates "From Dirsha data" vs "General explanation", forbids advice, and treats user/history/IPO description as untrusted data.
- Every response includes a language-matched disclaimer. Mock/fallback answers set `simulated: true`.

The AI module does not import wallet, ledger, subscriptions, onboarding, admin, or write-user code, and it has no action-taking tools.

## Demo with Gemini

In `backend/.env`:

```
AI_PROVIDER=gemini
GEMINI_MODEL_ID=gemini-3.5-flash-lite
# Set GEMINI_API_KEY only in backend/.env; never commit it.
```

Then:

```bash
cd backend
npm run dev

cd ../mobile
flutter run --dart-define=DIRSHA_USE_MOCKS=false --dart-define=DIRSHA_API_BASE_URL=http://10.0.2.2:3000
```

There is **no `/api` prefix**. Android emulator uses `10.0.2.2`; a physical device needs the host LAN IP; Windows/desktop can use `http://localhost:3000`.

Create an **Investor** account (not Company/Broker), sign in, open **Ask AI** on Dashboard/IPOs (hidden on Wallet), or **Ask AI about this IPO** on an offering.

## Known limits

- Amharic is requested and prompted, but quality is not guaranteed; see `docs/AI_EVAL.md`.
- Mock answers are simulated. The UI shows "Demo answer (simulated)" when `simulated` is true.
- Gemini is request-time generation, not model training. It receives only the authorized IPO context selected by the backend.
- The Bedrock adapter requires an approved model and AWS credentials from the default SDK credential chain.
