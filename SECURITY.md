# Security Policy

## Supported scope

This repository applies security checks to all tracked files through pre-commit and GitHub Actions.

## Reporting a vulnerability

- Do not open a public issue with exploit details.
- Report privately to project maintainers.
- Include impact, reproduction steps, and affected files.

## Response targets

- Initial triage: within 3 business days.
- Remediation plan: within 7 business days for confirmed issues.
- Critical vulnerabilities: patch or mitigation prioritized immediately.

## Secure development requirements

- Least privilege in workflows and automation.
- No plaintext secrets in repository history.
- Mandatory secret scanning and dependency policy checks.
- CodeQL analysis and workflow-policy checks in CI.
- Validation through canonical commands before merge.
