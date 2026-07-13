# HackMachine

Mi entorno de trabajo (CachyOS + Hyprland) empaquetado para reproducirlo en un equipo nuevo de golpe.

## Uso rápido

En el equipo nuevo, tras una instalación limpia de CachyOS:

```bash
git clone git@github.com:SrPatoMan/HackMachine.git
cd HackMachine
./install.sh
```

O directamente sin clonar a mano:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SrPatoMan/HackMachine/main/install.sh)
```

`install.sh` hace **dos cosas** de una pasada:

1. **Instala los paquetes**: actualiza el sistema, instala `paru`, luego todos los
   paquetes nativos (`packages/native.txt`) y los de AUR (`packages/aur.txt`).
   Si algún paquete no existe en los repos, lo salta y sigue (no aborta).
2. **Despliega la configuración** (ver tabla abajo). Se hace *después* de los
   paquetes, a propósito, para que mis configs ganen a las que traen los paquetes.

**Sobrescribe** la configuración existente sin backup (pensado para un equipo recién
instalado). Al terminar, cierra sesión y vuelve a entrar.

### Opciones

- `./install.sh --no-packages` → solo configs (útil para reaplicar dotfiles).
- `./install.sh --no-config`   → solo paquetes.

## Estructura del repo

El script despliega cada carpeta en su ruta real:

| Carpeta del repo | Se copia a      | Notas                          |
|------------------|-----------------|--------------------------------|
| `config/`        | `~/.config/`    | dotfiles de apps (hypr, waybar, fish, kitty, nvim, rofi, btop, micro, VSCode, herramientas de recon...) |
| `home/`          | `~/`            | dotfiles de shell (`.zshrc`, `.bashrc`, `.bash_profile`, `.bash_logout`) |
| `system/`        | `/`             | archivos fuera del home (p. ej. `usr/share/cachyos-fish-config`), se copian con `sudo` |
| `packages/`      | (no se copia)   | listas `native.txt` y `aur.txt` que instala el script |

Para añadir más config al repo: copia el archivo a la carpeta correspondiente
respetando la estructura de destino y haz commit. `install.sh` lo detecta solo,
no hay que tocar el script.

## Qué NO incluye (a propósito)

- Perfiles de navegador (Brave/Chromium/Firefox) → se recuperan con login/sync.
- Cachés, logs, historiales y resultados de escaneos (ffuf/waymore) → basura y datos de targets.
- Secretos (claves SSH, tokens, API keys) → nunca en un repo público.

## Extras

- `hacktools.sh` — instalador de dependencias base de pentesting/bug bounty por distro.
