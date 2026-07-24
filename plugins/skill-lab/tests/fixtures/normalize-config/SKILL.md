---
name: normalize-config
description: Use when a simple .env-style configuration needs deterministic normalization for comparison or review.
---

# Normalize Config

Normalize a small `.env`-style config into a stable form that is easy to diff.

## Input Format

Use this skill only for line-oriented config entries shaped like:

```text
KEY=value
```

Comments beginning with `#` and blank lines are ignored.

## Normalization Rules

1. Trim surrounding whitespace from each key and value.
2. Lowercase keys.
3. Preserve value text exactly after trimming; do not lowercase or unquote values.
4. If a key appears more than once after lowercasing, keep the last value.
5. Sort output lines by key in ascending ASCII order.
6. Output only normalized `key=value` lines.

## Stop Conditions

If any non-comment line lacks `=`, stop and report the first invalid line instead of guessing.

## Example

Input:

```text
PORT = 3000
# local override
Name = API
port=8080
```

Output:

```text
name=API
port=8080
```
