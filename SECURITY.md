# Security Policy

## Supported versions

Only the latest version on the default branch is considered for security reports. This is an experimental utility and has not been certified for production use.

## Reporting a vulnerability

Please do not publish sensitive personal information, logs containing usernames or local paths, or exploit details in a public issue. Use GitHub's private vulnerability reporting feature if enabled for this repository; otherwise contact the maintainer through the contact information on the GitHub profile.

## Scope

The script is intended to be read-only except for the explicitly confirmed cleanup of old files under the current user's TEMP directory. It should not modify the registry, disable services, or change system security settings.
