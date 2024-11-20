#!/bin/bash

# Directories
INPUT_DIR="movies"           # Input directory containing movie files
OUTPUT_DIR="output"          # Output directory for processed movies
TEMP_DIR="temp_audio"        # Temporary directory for intermediate files

# Create directories if not exist
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

# Supported movie extensions
MOVIE_EXT=("mkv" "mp4" "avi")

# Process each movie file in the input directory
for MOVIE in "$INPUT_DIR"/*; do
    # Check if the file has a valid movie extension
    EXT="${MOVIE##*.}"
    if [[ ! " ${MOVIE_EXT[@]} " =~ " ${EXT} " ]]; then
        echo "Skipping non-movie file: $MOVIE"
        continue
    fi

    echo "Processing: $MOVIE"

    # Define the output file path
    BASENAME=$(basename "$MOVIE")
    OUTPUT_MOVIE="$OUTPUT_DIR/${BASENAME%.*} (AC3).${EXT}"

    # Extract information about audio streams
    MAP_AUDIO_STREAMS=()
    STREAM_INDEX=0
    CONVERT_NEEDED=false
    while IFS= read -r STREAM_INFO; do
        AUDIO_CODEC=$(echo "$STREAM_INFO" | cut -d, -f1)
        CHANNELS=$(echo "$STREAM_INFO" | cut -d, -f2)

        if [[ "$AUDIO_CODEC" == "eac3" || "$CHANNELS" -gt 6 || ( "$CHANNELS" -ge 6 && "$AUDIO_CODEC" != "ac3" ) ]]; then
            echo "Audio stream $STREAM_INDEX: Conversion needed (codec=$AUDIO_CODEC, channels=$CHANNELS)."
            # Convert this stream to AC3 (6 channels)
            AUDIO_OUTPUT="$TEMP_DIR/audio_$STREAM_INDEX.ac3"
            ffmpeg -i "$MOVIE" -map 0:a:$STREAM_INDEX -c:a ac3 -b:a 640k -ac 6 "$AUDIO_OUTPUT" -y
            MAP_AUDIO_STREAMS+=("-map $AUDIO_OUTPUT")
            CONVERT_NEEDED=true
        else
            echo "Audio stream $STREAM_INDEX: Compatible. Copying without changes."
            MAP_AUDIO_STREAMS+=("-map 0:a:$STREAM_INDEX")
        fi
        STREAM_INDEX=$((STREAM_INDEX + 1))
    done < <(ffprobe -v error -show_entries stream=index,codec_name,channels -select_streams a \
               -of csv=p=0 "$MOVIE")

    # Build the final FFmpeg command
    if [[ "$CONVERT_NEEDED" == true ]]; then
        echo "Merging converted audio streams with video and subtitles..."
        ffmpeg -i "$MOVIE" "${MAP_AUDIO_STREAMS[@]}" \
            -map 0:v -map 0:s? -map 0:t? \
            -c:v copy -c:s copy -c:t copy \
            "$OUTPUT_MOVIE" -y
        echo "Converted and saved: $OUTPUT_MOVIE"
    else
        echo "No incompatible audio streams found. Copying original file."
        cp "$MOVIE" "$OUTPUT_MOVIE"
    fi
done

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete!"
