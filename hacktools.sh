#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Colores ANSI
# ==========================================

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# ==========================================
# Banner
# ==========================================

clear

echo -e "${CYAN}"
echo "==============================================="
echo "      Pentesting / Bug Bounty Installer"
echo "==============================================="
echo -e "${RESET}"

echo
echo -e "${YELLOW}Selecciona la familia de distribución:${RESET}"
echo
echo "  1) Ubuntu / Debian / Kali / ParrotOS / Mint ..."
echo "  2) Fedora"
echo "  3) Arch Linux / CachyOS / EndeavourOS / Archcraft ..."
echo "  4) OpenSUSE"
echo

read -rp "Opción [1-4]: " DISTRO

case "$DISTRO" in
    1)
        DISTRO_NAME="Ubuntu / Debian / Kali / ParrotOS / Mint"
        PKG_UPDATE="sudo apt update && sudo apt upgrade -y"
        PKG_INSTALL="sudo apt install -y"
        ;;
    2)
        DISTRO_NAME="Fedora"
        PKG_UPDATE="sudo dnf upgrade -y"
        PKG_INSTALL="sudo dnf install -y"
        ;;
    3)
        DISTRO_NAME="Arch Linux / CachyOS / EndeavourOS / Archcraft"
        PKG_UPDATE="sudo pacman -Syu --noconfirm"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        ;;
    4)
        DISTRO_NAME="OpenSUSE"
        PKG_UPDATE="sudo zypper refresh && sudo zypper update -y"
        PKG_INSTALL="sudo zypper install -y"
        ;;
    *)
        echo
        echo -e "${RED}[!] Opción no válida.${RESET}"
        exit 1
        ;;
esac

echo
echo -e "${GREEN}[+] Distribución seleccionada:${RESET} ${DISTRO_NAME}"
echo

echo -e "${YELLOW}[+] Configurando gestor de paquetes...${RESET}"
sleep 1

echo -e "${GREEN}[+] Actualizando el sistema...${RESET}"
eval "$PKG_UPDATE"

echo
echo -e "${GREEN}[+] Sistema actualizado.${RESET}"
echo

echo -e "${BLUE}===============================================${RESET}"
echo -e "${GREEN}Instalador inicializado correctamente.${RESET}"
echo -e "${BLUE}===============================================${RESET}"
echo

echo "Comando de instalación configurado:"
echo
echo "  $PKG_INSTALL"
echo
