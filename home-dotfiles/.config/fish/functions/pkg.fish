function pkg --description 'Fuzzy-find and install packages (pacman / AUR)'
    argparse h/help p/pacman a/aur b/both -- $argv
    or return 1

    if set -q _flag_help; or test (count $argv) -gt 0
        echo "Usage: pkg [OPTION]"
        echo
        echo "Fuzzy-find packages with fzf and install the selected ones."
        echo "Use TAB to select multiple packages."
        echo
        echo "Options:"
        echo "  -p, --pacman   Official repo packages (pacman)"
        echo "  -a, --aur      AUR packages only (yay)"
        echo "  -b, --both     Repo + AUR packages (yay)"
        echo "  -h, --help     Show this help"
        echo
        echo "With no option, defaults to --pacman."
        return 0
    end

    set -l fzf_opts --multi --preview-window=down:65%

    if set -q _flag_both
        yay -Slq | fzf $fzf_opts --preview 'yay -Sii {1}' | xargs -ro yay -S
    else if set -q _flag_aur
        yay -Slq aur | fzf $fzf_opts --preview 'yay -Sii {1}' | xargs -ro yay -S
    else
        pacman -Slq | fzf $fzf_opts --preview 'pacman -Sii {1}' | xargs -ro sudo pacman -S
    end
end
