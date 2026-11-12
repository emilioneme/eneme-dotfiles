# Eneme-Dotfiles — Arch Linux + Hyprland Dotfiles

This repository contains my personal configuration files (`dotfiles`) for Arch Linux running the Hyprland Wayland compositor. These files define my desktop environment's look, feel, and behavior.

Managed with [GNU Stow](https://www.gnu.org/software/stow/) — cloning this repo and running one script symlinks everything into place.

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
   sudo pacman -S hyprland stow quickshell git ghostty rofi neovim yazi nautilus awww webapp-creator swaync gtk3 gtk4 xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland hyprpolkitagent sunshine firewalld
   ```

# Dotfiles Installation
### 8. Clone this repo and stow your dotfiles

   ```bash
   git clone <your-repo-url> ~PATH/eneme-dotfiles
   cd ~/PATH/eneme-dotfiles
   chmod +x stow-home-dotfiles.sh
   ./stow-home-dotfiles.sh
   ```
   That's it, all your configs are now symlinked into place.


# MUST HAVE PACKAGES

- **hyprland**            (window manager)
- quickshell              (app bar and personal gui kit)
- **git**                 (screenshots)
- **stow**                (dotfiles symlink manager)
- **hypershot** 
- **xdg-desktop-portal**  (flatpak portals)
   - **xdg-desktop-portal-gtk**
   - **xdg-desktop-portal-hyprland**
- **hyprpolkitagent**     (authentication agent)
- **gnome-keyring**       (password storing)

- ghostty                 (terminal)
- rofi                    (app launcher)
- neovim                  (code editor)
- yazi                    (tui filemanager)
- nautilus                (gui filemanager)
- awww                    (wallpapers)
- swaync                  (notification center)
- gtk3 and gtk4           (gnome gui kit)
- google-chrome-stable    (or a browser)

- firewalld               (firwall manager)
- sunshine                (remote control)

---

# MY TOOLS

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
- gdu                     (tui storage manager)
- seahorse                (keyring manager)
- localsend
- opencode                (AI)
- claude-desktop          (AI)
- nvidia-settings 

   # GNOME TOOLS
   - gnome-password-and-keys
   - gnome-clocks            (Timer, World Clock, StopWatch)
   - gnome-calculator
   - gnome-weather
   - gnome-logs
   - gnome-resources
   - gnome-boxes             (Virtual MAchines)
   - gnome-maps
   - impressions             (drive formattinh)
   - d-spy                   (dbuss)

# ~/.CONFIG
   - hypr      (has all the keybidnings and starts)
   - fish      (allows me to run perosdnal scripts in the .local/bin like wp-set)
      - aliases: cd for z (zoxide), and dotfiles for cd dotfiles
   - btop      (theme)
   - fasfecth  (ascii)
   - gdu       (theme)
   - ghostty   (theme)
   - mimeapps.list (defualt zdg apps)
   - nvim      (theme)
   - rofi      (configs, theme, style)
   - yazi      (toml)

# ~/.LOCAL/BIN
   - wp-set.sh  (set wallpapers using awww)
   - wp-rotate.sh (rotates the wallpapers using awww)
   - smart-reboot.sh (select what to reboot next into)

   ## MOUNT DEVICE INTO BOOT
      - sudo mkdir -p /mnt/winesp
      - sudo mount /dev/nvme0n1p1 /mnt/winesp   (replace nvme0n1p1 with your device)
      - sudo cp -r /mnt/winesp/EFI/Microsoft /boot/EFI/
      - sudo umount /mnt/winesp

## MY APPS

- obs-studio
- steam
- krita
- audacity
- whatsapp               (webapp-wrapper.sh)
- obsidian
- audacity
- discord 
- spotify

## Bindings

- Hyperland Bindings

- Super + Enter                  -> Terminal
- Super + Shift + ENTER          -> Google Chrome

- Super + W                      -> Quit

- Super + F                      -> Fullscreen
- Super + Q                      -> Float Toggle

- Super + H                      -> Toggle Hide Quickshell
- Super + R                      -> Reload Hyperland

- Super + Miuns                  -> Lower Monitor Scaled
- Super + Equals                 -> Increase Monitor Scaled
- Super + SHift + Equals         -> Reset Monitor Scaled

- Super + M                      -> Toggle Headless Monitor2

- Super + S OR Super + Shift S   -> Screenshots

- Super + Shift + W              -> WhastApp Webb
- Super + Shift + D              -> Discord

- Super + Space                  -> Rofi Apps
- Super + Space + Enter          -> Rofi Commands
- Alt + Tab                      -> Rofi Windows


# SUNSHINE and MOONLIGHT

Add Sunshine ports to firewall (if sunshine does not connect already to the ipad)
```bash
sudo firewall-cmd --permanent --add-port={47984,47989,48010}/tcp --add-port=47998-48000/udp && sudo firewall-cmd --reload
```

# ~/.THEMES

You can find themes on the web, put them on `.Themes`, and use the nwg-look tool to preview the themes.

#### GTK Theme: MacTahoe-Dark

Set gtk theme:
```bash
gsettings set org.gnome.desktop.interface gtk-theme MacTahoe-Dark
```

#### Icon Theme: WhiteSur-grey-dark

Set gtk icon-theme:
```bash
gsettings set org.gnome.desktop.interface icon-theme WhiteSur-grey-dark
```