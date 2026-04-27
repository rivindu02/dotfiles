#!/bin/bash
# Find the exact line, take the path, trim spaces, and expand the tilde
grep '^wallpaper =' ~/.config/waypaper/config.ini | head -n 1 | cut -d'=' -f2 | xargs | sed "s|^~|$HOME|"
