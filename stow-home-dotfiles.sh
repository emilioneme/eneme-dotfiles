#!/usr/bin/env bash

##This scirpt is a safe way to run stow, wihtout loosing files.

# Get the absolute path to the directory containing this script
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$REPO_DIR/home-dotfiles"
TARGET_DIR="$HOME"

# Get current date for the backup folder (e.g., 03-10-2026)
DATE_STR=$(date +'%d-%m-%Y')

echo "Starting stow process..."

# Navigate to the stow directory so 'find' paths are relative
cd "$STOW_DIR" || exit 1


# Find all files in the stow directory
find . -type f | while read -r file; do
    # Remove the leading './' from the find output
    rel_path="${file#./}"
    target_file="$TARGET_DIR/$rel_path"
    
    # Check if a file or symlink exists at the target location
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        # Resolve through symlinked parent dirs too (stow folds directories)
        target_real=$(readlink -f "$target_file")
        # If it already resolves into our STOW_DIR, safely ignore it
        if [[ "$target_real" == "$STOW_DIR"/* ]]; then
            continue
        fi
        
        # If we reach here, it is a conflict!
        # Create the backup directory alongside the conflicting file
        target_dir_path=$(dirname "$target_file")
        backup_dir="$target_dir_path/$DATE_STR"
        
        echo "Conflict found: $target_file"
        echo "Backing up to: $backup_dir/$(basename "$target_file").bak"
        
        mkdir -p "$backup_dir"
        mv "$target_file" "$backup_dir/$(basename "$target_file").bak"
    fi
done

# Now run stow from the repo directory
echo "Running stow..."
stow --dir="$REPO_DIR" --target="$TARGET_DIR" home-dotfiles

echo "Done! Dotfiles have been stowed successfully."
