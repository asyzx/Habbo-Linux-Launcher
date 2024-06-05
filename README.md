# Habbo-Linux-Launcher

You can launch the habbo client using 3 methods:

- `Native`: make a Habbo Flash for Linux using AdobeAIR SDK and runs natively.
- `Classic`: download the Habbo Flash for Windows and runs using Wine.
- `Modern`:  download the Habbo Unity for Windows and runs using Wine.

### Installing on Debian based distros

1. Download the lastest deb package from [release](https://github.com/asyzx/Habbo-Linux-Launcher/releases)
2. Double click or type the following commands in the terminal: `sudo dpkg -i HabboLauncher_version_arch.deb`

### Installing Manually

1. Make sure you have installed `unzip wget wine dialog xdg-utils`
2. Type the following commands in the terminal:
  ```bash
  git clone https://github.com/asyzx/Habbo-Linux-Launcher && cd Habbo-Linux-Launcher
  bash ./install.sh
  ```
