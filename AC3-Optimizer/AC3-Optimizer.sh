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

    # Extract audio codec and channel count information
    AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$MOVIE")
    CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=nw=1:nk=1 "$MOVIE")

    # Define the output file path
    BASENAME=$(basename "$MOVIE")
    OUTPUT_MOVIE="$OUTPUT_DIR/${BASENAME%.*} (AC3).${EXT}"

    if [[ "$AUDIO_CODEC" == "eac3" || ( "$CHANNELS" -ge 6 && "$AUDIO_CODEC" != "ac3" ) ]]; then
        echo "E-AC3 or non-AC3 6+ channels detected. Converting to AC3 (6 channels)..."
        
        # Extract and convert audio to AC3 (6 channels)
        AUDIO_STREAM="$TEMP_DIR/audio.ac3"
        ffmpeg -i "$MOVIE" -vn -c:a ac3 -b:a 640k -ac 6 "$AUDIO_STREAM" -y

        # Merge video, converted audio, and subtitle streams
        ffmpeg -i "$MOVIE" -i "$AUDIO_STREAM" \
            -map 0:v -map 1:a -map 0:s? -map 0:t? \
            -c:v copy -c:a copy -c:s copy -c:t copy \
            "$OUTPUT_MOVIE" -y

        echo "Converted and saved: $OUTPUT_MOVIE"

    elif [[ "$AUDIO_CODEC" == "ac3" && "$CHANNELS" -eq 6 ]]; then
        echo "AC3 with 6 channels detected. No conversion needed."
        cp "$MOVIE" "$OUTPUT_MOVIE"
        echo "Saved: $OUTPUT_MOVIE"

    else
        echo "Audio codec is not E-AC3, AC3 (6 channels), or 6+ channels. Moving without modification."
        mv "$MOVIE" "$OUTPUT_DIR/"
    fi
done

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "Processing complete!"

