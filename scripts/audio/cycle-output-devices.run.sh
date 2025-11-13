#!/bin/bash

# Get a list of all sink names
SINK_NAMES=($(pactl list short sinks | awk '{print $2}'))

# Check the config file for selected sinks
CONFIG_FILE="$HOME/.config/cycle-output-devices.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
  notify-send "Cycle Output Devices - Error" "Configuration file not found! Please run the setup script first." -i audio-speakers -h string:transient:true
  exit 1
fi

# Read the selected sinks from the config file
mapfile -t SELECTED_SINKS < "$CONFIG_FILE"

# Check if all the selected sinks are valid
for SINK in "${SELECTED_SINKS[@]}"; do
  if [[ ! " ${SINK_NAMES[*]} " =~ " ${SINK} " ]]; then
    notify-send "Cycle Output Devices - Error" "Selected sink '$SINK' is not a valid sink. Please run the setup script again." -i audio-speakers -h string:transient:true
    exit 1
  fi
done

# Get the current default sink name
CURRENT_SINK=$(pactl info | grep 'Default Sink:' | awk '{print $3}')

# If the current sink is not in the selected list, set to the first selected sink
if [[ ! " ${SELECTED_SINKS[*]} " =~ " ${CURRENT_SINK} " ]]; then
  pactl set-default-sink "${SELECTED_SINKS[0]}"
  DEVICE_DESCRIPTION=$(pactl list sinks | grep -A 100 "Name: ${SELECTED_SINKS[0]}" | grep "Description:" | awk '{$1=""; print $0}' | xargs)
  notify-send "Audio Output Switched" "$DEVICE_DESCRIPTION" -i audio-speakers -h string:transient:true
  exit 0
fi

# Get the index of the current sink in the selected sinks array
CURRENT_INDEX=-1
for i in "${!SELECTED_SINKS[@]}"; do
  if [[ "${SELECTED_SINKS[$i]}" == "${CURRENT_SINK}" ]]; then
    CURRENT_INDEX=${i}
    break
  fi
done

# Calculate the index of the next sink (cycle back to 0 if at the end)
NEXT_INDEX=$(((CURRENT_INDEX + 1) % ${#SELECTED_SINKS[@]}))
NEXT_SINK_NAME=${SELECTED_SINKS[$NEXT_INDEX]}

# Set the new default sink
pactl set-default-sink "$NEXT_SINK_NAME"

# Move all active streams to the new sink (optional, but ensures active apps switch)
# In newer Ubuntu versions (22.04+), this might be automatic
pactl list short sink-inputs | while read -r line; do
  input_index=$(echo "$line" | awk '{print $1}')
  pactl move-sink-input "$input_index" "$NEXT_SINK_NAME"
done

DEVICE_DESCRIPTION=$(pactl list sinks | grep -A 100 "Name: $NEXT_SINK_NAME" | grep "Description:" | awk '{$1=""; print $0}' | xargs)
notify-send "Audio Output Switched" "$DEVICE_DESCRIPTION" -i audio-speakers -h string:transient:true