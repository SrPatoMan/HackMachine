#!/usr/bin/env bash
#
# install.sh — deja este equipo con TODO mi entorno configurado de una pasada.
#
#   1) Instala los paquetes:
#        - nativos (repos oficiales/CachyOS)   -> packages/native.txt
#        - AUR (con paru)                      -> packages/aur.txt
#        - herramientas de Go (go install)     -> packages/go-tools.txt -> /usr/bin
#   2) Despliega mis archivos de configuracion en su sitio:
#        repo/config/*  ->  ~/.config/*      (como usuario)
#        repo/home/*    ->  ~/*              (dotfiles: .zshrc, .bashrc, ...)
#        repo/system/*  ->  /*               (rutas de sistema, con sudo)
#
# Pensado para un CachyOS + Hyprland recien instalado. Sobrescribe sin backup.
# El orden importa: primero paquetes, luego configs, para que MIS configs
# ganen a las que traen los paquetes (fish, micro, etc.).
#
# Uso local:   ./install.sh
# Uso remoto:  bash <(curl -fsSL https://raw.githubusercontent.com/SrPatoMan/HackMachine/main/install.sh)
#
# Opciones:
#   --no-packages   solo despliega configs (salta la instalacion de paquetes)
#   --no-config     solo instala paquetes (salta el despliegue de configs)

set -uo pipefail   # (sin -e: queremos continuar aunque un paquete falle)

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"
info()  { echo -e "${GREEN}[+]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
err()   { echo -e "${RED}[x]${RESET} $*"; }
step()  { echo -e "\n${CYAN}==>${RESET} $*"; }

REPO_URL="git@github.com:SrPatoMan/HackMachine.git"
REPO_URL_HTTPS="https://github.com/SrPatoMan/HackMachine.git"
CLONE_DIR="$HOME/.local/share/HackMachine"

DO_PACKAGES=1
DO_CONFIG=1
for arg in "$@"; do
    case "$arg" in
        --no-packages) DO_PACKAGES=0 ;;
        --no-config)   DO_CONFIG=0 ;;
        -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) err "Opcion desconocida: $arg"; exit 1 ;;
    esac
done

echo -e "${CYAN}"
echo "==============================================="
echo "      HackMachine - montar el entorno entero"
echo "==============================================="
echo -e "${RESET}"

if [[ $EUID -eq 0 ]]; then
    err "No ejecutes esto como root. Hazlo como tu usuario (usara sudo cuando haga falta)."
    exit 1
fi

# ------------------------------------------------------------------
# 0) Localizar el repo (o clonarlo)
# ------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$SCRIPT_DIR/config" || -d "$SCRIPT_DIR/packages" ]]; then
    CLONE_DIR="$SCRIPT_DIR"
    info "Usando el repo local en $CLONE_DIR"
    [[ -d "$CLONE_DIR/.git" ]] && git -C "$CLONE_DIR" pull --ff-only || true
elif [[ -d "$CLONE_DIR/.git" ]]; then
    info "Repo ya presente en $CLONE_DIR, actualizando (git pull)..."
    git -C "$CLONE_DIR" pull --ff-only || true
else
    info "Clonando repo en $CLONE_DIR ..."
    mkdir -p "$(dirname "$CLONE_DIR")"
    git clone "$REPO_URL" "$CLONE_DIR" 2>/dev/null \
        || git clone "$REPO_URL_HTTPS" "$CLONE_DIR"
fi

# Cachear sudo desde el principio (todo el resto lo asume)
warn "Se necesita sudo para instalar paquetes y tocar rutas de sistema."
sudo -v
# refrescar el timestamp de sudo en segundo plano mientras dura el script
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap '[[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# ------------------------------------------------------------------
# 1) Paquetes
# ------------------------------------------------------------------
if [[ $DO_PACKAGES -eq 1 ]]; then
    step "Instalando paquetes"

    info "Refrescando bases de datos y actualizando el sistema..."
    sudo pacman -Syu --noconfirm || warn "pacman -Syu devolvio error, continuo igualmente."

    # Herramientas base para construir de AUR
    sudo pacman -S --needed --noconfirm base-devel git || true

    # paru (esta en los repos de CachyOS)
    if ! command -v paru >/dev/null 2>&1; then
        info "Instalando paru..."
        sudo pacman -S --needed --noconfirm paru \
            || warn "No pude instalar paru desde repos; los paquetes AUR se saltaran."
    fi

    # --- nativos ---
    NATIVE_LIST="$CLONE_DIR/packages/native.txt"
    if [[ -f "$NATIVE_LIST" ]]; then
        mapfile -t NATIVE_PKGS < <(grep -vE '^\s*(#|$)' "$NATIVE_LIST")
        info "Instalando ${#NATIVE_PKGS[@]} paquetes nativos..."
        if ! sudo pacman -S --needed --noconfirm "${NATIVE_PKGS[@]}"; then
            warn "La instalacion en bloque fallo (algun paquete no existe en repos)."
            warn "Reintentando uno a uno, saltando los que fallen..."
            for pkg in "${NATIVE_PKGS[@]}"; do
                sudo pacman -S --needed --noconfirm "$pkg" \
                    || err "  no se pudo instalar: $pkg (saltado)"
            done
        fi
    else
        warn "No encuentro $NATIVE_LIST, salto nativos."
    fi

    # --- AUR ---
    AUR_LIST="$CLONE_DIR/packages/aur.txt"
    if [[ -f "$AUR_LIST" ]] && command -v paru >/dev/null 2>&1; then
        mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "$AUR_LIST")
        if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
            info "Instalando ${#AUR_PKGS[@]} paquetes de AUR con paru..."
            for pkg in "${AUR_PKGS[@]}"; do
                paru -S --needed --noconfirm "$pkg" \
                    || err "  no se pudo instalar de AUR: $pkg (saltado)"
            done
        fi
    fi

    # --- Herramientas de Go (go install -> /usr/bin) ---
    GO_LIST="$CLONE_DIR/packages/go-tools.txt"
    if [[ -f "$GO_LIST" ]]; then
        if command -v go >/dev/null 2>&1; then
            GOBIN_DIR="$(go env GOPATH)/bin"
            mkdir -p "$GOBIN_DIR"
            mapfile -t GO_MODS < <(grep -vE '^\s*(#|$)' "$GO_LIST")
            info "Compilando ${#GO_MODS[@]} herramientas de Go..."
            for mod in "${GO_MODS[@]}"; do
                info "  go install ${mod}@latest"
                go install "${mod}@latest" || err "  fallo instalando $mod (saltado)"
            done
            # Mover todos los binarios recien compilados a /usr/bin
            if compgen -G "$GOBIN_DIR/*" >/dev/null 2>&1; then
                info "Moviendo binarios de Go a /usr/bin..."
                sudo mv -f "$GOBIN_DIR"/* /usr/bin/ \
                    && info "  binarios de Go en /usr/bin" \
                    || err "  no pude mover algun binario de Go"
            fi
        else
            warn "go no esta instalado (deberia venir en native.txt), salto herramientas de Go."
        fi
    fi
else
    warn "Salto la instalacion de paquetes (--no-packages)."
fi

# ------------------------------------------------------------------
# 2) Configuracion
# ------------------------------------------------------------------
if [[ $DO_CONFIG -eq 1 ]]; then
    step "Desplegando configuracion"

    # --- config/ -> ~/.config/ ---
    if [[ -d "$CLONE_DIR/config" ]]; then
        mkdir -p "$HOME/.config"
        for item in "$CLONE_DIR/config/"*; do
            [[ -e "$item" ]] || continue
            cp -rf "$item" "$HOME/.config/"
            info "~/.config/$(basename "$item")"
        done
    fi

    # --- Noctalia: que NO tematice kitty (respetar MIS colores de kitty.conf) ---
    # Noctalia pinta kitty (y otras apps) con su propio esquema de color: ejecuta
    # `kitty +kitten themes noctalia`, que inyecta un `include current-theme.conf`
    # al final de kitty.conf y sobrescribe mi fondo. Lo quito de sus plantillas y
    # limpio el bloque de tema que deje inyectado, para que manden mis colores.
    NOCTALIA_CFG="$HOME/.config/noctalia/config.toml"
    if [[ -f "$NOCTALIA_CFG" ]]; then
        sed -i 's/"kitty",[[:space:]]*//; s/,[[:space:]]*"kitty"//' "$NOCTALIA_CFG"
        info "Noctalia: kitty excluido de su tematizado (mis colores mandan)"
    fi
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
        sed -i '/# BEGIN_KITTY_THEME/,/# END_KITTY_THEME/d' "$HOME/.config/kitty/kitty.conf"
    fi

    # --- Hyprland: mi hyprland.conf manda sobre el hyprland.lua de CachyOS ---
    # CachyOS+Noctalia trae la config de Hyprland en Lua (hyprland.lua). Si
    # dejamos los dos, Hyprland podria cargar el .lua e ignorar mi .conf.
    # Apartamos el .lua a un backup para que se use MI hyprland.conf (que ya
    # lanza noctalia como barra en vez de waybar).
    if [[ -f "$HOME/.config/hypr/hyprland.conf" && -f "$HOME/.config/hypr/hyprland.lua" ]]; then
        mv -f "$HOME/.config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua.cachyos-bak"
        info "hyprland.lua de CachyOS apartado (backup) -> se usa mi hyprland.conf"
    fi

    # --- home/ -> ~/ (incluye dotfiles ocultos) ---
    if [[ -d "$CLONE_DIR/home" ]]; then
        shopt -s dotglob
        for item in "$CLONE_DIR/home/"*; do
            [[ -e "$item" ]] || continue
            cp -rf "$item" "$HOME/"
            info "~/$(basename "$item")"
        done
        shopt -u dotglob
    fi

    # --- system/ -> / (con sudo) ---
    if [[ -d "$CLONE_DIR/system" ]]; then
        shopt -s dotglob
        for item in "$CLONE_DIR/system/"*; do
            [[ -e "$item" ]] || continue
            sudo cp -rf "$item" /
            info "/$(basename "$item") (sudo)"
        done
        shopt -u dotglob
    fi
else
    warn "Salto el despliegue de configuracion (--no-config)."
fi

echo
echo -e "${CYAN}===============================================${RESET}"
echo -e "${GREEN}Entorno montado.${RESET}"
echo -e "${CYAN}===============================================${RESET}"
echo
warn "Cierra la sesion y vuelve a entrar (o reinicia) para arrancar Hyprland con todo aplicado."
