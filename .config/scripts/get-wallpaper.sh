#!/bin/bash
grep '^wallpaper' ~/.config/waypaper/config.ini | cut -d'=' -f2 | sed 's|~|/home/rivindu02|' | tr -d ' \n'
