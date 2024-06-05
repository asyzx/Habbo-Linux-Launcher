#!/bin/bash

# unzip wget wine dialog xdg-utils



app_path="$HOME/.local/share/applications/HabboWine"

# Correct crashing problem when opening certain windows (e.g. shop, profile, BC warehouse) extracted from winetricks heapcheck

load_heapcheck() { 
    cat > heapcheck.reg <<_EOF_
REGEDIT4

[HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager]
"GlobalFlag"=dword:00200030

_EOF_

    wine regedit heapcheck.reg
}

set_habbo_url_protocol() {
    echo "xdg-settings set default-url-scheme-handler habbo $*"
    if command -v xdg-settings >/dev/null 2>&1; then
        echo "Registering habbo url protocol"
#        xdg-settings set default-url-scheme-handler habbo HabboLauncher.desktop
        xdg-mime default HabboLauncher.desktop x-scheme-handler/habbo
    else
        echo "Error: unable to register habbo url protocol"
    fi
}

set_habbo_desktop() {

    if command -v xdg-user-dir >/dev/null 2>&1; then

        LinuxDesktopPath="$HOME/.local/share/applications/HabboLauncher.desktop"

        echo "Creating desktop shortcut"

        cat > $LinuxDesktopPath << _EOF_
[Desktop Entry]
Type=Application
Name=Habbo Launcher
Exec=bash -c "$app_path/HabboLauncher.sh %u"
StartupNotify=false
Terminal=true
Icon=$app_path/HabboLauncher.png
Categories=Game;
MimeType=x-scheme-handler/habbo;
_EOF_


        chmod +x "$LinuxDesktopPath" 
        chmod +x "$app_path/HabboLauncher.sh"

        cp -s "$LinuxDesktopPath" "$(xdg-user-dir DESKTOP)"
        
        set_habbo_url_protocol

    else
        echo "Error: unable to create desktop shortcut"
    fi

}


load_files(){
    echo "Setting app on: $app_path"
    mkdir -p "$app_path"
    
    cp HabboLauncher.sh "$app_path"
    cp HabboLauncher.png "$app_path"
    
}

load_files
set_habbo_desktop
load_heapcheck


