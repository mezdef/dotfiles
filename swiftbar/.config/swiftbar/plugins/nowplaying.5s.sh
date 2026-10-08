#!/bin/bash

# <xbar.title>Now playing</xbar.title>
# <xbar.version>v1.1</xbar.version>
# <xbar.author>Adam Kenyon</xbar.author>
# <xbar.author.github>adampk90</xbar.author.github>
# <xbar.desc>Shows and controls the music that is now playing. Currently supports Spotify, iTunes, Vox, and web browsers (Safari, Chrome, etc.) via media-control.</xbar.desc>
# <xbar.image>https://pbs.twimg.com/media/CbKmTS7VAAA84VS.png:small</xbar.image>
# <xbar.dependencies>media-control</xbar.dependencies>
# <xbar.abouturl></xbar.abouturl>

# Cache directory
CACHE_DIR="$HOME/.cache/swiftbar-nowplaying"

# Check if media-control is available
if ! command -v media-control &> /dev/null; then
    echo "⚠️ media-control not found | color=red"
    echo "---"
    echo "Install media-control: brew install media-control | bash='open' param1='https://github.com/ungive/media-control' terminal=false"
    exit 1
fi

# UTIL - ENCODE JSON CONFIG TO BASE64
encode_config() {
    echo "$1" | base64 | tr -d '\n'
}

# Function to detect media using media-control library
detect_media_control() {
    # Get current media information
    local media_json=$(media-control get 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$media_json" ]; then
        return 1
    fi
    
    # Parse JSON to extract all fields in one call, using a separator that won't conflict
    local json_output=$(echo "$media_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    title = data.get('title', '').replace('\\x1f', ' ')
    artist = data.get('artist', '').replace('\\x1f', ' ')
    album = data.get('album', '').replace('\\x1f', ' ')
    bundle_id = data.get('bundleIdentifier', '').replace('\\x1f', ' ')
    is_playing = 'true' if data.get('playing', False) else 'false'
    print(f'{title}\\x1f{artist}\\x1f{album}\\x1f{bundle_id}\\x1f{is_playing}')
except:
    print('\\x1f\\x1f\\x1f\\x1ffalse')
" 2>/dev/null)
    
    IFS=$'\x1f' read -r title artist album bundle_id is_playing <<< "$json_output"
    
    # Only return data if we have at least a title
    if [ -n "$title" ] && [ "$title" != "" ]; then
        # Map bundle identifier to app name
        local app_name="Unknown"
        case "$bundle_id" in
            "company.thebrowser.Browser")
                app_name="Arc"
                ;;
            "com.apple.Safari")
                app_name="Safari"
                ;;
            "com.google.Chrome")
                app_name="Chrome"
                ;;
            "org.mozilla.firefox")
                app_name="Firefox"
                ;;
            "app.zen-browser.zen")
                app_name="Zen"
                ;;
            "com.spotify.client")
                app_name="Spotify"
                ;;
            "com.apple.Music")
                app_name="Music"
                ;;
            "com.coppertino.Vox")
                app_name="Vox"
                ;;
            "fm.overcast.overcast")
                app_name="Overcast"
                ;;
            *)
                # Extract app name from bundle identifier
                app_name=$(echo "$bundle_id" | awk -F'.' '{print $NF}' | sed 's/^./\U&/')
                ;;
        esac
        
        echo "$app_name"$'\x1f'"$title"$'\x1f'"$artist"$'\x1f'"$album"$'\x1f'"$is_playing"
        return 0
    fi
    
    return 1
}

# Function to truncate text to 30 characters
truncate_text() {
    echo "$1" | python3 -c "
import sys
text = sys.stdin.read().strip()
if len(text) > 30:
    print(text[:30] + '...')
else:
    print(text)
" 2>/dev/null
}

# Generic function to resize image and convert to base64
# Usage: resize_image_to_base64 <source_path_or_data> <max_size> <cache_name> [is_base64_data]
resize_image_to_base64() {
    local source="$1"
    local max_size="$2"
    local cache_name="$3"
    local is_base64_data="$4"
    
    mkdir -p "$CACHE_DIR"
    local original_path="$CACHE_DIR/${cache_name}_original"
    local resized_path="$CACHE_DIR/${cache_name}_resized"
    
    # Handle source data (either file path or base64 data)
    if [ "$is_base64_data" = "true" ]; then
        # Source is base64 data, decode it to file
        echo "$source" | base64 -d > "$original_path" 2>/dev/null
    else
        # Source is file path, copy it
        cp "$source" "$original_path" 2>/dev/null
    fi
    
    # Create square artwork with gray background if original exists
    if [ -f "$original_path" ] && [ -s "$original_path" ]; then
        local square_path="$CACHE_DIR/${cache_name}_square"
        local temp_resized_path="$CACHE_DIR/${cache_name}_temp_resized"
        
        # Resize artwork to fit within the square bounds using sips
        sips -Z "$max_size" "$original_path" --out "$temp_resized_path" >/dev/null 2>&1
        
        if [ -f "$temp_resized_path" ] && [ -s "$temp_resized_path" ]; then
            # Try to create square using sips padding, but with fallback
            sips --padColor E6E6E6 --padToHeightWidth "$max_size" "$max_size" "$temp_resized_path" --out "$square_path" >/dev/null 2>&1
            
            # Check if the result is actually square, if not, fall back to simple copy
            if [ -f "$square_path" ]; then
                local check_dim=$(sips -g pixelWidth -g pixelHeight "$square_path" 2>/dev/null | grep "pixel" | awk '{print $2}' | tr '\n' ' ')
                local width=$(echo $check_dim | awk '{print $1}')
                local height=$(echo $check_dim | awk '{print $2}')
                
                if [ "$width" != "$max_size" ] || [ "$height" != "$max_size" ]; then
                    # Padding didn't work, just copy the resized image
                    cp "$temp_resized_path" "$square_path" 2>/dev/null
                fi
            else
                # Padding command failed, just copy the resized image
                cp "$temp_resized_path" "$square_path" 2>/dev/null
            fi
            
            # Clean up temporary resized file
            rm -f "$temp_resized_path" 2>/dev/null
            
            if [ -f "$square_path" ] && [ -s "$square_path" ]; then
                # Convert square artwork to base64
                base64 -i "$square_path" 2>/dev/null | tr -d '\n'
            else
                # Fallback to original resizing method
                sips -Z "$max_size" "$original_path" --out "$resized_path" >/dev/null 2>&1
                if [ -f "$resized_path" ] && [ -s "$resized_path" ]; then
                    base64 -i "$resized_path" 2>/dev/null | tr -d '\n'
                else
                    base64 -i "$original_path" 2>/dev/null | tr -d '\n'
                fi
            fi
        else
            # Fallback to original if resize failed
            base64 -i "$original_path" 2>/dev/null | tr -d '\n'
        fi
    fi
}

# Function to get appropriate SF symbol based on app name and content
get_icon() {
    local playing="$1"
    local media_detected="$2"

    if [ "$media_detected" = false ]; then
        echo "waveform.slash"
    elif [ "$playing" = false ]; then
        echo "waveform.badge.exclamationmark"
    else
        echo "waveform"
    fi
}

# BUILD SFIMAGE ICON CONFIG BASED ON APP
get_icon_config() {
    local app_name="$1"
    local icon_media="$2"
    local app_sub_name="$3"
    local playing="$4"

    # Handle no media case
    if [ -z "$app_name" ] || [ "$icon_media" = "waveform.slash" ]; then
        encode_config '{"renderingMode":"Palette", "colors":["gray"], "scale": "large", "weight": "bold" }'
        return
    fi

    # Paused
    if [ "$playing" = false ]; then
        encode_config '{"renderingMode":"Palette", "colors":["gray"], "scale": "large", "weight": "bold"}'
        return
    fi
 

    case "$app_name" in
        "Spotify")
            encode_config '{"renderingMode":"Palette", "colors":["green"], "scale": "large", "weight": "bold"}'
            ;;
        "Arc" | "Safari" | "Chrome" | "Firefox" | "Zen")
            # For browsers, detect content source based on app_sub_name
            if [ "$app_sub_name" = "Overcast" ]; then
                encode_config '{"renderingMode":"Palette", "colors":["orange"], "scale": "large", "weight": "bold"}'
            else
                # YouTube content
                encode_config '{"renderingMode":"Palette", "colors":["red"], "scale": "large", "weight": "bold"}'
            fi
            ;;
        "YouTube")
            encode_config '{"renderingMode":"Palette", "colors":["red"], "scale": "large", "weight": "bold"}'
            ;;
        "Music")
            encode_config '{"renderingMode":"Palette", "colors":["purple"], "scale": "large", "weight": "bold"}'
            ;;
        "Vox")
            encode_config '{"renderingMode":"Palette", "colors":["blue"], "scale": "large", "weight": "bold"}'
            ;;
        "Overcast")
            encode_config '{"renderingMode":"Palette", "colors":["orange"], "scale": "large", "weight": "bold"}'
            ;;
        *)
            encode_config '{"renderingMode":"Palette", "colors":["white"], "scale": "large", "weight": "bold"}'
            ;;
    esac
}

# Function to get and resize artwork for current song
get_artwork() {
    # Get artwork data from media-control
    local artwork_data=$(media-control get 2>/dev/null | jq -r '.artworkData // empty' 2>/dev/null)
    
    if [ -n "$artwork_data" ] && [ "$artwork_data" != "null" ] && [ "$artwork_data" != "" ]; then
        # Create cache name based on app name (lowercase)
        local app_filename=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
        # Use generic function to resize artwork to 160px
        resize_image_to_base64 "$artwork_data" 160 "${app_filename}_artwork.jpg" true
    fi
}

# Function to cache and manage media info per app
cache_media_info() {
    mkdir -p "$CACHE_DIR"
    
    # Get current media info
    local current_info=$(detect_media_control)
    if [ $? -eq 0 ] && [ -n "$current_info" ]; then
        IFS=$'\x1f' read -r current_app current_title current_artist current_album current_playing <<< "$current_info"
        
        # Cache this app's info separately
        local app_cache_file="$CACHE_DIR/${current_app}_cache"
        echo "$current_app|$current_title|$current_artist|$current_album|$current_playing|$(date +%s)" > "$app_cache_file"
        echo "$current_info"
        return 0
    fi
    
    return 1
}


# Get current media information using cache system
media_info=$(cache_media_info)
media_detected=$?

# Store media info for use throughout the script
if [ $media_detected -eq 0 ]; then
	IFS=$'\x1f' read -r app_name track_title artist_name album_name is_playing <<< "$media_info"
	
	# Store original title for icon detection before parsing
	original_title="$track_title"
	
	# Special handling for Overcast podcasts in Arc
	if [ "$app_name" = "Arc" ] && [ -z "$artist_name" ] && [[ "$track_title" == *" — Overcast" ]]; then
		# Extract artist from title format: "Episode Title — Podcast Name — Overcast"
		temp_title="${track_title% — Overcast}"  # Remove " — Overcast" suffix
		if [[ "$temp_title" == *" — "* ]]; then
			# Split on the last " — " separator (em dash)
			artist_name="${temp_title##* — }"  # Podcast name (everything after last " — ")
			track_title="${temp_title% — *}"   # Episode title (everything before last " — ")
		fi
	fi
	
	# Special handling for YouTube content in browsers with pipe-separated titles
	if [ "$app_name" = "Zen" ] && [[ "$track_title" == *" | "* ]]; then
		# For YouTube content, the title often contains: "Track Title | Artist Name | Additional Info"
		# Extract the first part as track title and second part as artist name
		if [[ "$track_title" == *" | "* ]]; then
			# Get the first part as track title
			first_part="${track_title%% | *}"
			# Get everything after the first " | "
			remaining="${track_title#* | }"
			# Get the next part as artist name (before the next " | " if exists)
			if [[ "$remaining" == *" | "* ]]; then
				artist_name="${remaining%% | *}"
			else
				artist_name="$remaining"
			fi
			track_title="$first_part"
		fi
	fi
	
	# APP_SUB_NAME for browsers
	app_sub_name=""
	case "$app_name" in
		"Arc" | "Safari" | "Chrome" | "Firefox" | "Zen")
			# Detect service based on content
			if [[ "$original_title" == *" — Overcast" ]]; then
				app_sub_name="Overcast"
			else
				# Default to YouTube for other browser content
				app_sub_name="YouTube"
			fi
			;;
	esac
	
	# Create shortened versions (max 30 characters)
	track_title_short=$(truncate_text "$track_title")
	artist_name_short=$(truncate_text "$artist_name")
	# Get and resize artwork
	artwork_base64=$(get_artwork)
else
	app_name=""
	track_title=""
	artist_name=""
	track_title_short=""
	artist_name_short=""
	album_name=""
	is_playing="false"
	artwork_base64=""
	app_sub_name=""
fi

# open a specified app
if [ "$1" = "open" ]; then
	# Handle special browser cases
	case "$2" in
		"Chrome")
			osascript -e "tell application \"Google Chrome\" to activate"
			;;
		*)
			osascript -e "tell application \"$2\" to activate"
			;;
	esac
	exit
fi

# Handle media controls using media-control
if [ "$1" = "play" ]; then
	media-control play
	sleep 0.1  # Delay refresh by 100ms
	exit
elif [ "$1" = "pause" ]; then
	media-control pause
	sleep 0.1  # Delay refresh by 100ms
	exit
elif [ "$1" = "toggle-play-pause" ]; then
	media-control toggle-play-pause
	sleep 0.1  # Delay refresh by 100ms
	exit
elif [ "$1" = "next" ]; then
	media-control next-track
	sleep 0.1  # Delay refresh by 100ms
	exit
elif [ "$1" = "previous" ]; then
	media-control previous-track
	sleep 0.1  # Delay refresh by 100ms
	exit
fi

# BUILD DISPLAY COMPONENTS

# SET - ICON BASED ON MEDIA SOURCE AND STATUS
icon_media=$(get_icon "$is_playing" "$media_detected")
icon_config=$(get_icon_config "$app_name" "$icon_media" "$app_sub_name" "$is_playing")

# BUILD - main title line
if [ $media_detected -ne 0 ] || [ -z "$track_title" ] || [ "$is_playing" = "false" ]; then
    main_title_line=" | sfimage='$icon_media' sfconfig='$icon_config'"
else
    main_title_line="$track_title_short — $artist_name_short | sfimage='$icon_media' sfconfig='$icon_config'"
fi

# SET status icon
if [ "$is_playing" = "true" ]; then
    status_icon=":play.fill:"
else
    status_icon=":pause.fill:"
fi

# SET image source - prefer artwork, fallback to SF symbol
if [ -n "$artwork_base64" ] && [ "$artwork_base64" != "" ] && [ "$artwork_base64" != "null" ]; then
    image_source="$artwork_base64"
    use_sfimage=""
else
    image_source=""
    use_sfimage="$icon_media"
fi

# Build app display
if [ -n "$app_sub_name" ]; then
    app_display="$app_sub_name ($app_name)"
else
    app_display="$app_name"
fi

# Build media source cluster
if [ -n "$image_source" ]; then
    media_source_cluster="$track_title_short\n$artist_name_short\n$status_icon $app_display | image=$image_source bash='$0' param1=toggle-play-pause refresh=true terminal=false"
elif [ -n "$use_sfimage" ]; then
    media_source_cluster="$track_title_short\n$artist_name_short\n$status_icon $app_display | sfimage='$use_sfimage' sfconfig='$icon_config' bash='$0' param1=toggle-play-pause refresh=true terminal=false"
else
    media_source_cluster="$track_title_short\n$artist_name_short\n$status_icon $app_display | bash='$0' param1=toggle-play-pause refresh=true terminal=false"
fi

# Build media controls
if [ "$is_playing" = "true" ]; then
    play_pause_control=":playpause.fill: Pause | bash='$0' param1=pause refresh=true terminal=false"
else
    play_pause_control=":playpause.fill: Play | bash='$0' param1=play refresh=true terminal=false"
fi

previous_control=":backward.end.alt.fill: Previous | bash='$0' param1=previous refresh=true terminal=false"
next_control=":forward.end.alt.fill: Next | bash='$0' param1=next refresh=true terminal=false"
open_app_control="Open $app_name | bash='$0' param1=open param2=$app_name terminal=false"

# BUILD - COMPONENT LAYOUT
if [ $media_detected -ne 0 ] || [ -z "$track_title" ]; then
	echo "$main_title_line"
else
	echo "$main_title_line"
	echo "---"
	echo "$media_source_cluster"
	echo "---"
	echo "$previous_control"
	echo "$play_pause_control"
	echo "$next_control"
	echo "---"
	echo "$open_app_control"
fi
