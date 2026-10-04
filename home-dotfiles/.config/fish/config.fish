source /usr/share/cachyos-fish-config/cachyos-config.fish

if test -d ~/.local/bin
    fish_add_path ~/.local/bin
end

# overwrite greeting
function fish_greeting
   # potentially disabling fastfetch
end

zoxide init fish | source