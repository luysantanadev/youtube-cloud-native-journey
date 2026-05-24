#!/usr/bin/env bash

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0
    [[ -r /proc/version ]] && grep -qi microsoft /proc/version
}

command_exists() {
    command -v "$1" &>/dev/null
}

require_docker_runtime() {
    if ! command_exists docker; then
        echo "Docker não encontrado no WSL. Inicie o Docker Engine/Docker Desktop no host antes de continuar."
        exit 1
    fi

    if ! docker info &>/dev/null; then
        echo "Docker está instalado, mas o daemon não responde. Verifique se o Docker Engine está ativo no host."
        exit 1
    fi
}
