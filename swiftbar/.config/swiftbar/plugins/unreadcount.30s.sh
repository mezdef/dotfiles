#!/bin/bash

app_names=(
    "Messages"
    "Beeper Desktop"
    "Slack"
    "Microsoft Outlook"
)

# UTIL - Encode to base64
encode_config() {
    echo "$1" | base64 | tr -d '\n'
}

# SET - App name based on unread count
get_app() {
    local messages_count="$1"
    local beeper_count="$2"
    local slack_count="$3"
    local outlook_count="$4"

    if [ "$messages_count" -gt 0 ]; then
        echo "Messages"
    elif [ "$beeper_count" -gt 0 ]; then
        echo "Beeper Desktop"
    elif [ "$slack_count" -gt 0 ]; then
        echo "Slack"
    elif [ "$outlook_count" -gt 0 ]; then
        echo "Microsoft Outlook"
    else
        echo "None"
    fi
}

# SET - Icon based on app name
get_icon() {
    local current_app="$1"

    if [ "$current_app" = "Messages" ]; then
        echo "message.badge.filled.fill"
    elif [ "$current_app" = "Beeper Desktop" ]; then
        echo "message.badge"
    elif [ "$current_app" = "Slack" ]; then
        echo "number.square"
    elif [ "$current_app" = "Microsoft Outlook" ]; then
        echo "envelope.badge"
    else
        echo "circle.slash"
    fi
}

# GET - Count for specific app by name
get_count_for_app() {
    local app_name="$1"

    case "$app_name" in
        "Messages")
            echo "$messages_count"
            ;;
        "Beeper Desktop")
            echo "$beeper_count"
            ;;
        "Slack")
            echo "$slack_count"
            ;;
        "Microsoft Outlook")
            echo "$outlook_count"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# SET - Icon config based on app name
get_icon_config() {
    local current_app="$1"
    local count="${2:-1}"  # Default to 1 if not provided (for backwards compatibility)

    local color="white"
    if [ "$count" -eq 0 ]; then
        color="gray"
    fi

    case "$current_app" in
        "Messages"|"Beeper Desktop"|"Slack"|"Microsoft Outlook")
            encode_config "{\"renderingMode\":\"Palette\", \"colors\":[\"$color\"], \"scale\": \"medium\", \"weight\": \"bold\"}"
            ;;
        *)
            encode_config '{"renderingMode":"Palette", "colors":["gray"], "scale": "medium", "weight": "bold"}'
            ;;
    esac
}

# Function to get unread count from dock badge
get_unread_count() {
    local app_name="$1"
    local count=$(osascript -e "
    tell application \"System Events\"
        tell process \"Dock\"
            set dockItems to UI elements of list 1
            repeat with dockItem in dockItems
                if name of dockItem is \"$app_name\" then
                    try
                        set badgeValue to value of attribute \"AXStatusLabel\" of dockItem
                        return badgeValue
                    on error
                        return \"0\"
                    end try
                end if
            end repeat
            return \"0\"
        end tell
    end tell
    " 2>/dev/null | grep -o '[0-9]\+' | head -1)
    
    if [ -z "$count" ]; then
        count=0
    fi
    echo "$count"
}

# Get unread counts for each app
messages_count=$(get_unread_count "Messages")
beeper_count=$(get_unread_count "Beeper Desktop")
slack_count=$(get_unread_count "Slack")
outlook_count=$(get_unread_count "Microsoft Outlook")

# Calculate total count
total_count=$((messages_count + beeper_count + slack_count + outlook_count))
current_app=$(get_app "$messages_count" "$beeper_count" "$slack_count" "$outlook_count")
current_icon=$(get_icon "$current_app")
current_icon_config=$(get_icon_config "$current_app")

# Display with priority: Messages > Beeper > Slack > Outlook (show only one icon)
if [ "$current_app" = "None" ]; then
    echo "| sfimage='$current_icon' sfconfig='$current_icon_config'"
else
    echo "$total_count | sfimage='$current_icon' sfconfig='$current_icon_config'"
fi

# Add dropdown rows for each app (always show when total_count > 0)
if [ "$total_count" -gt 0 ]; then
    echo "---"
    for app in "${app_names[@]}"; do
        app_count=$(get_count_for_app "$app")
        app_icon=$(get_icon "$app")
        app_icon_config=$(get_icon_config "$app" "$app_count")
        echo "$app: $app_count | sfimage='$app_icon' sfconfig='$app_icon_config' bash='open -a \"$app\"' terminal=false"
    done
fi