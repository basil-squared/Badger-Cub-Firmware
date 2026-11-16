#!/usr/bin/env bash
set -euo pipefall

ELF_PATH="target/thumbv6m-none-eabi/release/badger_cub_fw"
UF2_PATH="target/thumbv6m-none-eabi/release/badger_cub_fw.uf2"
PATCHER="tools/patch_boot2"


if [[ ! -x "$PATCHER"]]

# gonna wip this because im tired and cba to finish ti right now now
