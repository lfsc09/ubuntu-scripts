#!/bin/bash
set -e

echo -e '\n'
echo '#######################################'
echo '## Audio Output Device Cycling Setup ##'
echo '#######################################'
echo -e '\n'

# Install dependencies if not already installed
if ! command -v pactl &> /dev/null || ! command -v notify-send &> /dev/null || ! command -v fzf &> /dev/null; then
  echo -e "\n⏳ Installing required packages for audio output device cycling..."
  sudo apt-get update > /dev/null
  sudo apt-get install -y fzf pulseaudio-utils libnotify-bin > /dev/null
  echo "✅ Audio output device cycling install completed."
fi

# Choose the devices to cycle through
config_file="$HOME/.config/cycle-output-devices.conf"
mkdir -p "$(dirname "$config_file")"

pactl list short sinks | awk '{print $2}' | \
fzf --multi --prompt="Select the audio output devices you want to cycle through: " \
  --header="Use TAB/SHIFT+TAB to select, ENTER to confirm" > "$config_file"

echo -e "\n✅ Setup complete! You can now use the cycle-output-devices script to switch between your selected audio output devices."
