### **Batch Audio Conversion for Media Files**

This script is designed to handle batch audio conversion for movie files, ensuring compatibility with audio systems that support **AC3 (Dolby Digital)** up to 6 channels. It processes files with incompatible audio formats such as **E-AC3**, **DTS**, and other multi-channel formats, converting them to AC3 while preserving all other media components, including video, subtitles, and metadata.

---

### **Features**

1. **Multi-Audio Stream Support**:
    - Detects and processes multiple audio streams within a file.
    - Converts only incompatible audio streams while retaining compatible ones.
2. **Channel Downmixing**:
    - Audio streams with more than 6 channels (e.g., 7.1 surround) are downmixed to **6 channels (5.1 surround)**.
3. **Audio Format Conversion**:
    - Converts audio formats like **E-AC3**, **DTS**, or **TrueHD** to **AC3** for compatibility.
4. **Subtitles and Metadata**:
    - Retains subtitles, chapters, and other metadata.
5. **File Renaming**:
    - Appends **"(AC3)"** to the filename for processed files.
6. **Batch Processing**:
    - Processes all supported movie files in a specified input directory.
7. **Output Directory**:
    - Saves processed files in a designated output folder.

---

### **Requirements**

1. **Dependencies**:
    - [FFmpeg](https://ffmpeg.org/): A powerful multimedia framework for handling audio and video files.
    - Bash (Linux/macOS) or WSL (Windows Subsystem for Linux).
2. **Supported Movie Extensions**:
    - `.mkv`, `.mp4`, `.avi` (can be customized in the script).

---

### **Usage Instructions**

1. **Clone the Repository**:
    
    ```bash
    git clone https://github.com/gskumar-lab/fun-projects.git
    cd audio-conversion-script
    
    ```
    
2. **Place Your Movie Files**:
    - Place all movie files to be processed in the `movies/` directory.
3. **Run the Script**:
    
    ```bash
    ./convert_audio.sh
    
    ```
    
4. **Find Processed Files**:
    - Processed files will be available in the `output/` directory.

---

### **Script**

Here’s the complete script:

```bash
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

```

---

### **How It Works**

1. **Audio Analysis**:
    - Uses `ffprobe` to analyze all audio streams in the file.
    - Detects codec (`eac3`, `ac3`, etc.) and the number of channels.
2. **Conversion Rules**:
    - Converts incompatible audio (e.g., E-AC3, 7.1 channels) to AC3 (5.1 channels).
    - Copies compatible audio streams as-is.
3. **Stream Merging**:
    - Combines video, converted audio, subtitles, and other metadata into a single output file.
4. **Output File Naming**:
    - Appends **"(AC3)"** to filenames after processing.

---

### **Contribute**

Feel free to contribute to this project by submitting issues or pull requests. Suggestions for improvements, additional format handling, or new features are always welcome!