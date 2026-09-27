#!/usr/bin/env bash
# base: stock claude from the unchanged devcontainer, CONTEXT.md as the prompt, JSON reply (result + usage).
# New config = copy this folder, edit the line below.
cd /workspace && claude -p --output-format json < CONTEXT.md
