#!/bin/bash

# File containing SoundCloud profile links
LIKES_FILE="likes.txt"
TIMEOUT_DURATION=300 # 5 minutes
SCDL_PID=""

# Function to handle cleanup on Ctrl + C
cleanup() {
    if [[ -n "$SCDL_PID" ]] && kill -0 "$SCDL_PID" 2>/dev/null; then
        echo "Stopping current download..."
        kill "$SCDL_PID"
        wait "$SCDL_PID" 2>/dev/null
    fi
    echo "Exiting script."
    exit 1
}

# Trap SIGINT (Ctrl + C) and call cleanup
trap cleanup SIGINT

# Check if scdl is installed
if ! command -v scdl &> /dev/null; then
    echo "scdl is not installed. Install it with: pip install scdl"
    exit 1
fi

# Check if the likes file exists
if [[ ! -f "$LIKES_FILE" ]]; then
    echo "File '$LIKES_FILE' not found!"
    exit 1
fi

# Read the file line by line and download likes
while IFS= read -r url; do
    if [[ -n "$url" ]]; then
        echo "Downloading likes from: $url"

        # Start scdl with timeout in the background
        timeout $TIMEOUT_DURATION scdl -l "$url" -f --path downloads --download-archive history.txt &
        SCDL_PID=$!

        echo "Press [s] to skip to the next user..."
        while kill -0 $SCDL_PID 2>/dev/null; do
            read -t 1 -n 1 key
            if [[ "$key" == "s" ]]; then
                echo "Skipping $url..."
                kill "$SCDL_PID"
                wait "$SCDL_PID" 2>/dev/null
                break
            fi
        done

        # Check if timeout was hit
        if [[ $? -eq 124 ]]; then
            echo "Timeout reached for $url. Moving to next user..."
        fi
    fi
done < "$LIKES_FILE"

echo "All downloads completed."
