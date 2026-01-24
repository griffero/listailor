# Cursor Agent Rules (Listailor)

## Default workflow
- Understand the request and inspect relevant files before editing.
- Make changes, run the most relevant checks, and keep iterating until the task works end-to-end.
- Prefer small, verifiable changes; keep each loop tight.

## Render logs + feedback loop
- After any change that affects runtime behavior or deploys, check Render logs and surface errors/warnings.
- Use available Render tooling (CLI or dashboard) to confirm the app is healthy.
- If logs show failures, fix the cause and repeat the loop until logs are clean and the issue is resolved.
- Report what you checked and what improved each loop.

## Git and deploy policy
- If the user asks to push, push to `main` by default unless they specify another branch.
- Never force-push. Never bypass hooks unless explicitly requested.

## General behavior
- Keep actions transparent: list what you ran and why.
- Avoid destructive commands unless the user explicitly requests them.
