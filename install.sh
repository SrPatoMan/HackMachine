#!/usr/bin/env bash
#
# install.sh — clona/actualiza este repo y vuelca los archivos de configuracion
# sobre el sistema actual, sobrescribiendo lo que haya.
#
# Uso: ./install.sh
#   (o remoto: bash <(curl -fsSL https://raw.githubusercontent.com/SrPatoMan/HackMachine/main/install.sh))

set -euo pipefail

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

REPO_URL="https://github.com/SrPatoMan/HackMachine.git"
CLONE_DIR="$HOME/.local/share/HackMachine"

# ==========================================
# Tabla de mapeo: "origen (relativo al repo)|destino|tipo"
#   tipo = home   -> destino relativo a $HOME, se copia como el usuario actual
#   tipo = system -> destino absoluto (empieza en /), se copia con sudo
# Añadir aquí cada archivo/carpeta nuevo que se suba al repo.
# ==========================================
MAPPINGS=(
    "hyprland.conf|.config/hypr/hyprland.conf|home"
    "config/waybar|.config/waybar|home"
    "AppsConfigFiles/VsCode/settings.json|.config/Code - OSS/User/settings.json|home"
    "usr/share/cachyos-fish-config|/usr/share/cachyos-fish-config|system"
)

echo -e "${CYAN}"
echo "==============================================="
echo "      HackMachine - sincronizador de config"
echo "==============================================="
echo -e "${RESET}"

if [[ -d "$CLONE_DIR/.git" ]]; then
    echo -e "${YELLOW}[+] Repo ya clonado, actualizando (git pull)...${RESET}"
    git -C "$CLONE_DIR" pull --ff-only
else
    echo -e "${YELLOW}[+] Clonando repo en $CLONE_DIR ...${RESET}"
    git clone "$REPO_URL" "$CLONE_DIR"
fi

# sudo por adelantado solo si hace falta para alguna entrada "system"
needs_sudo=false
for entry in "${MAPPINGS[@]}"; do
    [[ "$entry" == *"::system" ]] && needs_sudo=true
done
if $needs_sudo; then
    echo -e "${YELLOW}[+] Algunas rutas son del sistema, pidiendo sudo...${RESET}"
    sudo -v
fi

echo
for entry in "${MAPPINGS[@]}"; do
    IFS='|' read -r src dest kind <<< "$entry"
    src_path="$CLONE_DIR/$src"

    if [[ ! -e "$src_path" ]]; then
        echo -e "${RED}[!] No existe en el repo: $src${RESET}"
        continue
    fi

    if [[ "$kind" == "home" ]]; then
        dest_path="$HOME/$dest"
        mkdir -p "$(dirname "$dest_path")"
        cp -rf "$src_path" "$dest_path"
        echo -e "${GREEN}[+] ~/${dest}${RESET}"
    elif [[ "$kind" == "system" ]]; then
        dest_path="$dest"
        sudo mkdir -p "$(dirname "$dest_path")"
        sudo cp -rf "$src_path" "$dest_path"
        echo -e "${GREEN}[+] ${dest} (sudo)${RESET}"
    else
        echo -e "${RED}[!] Tipo desconocido '$kind' para $src${RESET}"
    fi
done

echo
echo -e "${CYAN}===============================================${RESET}"
echo -e "${GREEN}Configuracion sincronizada.${RESET}"
echo -e "${CYAN}===============================================${RESET}"
