source /usr/share/cachyos-fish-config/cachyos-config.fish

# Fix: --icons sin valor captura el siguiente argumento (p.ej. la ruta) como su WHEN.
# Fijar --icons=auto evita que `ls /ruta` falle con "invalid value for '--icons'".
alias ls='eza -al --color=always --group-directories-first --icons=auto' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons=auto'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons=auto'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons=auto' # tree listing

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
