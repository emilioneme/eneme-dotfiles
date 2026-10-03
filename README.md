# Eneme-Dotfiles — Arch Linux + Hyprland Dotfiles

This repository contains my personal configuration files (`dotfiles`) for Arch Linux running the Hyprland Wayland compositor. These files define my desktop environment's look, feel, and behavior.

Managed with [GNU Stow](https://www.gnu.org/software/stow/) — cloning this repo and running one script symlinks everything into place.

---

## MUST HAVE PACKAGES

- **hyprland**            (window manager)
- quickshell              (app bar and personal gui kit)
- **git**                 (screenshots)
- **stow**                (dotfiles symlink manager)
- **hypershot** 
- **xdg-desktop-portal**  (flatpak portals)
- **xdg-desktop-portal-gtk**
- **xdg-desktop-portal-hyprland**

- ghostty                 (terminal)
- rofi                    (app launcher)
- neovim                  (code editor)
- yazi                    (tui filemanager)
- nautilus                (gui filemanager)
- awww                    (wallpapers)
- webapp-creator          (create web apps)
- swaync                  (notification center)
- gtk3 and gtk4           (gnome gui kit)
- google-chrome-stable    (or a browser)

---

## SET UP ON A FRESH SYSTEM

### 1. Get Cachy OS ISO
### 2. Boot from Cachy OS live USB/ISO
### 3. Choose Hyprland on install
### 4. Ethernet connection
### 5. Start Hyprland:
   ```
   start-hyperland
   ```
### 6. Get a code editor (or text editor)
### 7. Install packages

   ```bash
   sudo pacman -S hyprland stow quickshell git ghostty rofi neovim yazi nautilus awww webapp-creator swaync gtk3 gtk4 xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland
   ```

### 8. Clone this repo and stow your dotfiles

   ```bash
   git clone <your-repo-url> ~PATH/eneme-dotfiles
   cd ~/PATH/eneme-dotfiles
   chmod +x stow-home-dotfiles.sh
   ./stow-home-dotfiles.sh
   ```
   That's it, all your configs are now symlinked into place.

## Installation


## PLYMOUTH THEMES

Plymouth themes go to `/usr/share/plymouth/themes` (system location), so they need sudo and are **not** handled by `stow.sh`.

### Install Plymouth themes
```bash
TODO: cd REPOPATH, and run .plymouth-add.sh /misc/plymoth/
TODO: symlink the REPOPATH/mis/plymouth folder to /usr/share/plymouth/themes
```

### Set your preferred theme

```bash
sudo plymouth-set-default-theme <theme-name>
```

### Rebuild initramfs so the theme loads at boot

```bash
sudo mkinitcpio -P
```

---

## .THEMES (in .config)

You can find themes on the web, put them on `.Themes`, and use the nwg-look tool to preview the themes.

#### GTK Theme: MacTahoe-Dark

```bash
gsettings set org.gnome.desktop.interface gtk-theme MacTahoe-Dark
```

#### Icon Theme: WhiteSur-grey-dark

```bash
gsettings set org.gnome.desktop.interface icon-theme WhiteSur-grey-dark
```

---

## MY TOOLS

- vscode                  (code editor)
- lazygit                 (git gui)
- github-desktop          (github gui)
- btop++                  (performance monitor)
- mpv                     (media player)
- nwg-look                (gtk theme tool)
- blueman                 (bluetooth control)
- shelly                  (library manager)
- pavucontrol             (volume control)
- avahi-daemon            (ssh server)
- baobab                  (disk usage analyzer)
- network-manager-applet  (network manager)

---

## MY APPS

- obs-studio
- steam
- krita
- audacity
- whatsapp               (through web app wrapper)
- localsend
