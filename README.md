# HackMachine

Mi entorno de trabajo (CachyOS + Hyprland) empaquetado para reproducirlo en un equipo nuevo de golpe.

## Uso rápido

En el equipo nuevo, tras instalar CachyOS + Hyprland base:

```bash
git clone git@github.com:SrPatoMan/HackMachine.git
cd HackMachine
./install.sh
```

O directamente sin clonar a mano:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SrPatoMan/HackMachine/main/install.sh)
```

`install.sh` **sobrescribe** la configuración existente sin hacer backup (pensado para
un equipo recién instalado). Reinicia la shell al terminar.

## Estructura del repo

El script despliega cada carpeta en su ruta real:

| Carpeta del repo | Se copia a      | Notas                          |
|------------------|-----------------|--------------------------------|
| `config/`        | `~/.config/`    | dotfiles de apps (hypr, waybar, fish, kitty, nvim, rofi, btop, micro, VSCode, herramientas de recon...) |
| `home/`          | `~/`            | dotfiles de shell (`.zshrc`, `.bashrc`, `.bash_profile`, `.bash_logout`) |
| `system/`        | `/`             | archivos fuera del home (p. ej. `usr/share/cachyos-fish-config`), se copian con `sudo` |

Para añadir más config al repo: copia el archivo a la carpeta correspondiente
respetando la estructura de destino y haz commit. `install.sh` lo detecta solo,
no hay que tocar el script.

## Qué NO incluye (a propósito)

- Perfiles de navegador (Brave/Chromium/Firefox) → se recuperan con login/sync.
- Cachés, logs, historiales y resultados de escaneos (ffuf/waymore) → basura y datos de targets.
- Secretos (claves SSH, tokens, API keys) → nunca en un repo público.

## Extras

- `hacktools.sh` — instalador de dependencias base de pentesting/bug bounty por distro.
