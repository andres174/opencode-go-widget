# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security vulnerabilities.

Report vulnerabilities privately to the maintainers via the private reporting
channel on GitHub (Security tab → Report a vulnerability) if available, or by
email to the project maintainers. Include:

- A description of the vulnerability and its impact.
- Steps to reproduce, including affected versions.
- Any suggested mitigations.

You will receive a response as soon as possible. Please allow time for a fix
and a coordinated disclosure before publishing details.

## Scope

- The API key handling and Keychain integration.
- Anything that could cause the API key to leak into logs, disk files,
  CI artifacts, or release bundles.
- Dependencies (none external at the moment) and the notification flow.

## Supported versions

Only the latest release is supported with security fixes.
