#!/usr/bin/env bash
#
# install.sh — despliega mis archivos de configuracion sobre este equipo.
#
# Clona (o actualiza) el repo y vuelca su contenido en las rutas reales:
#   repo/config/*  ->  ~/.config/*      (como usuario)
#   repo/home/*    ->  ~/*              (dotfiles: .zshrc, .bashrc, ...)
#   repo/system/*  ->  /*               (rutas de sistema, con sudo)
#
# Sobrescribe lo que exista SIN hacer backup (equipo nuevo -> nada que perder).
#
# Uso local:   ./install.sh
# Uso remoto:  bash <(curl -fsSL https://raw.githubusercontent.com/SrPatoMan/HackMachine/main/install.sh)

set -euo pipefail

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

REPO_URL="git@github.com:SrPatoMan/HackMachine.git"
REPO_URL_HTTPS="https://github.com/SrPatoMan/HackMachine.git"
CLONE_DIR="$HOME/.local/share/HackMachine"

info()  { echo -e "${GREEN}[+]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
err()   { echo -e "${RED}[x]${RESET} $*"; }

echo -e "${CYAN}"
echo "==============================================="
echo "      HackMachine - desplegar configuracion"
echo "==============================================="
echo -e "${RESET}"

# ------------------------------------------------------------------
# 1) Localizar el repo (o clonarlo)
# ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$SCRIPT_DIR/config" ]]; then
    # El script se ejecuta desde una copia del repo (git clone o descarga).
    CLONE_DIR="$SCRIPT_DIR"
    info "Usando el repo local en $CLONE_DIR"
    [[ -d "$CLONE_DIR/.git" ]] && git -C "$CLONE_DIR" pull --ff-only || true
elif [[ -d "$CLONE_DIR/.git" ]]; then
    info "Repo ya presente en $CLONE_DIR, actualizando (git pull)..."
    git -C "$CLONE_DIR" pull --ff-only
else
    # Ejecucion via curl: no hay repo en disco, hay que clonarlo.
    info "Clonando repo en $CLONE_DIR ..."
    mkdir -p "$(dirname "$CLONE_DIR")"
    git clone "$REPO_URL" "$CLONE_DIR" 2>/dev/null \
        || git clone "$REPO_URL_HTTPS" "$CLONE_DIR"
fi

# ------------------------------------------------------------------
# 2) Pedir sudo por adelantado solo si hay que tocar el sistema
# ------------------------------------------------------------------
if [[ -d "$CLONE_DIR/system" ]] && [[ -n "$(ls -A "$CLONE_DIR/system" 2>/dev/null)" ]]; then
    warn "Hay rutas de sistema que desplegar, pidiendo sudo..."
    sudo -v
fi

# ------------------------------------------------------------------
# 3) Desplegar
# ------------------------------------------------------------------
echo

# --- config/ -> ~/.config/ ---
if [[ -d "$CLONE_DIR/config" ]]; then
    mkdir -p "$HOME/.config"
    for item in "$CLONE_DIR/config/"*; do
        [[ -e "$item" ]] || continue
        name="$(basename "$item")"
        cp -rf "$item" "$HOME/.config/"
        info "~/.config/$name"
    done
fi

# --- home/ -> ~/ (incluye dotfiles ocultos) ---
if [[ -d "$CLONE_DIR/home" ]]; then
    shopt -s dotglob
    for item in "$CLONE_DIR/home/"*; do
        [[ -e "$item" ]] || continue
        name="$(basename "$item")"
        cp -rf "$item" "$HOME/"
        info "~/$name"
    done
    shopt -u dotglob
fi

# --- system/ -> / (con sudo) ---
if [[ -d "$CLONE_DIR/system" ]]; then
    shopt -s dotglob
    for item in "$CLONE_DIR/system/"*; do
        [[ -e "$item" ]] || continue
        name="$(basename "$item")"
        sudo cp -rf "$item" /
        info "/$name (sudo)"
    done
    shopt -u dotglob
fi

echo
echo -e "${CYAN}===============================================${RESET}"
echo -e "${GREEN}Configuracion desplegada.${RESET}"
echo -e "${CYAN}===============================================${RESET}"
echo
warn "Reinicia la shell (o abre una terminal nueva) para aplicar los cambios."
