#!/bin/bash

LauncherArguments=$1
HabboClientName=""

github_page="https://github.com/asyzx/Habbo-Linux-Launcher"
adobe_air_url="https://airsdk.harman.com"

app_path="$HOME/.local/share/applications/HabboWine"

LocalClientVersionFile="$app_path/VERSION.txt"

LocalFlashVersion="0"
LocalUnityVersion="0"
LocalNativeVersion="1" # LocalNativeVersion needs to be different of LocalFlashVersion
LocalAdobeVersion="0"

if test -f "$LocalClientVersionFile"; then
    DataVersion=$(cat $LocalClientVersionFile)
    LocalVersions=(${DataVersion//;/ })
    LocalFlashVersion=${LocalVersions[0]}
    LocalUnityVersion=${LocalVersions[1]}
    LocalNativeVersion=${LocalVersions[2]}
    LocalAdobeVersion=${LocalVersions[3]}
fi


dialog --infobox "Checking updates for Habbo ..." 5 50

RemoteClientData=$(wget https://habbo.com/gamedata/clienturls -q -O -)

if [ $? -ne 0 ]; then
        dialog --colors --title "\Zb\Z1Error when checking updates for Habbo" --yesno "\nTry installing a new version of this launcher script or open a issue on \Zu$github_page\Zb\n\nWant to continue?" 9 60
    
    if [ $? -eq 0 ]; then
        RemoteFlashVersion=$LocalFlashVersion
        RemoteUnityVersion=$LocalUnityVersion
    else
        exit 
    fi
else
    RemoteFlashVersion=${RemoteClientData#*'"flash-windows-version":"'}
    RemoteFlashVersion=${RemoteFlashVersion%%'"'*}
    RemoteUnityVersion=${RemoteClientData#*'"unity-windows-version":"'}
    RemoteUnityVersion=${RemoteUnityVersion%%'"'*}
    echo $RemoteFlashVersion
    echo $RemoteUnityVersion
fi

update_version_file(){
    echo "$LocalFlashVersion;$LocalUnityVersion;$LocalNativeVersion;$LocalAdobeVersion" > $LocalClientVersionFile
}

show_error_continue(){
    
    ErroTitle=${1:-"Error"}
    ErroMsg=${2:-"Try installing a new version of this launcher script or open a issue on \Zu$github_page"}

    dialog --colors --title "\Zb\Z1$ErroTitle" --yesno "\n$ErroMsg\n\n\ZbWant to return?" 11 60
    if [ $? -ne 0 ]; then
        exit
    else
        show_initial_menu $LauncherArguments
    fi
}

show_downloading(){
    wget "$2" -O habbo_client.zip 2>&1 --progress=bar:force | dialog --progressbox "$1" 5 60
    
    if [ $? -ne 0 ]; then
        show_error_continue "Error when downloading a Habbo Client"
    else
        unzip -q -o habbo_client.zip -d "$3"
        rm habbo_client.zip
    fi
}

download_flash_version(){
    if [[ "$RemoteClientData" =~ \"flash-windows\":\"([^\"]+)\" ]]; then
        UrlFlashProgram="${BASH_REMATCH[1]}"
    else
        show_error_continue "Error parsing JSON of Habbo Client" "flash-windows not found on the JSON"
    fi

    show_downloading "Downloading Flash Client ..." "$UrlFlashProgram" "$app_path/HabboWin"
    
    LocalFlashVersion=$RemoteFlashVersion
    update_version_file   
}

download_unity_version(){
    if [[ "$RemoteClientData" =~ \"unity-windows\":\"([^\"]+)\" ]]; then
        UrlUnityProgram="${BASH_REMATCH[1]}"
    else
        show_error_continue "Error parsing JSON of Habbo Client" "unity-windows not found on the JSON"
    fi

    show_downloading "Downloading Unity Client ..." "$UrlUnityProgram" "$app_path"

    LocalUnityVersion=$RemoteUnityVersion 
    update_version_file
}


check_flash_version(){
    if [ "$RemoteFlashVersion" != "$LocalFlashVersion" ]; then
        download_flash_version
    fi
}

check_unity_version(){
    if [ "$RemoteUnityVersion" != "$LocalUnityVersion" ]; then
        download_unity_version
    fi
}

download_AdobeAIR_SDK(){
    wget --load-cookies cookies.txt "$1" -O adobe.zip 2>&1 --progress=bar:force | dialog --progressbox "Downloading Adobe AIR SDK ..." 5 60
    
    if [ $? -ne 0 ]; then
        show_error_continue "Error when downloading a new versions AdobeAIR"
    else
        unzip -q -o adobe.zip -d "$2"
        rm adobe.zip
        LocalAdobeVersion=$RemoteAdobeVersion
        update_version_file
    fi
    
}

check_download_AdobeAIR_SDK(){
    dialog --infobox "Checking version of Adobe AIR SDK ..." 5 50

    RemoteAdobeJsonInfo=$(wget --save-cookies cookies.txt --keep-session-cookies $adobe_air_url/api/config-settings/download -q -O -)

    if [ $? -ne 0 ]; then
        show_error_continue "Error when checking new versions of AdobeAIR"
        return
    else
        RemoteAdobeVersion=""
        UrlAdobeAIRSDK=""
        IdUrlAdobeAIRSDK=""

        if [[ "$RemoteAdobeJsonInfo" =~ \"supVersion\":\"([^\"]+)\" ]]; then
            RemoteAdobeVersion="${BASH_REMATCH[1]}"
        else
            show_error_continue "Error parsing JSON of AdobeAIR" "supVersion not found on the JSON"
        fi

        if [[ "$RemoteAdobeJsonInfo" =~ \"SDK_AS_LIN\":\"([^\"]+)\" ]]; then
            UrlAdobeAIRSDK="${BASH_REMATCH[1]}"
        else
            show_error_continue "Error parsing JSON of AdobeAIR" "SDK_AS_LIN not found on the JSON"
        fi

        if [[ "$RemoteAdobeJsonInfo" =~ \"id\":([0-9]+)\} ]]; then
            IdUrlAdobeAIRSDK="${BASH_REMATCH[1]}"
        else
            show_error_continue "Error parsing JSON of AdobeAIR" "id not found on the JSON"
        fi
        
        if [ "$RemoteAdobeVersion" != "$LocalAdobeVersion" ]; then
            download_AdobeAIR_SDK "$adobe_air_url$UrlAdobeAIRSDK?id=$IdUrlAdobeAIRSDK" "$app_path/AdobeAIR SDK"
            return $?
        fi
    fi
}

build_native_version(){
        dialog --infobox "Building Native Habbo Client ..." 5 50

        CertOutput=$($app_path/AdobeAIR\ SDK/bin/adt -certificate -cn SelfSign -ou QE -o 'Example, Co' -c US 2048-RSA newcert.p12 cert_password)

        BuildOutput=$($app_path/AdobeAIR\ SDK/bin/adt -package -storetype pkcs12 -keystore newcert.p12 -storepass cert_password -tsa http://timestamp.digicert.com -target bundle Native HabboWin/META-INF/AIR/application.xml -C HabboWin HabboAir.swf local_include icon16.png icon32.png icon48.png icon128.png icon256.png habbo_logo.png)

        if [ $? -eq 0 ]; then
           LocalNativeVersion=$RemoteFlashVersion
           update_version_file
           cp -R HabboWin/META-INF Native
        else
            show_error_continue "Error Building Native Client"
        fi
        
}

check_native_version(){
    if [ "$LocalNativeVersion" != "$LocalFlashVersion" ]; then

        if [ "$RemoteFlashVersion" != "$LocalFlashVersion" ]; then
            download_flash_version
        fi
        
        check_download_AdobeAIR_SDK

        build_native_version
    fi 
}

launch_classic_version(){
    execFile="$app_path/HabboWin/Habbo.exe"

    if ! [ -f $execFile ]; then
        LocalFlashVersion="0"
    fi

    check_flash_version
    nohup bash -c "wine '$execFile' $* &" >/dev/null 2>&1;
}

launch_unity_version(){
    
    execFile="$app_path/StandaloneWindows/habbo2020-global-prod.exe"

    if ! [ -f $execFile ]; then
        LocalUnityVersion="0"
    fi

    check_unity_version
    nohup bash -c "wine '$execFile' $* &" > /dev/null 2>&1;
}

launch_native_version(){
    
    execFile="$app_path/Native/Habbo"

    if ! [ -f $execFile ]; then
        LocalNativeVersion="1"
    fi

    check_native_version
    nohup bash -c "$app_path/Native/Habbo $* &" >/dev/null 2>&1;
}

show_initial_menu(){
    version_selected=$(
    dialog --backtitle "Habbo Launcher" \
    --title "Habbo Launcher" \
    --menu --stdout "Select a version of Habbo to play:" 19 50 3\
    Native    "Flash version running without Wine" \
    Classic   "Flash version running with Wine" \
    Modern    "Unity version running with Wine" )

    case $version_selected in
        Native)
            launch_native_version $*
        ;;
        Classic)
            launch_classic_version $*
        ;;
        Modern)
            launch_unity_version $*
        ;;
        *)
            exit
        ;;
    esac
}

check_arguments(){
    if [[ "$LauncherArguments" =~ server=([^\&]+)\&token=([^\.]+\.[^\.]+)\.([^\.]+) ]]; then
        LauncherServer=${BASH_REMATCH[1]}
        LauncherTicket=${BASH_REMATCH[2]}
        HabboClientName=${BASH_REMATCH[3]}
        LauncherArguments="-server $LauncherServer -ticket $LauncherTicket"
    else
        LauncherArguments=""
    fi
}

check_arguments
show_initial_menu $LauncherArguments
