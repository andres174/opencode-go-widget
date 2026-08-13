# OpenCode Go Usage API

Contract observed by the widget when talking to the OpenCode Go usage endpoint.
Changes to this API are surfaced in the app as a decoding error ("The usage
response has an invalid format."); update `UsageAPIClient` and `UsageResponse`
if the upstream API changes.

## Endpoint

- URL: `https://opencode.ai/zen/go/v1/usage`
- Method: `GET`
- Auth: `Authorization: Bearer <OPENCODE_API_KEY>`
- Timeout: 20 seconds

## Status codes

| Status | Meaning                                  | App behavior                          |
| ------ | ---------------------------------------- | ------------------------------------- |
| 200    | Success                                  | Renders usage                         |
| 401    | Invalid or expired API key               | "Invalid or expired API key."         |
| Other  | Server error                             | "Server error (HTTP \<status\>)."     |
| —      | Network failure                          | Offline state with last update shown  |

## Response schema

The response is a JSON object with a single root key holding three windows.
The API has been observed emitting both `usage` and `Usage` as the root key;
the decoder accepts both.

```json
{
  "usage": {
    "rolling": { "percent": 12, "resetsAt": "2026-08-12T12:00:00Z" },
    "weekly":  { "percent": 8,  "resetsAt": null },
    "monthly": { "percent": 35, "resetsAt": "2026-09-01T00:00:00Z" }
  }
}
```

| Field                 | Type     | Notes                                              |
| --------------------- | -------- | -------------------------------------------------- |
| `usage` / `Usage`     | object   | Required. Both key spellings are decoded.          |
| `rolling.percent`     | number   | 0–100 percentage. The UI clamps out-of-range values via `validatedPercent`. |
| `rolling.resetsAt`    | string?  | ISO 8601 date, or `null` when it never resets.     |
| `weekly.percent`      | number   | Same as above.                                     |
| `weekly.resetsAt`     | string?  | Same as above.                                     |
| `monthly.percent`     | number   | Same as above.                                     |
| `monthly.resetsAt`    | string?  | Same as above.                                     |

## Handling API changes

1. The decoder fails loudly on missing or malformed fields, and the error
   state is shown in the menu bar window.
2. Root key: both `usage` and `Usage` are supported (`UsageResponse.CodingKeys`).
3. Percentages are treated as 0–100 and clamped before rendering.
4. Dates are parsed with `ISO8601DateFormatter`; unparseable strings are shown
   verbatim instead of crashing.
