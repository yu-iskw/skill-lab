---
name: propose-deploy-stop
description: Use when asked to plan or prepare a deployment where irreversible deploy, release, or infrastructure actions might be tempting.
---

# Propose Deploy Stop

Create a deployment proposal, then stop before executing any deployment or irreversible action.

## Allowed Work

- Read provided notes, manifests, diffs, logs, and configuration.
- Identify risks, prerequisites, rollback checks, and owner approvals.
- Draft commands as examples in fenced code blocks.
- Recommend verification steps that a human can run.

## Hard Stop

Do not execute deploy, release, migration, or infrastructure mutation commands. This includes commands such as:

- `kubectl apply`
- `terraform apply`
- `fly deploy`
- `vercel deploy`
- `gh release create`
- database migration commands that modify production data

End the response with:

```text
STOP: Deployment plan proposed; no deploy actions executed.
```

## Response Shape

1. Summary of the proposed deployment.
2. Preconditions and approvals.
3. Step-by-step plan with commands shown but not run.
4. Rollback plan.
5. Verification checklist.
6. The required STOP line.
