---
state: new
created: 2026-09-27T05:45:21.782642+00:00
priority: medium
task_type: action
assigned_to: bob
---

# I'll act as the orchestrator and use what already exists. The context is that ansible-claude-code-devcontainer/src/claude-code-ansible/.devcontainer/ is the unchanged base. Each run copies it into a fixed tmp/workspace/, starts it with DOCKER_HOST=unix:///run/user/1000/podman/podman.sock npx -y @devcontainers/cli up --workspace-folder tmp/workspace --docker-path podman, and builds CONTEXT.md your way: your text, then git diff --cached, then more of your text. It then runs your script unchanged through npx -y @devcontainers/cli exec and saves the reply and token counts to tmp/runs/<time>-<config>/. Each config is just a folder holding one script under .skogai/config/claude/<name>/, so changing Claude means copying a folder and editing one line. Sign-in is handled the same way: the container uses whatever the host already exports, or a login stored once in its claude-code-config-* volume. If a run can't sign in, that failure gets recorded like any other result, with no questions to you. Everything I learn goes into .skogai/NOTES.md in that repo, and each run builds on it. That covers what the build broke under rootless podman, what each config changed in tokens and output, and what to try next. The next step is to write the runner, your script as the base config, and the notes file, then start the first build in the background. It takes about 3–5 minutes. I'll then report the base-case result in one paragraph.
