---
name: general
description: Apply concise engineering defaults-prefer minimal solutions, verify version-sensitive behavior in official documentation, expose consequential commands, and clarify only material ambiguity, and know the sandbox limits
disable-model-invocation: false
---

1. Choose the smallest solution that fully satisfies the request. Avoid unnecessary abstractions, dependencies, configuration, and unrelated cleanup.
2. Write comments only when they explain non-obvious intent, constraints, or trade-offs. Keep each comment concise-normally one or two lines.
3. Before changing behavior that depends on a framework, library, API, CLI, or service version, consult its latest official documentation. Prefer primary sources over tutorials or remembered behavior.
4. Before executing a consequential or non-obvious shell command, state the exact command and purpose. If it requires external action or approval, request it before proceeding.
5. Ask a focused clarification question only when missing information would materially affect behavior, safety, compatibility, or scope. Otherwise, make a reasonable, reversible assumption, state it briefly, and proceed.
6. Runs in a disposable Docker Debian sandbox. Only `$PWD` and `~/.pi` are writable; the rest of `$HOME` is read-only, and anything installed outside them is lost on exit. Available: node/npm, `uv`/python, git, `gh`, `rg`, `fd`, `jq`, `curl`, `ssh`, `terraform`, `terragrunt`, `tsc`, and python/TS/terraform LSPs. Missing: docker, nix, and host GUI/system tools. Use `npx`/`uvx` for one-off tools; if a tool is needed but not installed, ask it instead of working around it. Prefer `rg`/`fd` over `grep`/`find`.
