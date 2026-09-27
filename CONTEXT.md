# Devcontainer experiment notes

Running log for `.skogai/scripts/run <config>`. Each run builds on what is here.

## How a run works

1. Copy the unchanged base `src/claude-code-ansible/.devcontainer/` into the fixed `tmp/workspace/`.
2. Write `tmp/workspace/CONTEXT.md`: `[$skogai:context]`, `git diff --cached` of this repo, `[$/skogai:context]`.
3. `DOCKER_HOST=unix:///run/user/1000/podman/podman.sock npx -y @devcontainers/cli up --workspace-folder tmp/workspace --docker-path podman`.
4. `devcontainers/cli exec` runs `.skogai/config/claude/<config>/run.sh` unchanged (copied to `/workspace/.skogai-run.sh`).
5. Save to `tmp/runs/<time>-<config>/`: `status`, `summary.json` (usage, cost, turns), `reply.json`, `reply.md`, `up.log`, `exec.log`, `CONTEXT.md`, `config/`.

New config: `cp -r .skogai/config/claude/base .skogai/config/claude/<name>` and edit the one command line.

Sign-in: whatever the host exports (`ANTHROPIC_API_KEY` via the base `containerEnv`; `CLAUDE_CODE_OAUTH_TOKEN` / `ANTHROPIC_API_KEY` forwarded with `--remote-env` at exec), or a login stored once in the `claude-code-config-<devcontainerId>` volume. A failed sign-in is recorded as `claude-error` / `exec-failed`, not asked about.

## Rootless podman: what the build broke

- Build itself: fine. `podman buildx build` of the base took ~2.5 min (cold), no errors; only warning `build args were not consumed: [BUILDKIT_INLINE_CACHE]`.
- `up` hangs forever after `Container started` (run `20260927T074745-base`, stuck 10+ min, recorded `up-failed`). devcontainers/cli 0.89.0 waits on `podman events --format json --filter event=start`, spawned at the same moment as `podman run`. The start event is in the journal (`podman events --since`) but the live stream never delivered it: a startup race, since a manual `podman events` started 3s early sees the same event (even with a 7 KB label) within 0.2s. Container itself was idle; postCreate never ran.
- Workaround in `.skogai/scripts/run`: watchdog kills `up` after 60s of silence following `Container started` and re-runs it once; the second `up` finds the running container and continues to lifecycle commands. Logged in `up.retries`.

## Configs: tokens and output

| run | config | status | input | cache read | cache create | output | cost | notes |
| --- | ------ | ------ | ----- | ---------- | ------------ | ------ | ---- | ----- |
| 20260927T074745 | base | up-failed | – | – | – | – | – | hung after `Container started` (events race), killed by hand |
| 20260927T080345 | base | claude-error | 0 | 0 | 0 | 0 | $0 | `Not logged in · Please run /login`; up 15s (reused running container, postCreate + postStart ran, no retry needed); CONTEXT.md 37 B because nothing was staged |

## Next to try

- Sign-in: host exports neither `CLAUDE_CODE_OAUTH_TOKEN` nor `ANTHROPIC_API_KEY`, and the `claude-code-config-098f7ob73aol5hg8s0lcd3mfh0rjb4r0ktgqdisultlga32f3akm` volume is empty. Either export a `claude setup-token` token on the host before `run`, or log in once inside the container (volume keeps it).
- Base sets `ANTHROPIC_MODEL=claude-opus-4-6`; a config that overrides the model is the first obvious variant once sign-in works.
- Watchdog path is still unexercised on a cold start: remove the container (`podman rm -f` on the `devcontainer.local_folder=…/tmp/workspace` label) and run again to confirm `up.retries` fires and recovers.
- Stage something before a run so CONTEXT.md carries a real diff.
