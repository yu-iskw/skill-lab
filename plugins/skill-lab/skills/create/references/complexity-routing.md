# Complexity routing

Use the lowest level that safely covers the request. If unsure, route higher.

| Level | Signals                                                       | Required handling                                    |
| ----- | ------------------------------------------------------------- | ---------------------------------------------------- |
| 1     | Single SKILL.md, clear trigger, no external effects           | Intent, architect, validator, lightweight evaluation |
| 2     | Multi-step workflow, scripts, ambiguous criteria              | Plus isolated `output-evaluator`, eval aggregation   |
| 3     | Credentials, billing, deletion, deployment, high blast radius | Stop at unsafe boundary; require human direction     |

## Rules

- Any credential, billing, delete, deploy, or permission-changing action is Level 3.
- Level 3 does not authorize the action.
- Failed deterministic validation is always a hard gate.
- MVP repair limit is one iteration.
