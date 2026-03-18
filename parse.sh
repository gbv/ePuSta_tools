#!/bin/bash

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

# Default pipeline
DEFAULT_PIPELINE="log2epusta.php | addIdentifierMIR.php | filter.php"

show_help() {
    cat <<'HELP'
Usage: parse.sh [OPTIONS] [FILE...]
Parse access logfiles to ePuSta logfiles.

Options:
  -h, --help      Show this help message
  -f, --force     Force parsing even if destination is up to date
  -a, --append    Append mode: only process new lines from the access log.
                  Reads the UUID from the last line of the destination ePuSta
                  log, finds that UUID in the access log, and processes only
                  the lines that follow it. Output is appended to the
                  destination file.

Arguments:
  FILE...       Access logfiles to parse (supports glob patterns)
                If no files given, all files in ACCESSLOGDIR are processed.

Parse conditions (without --force):
  - Destination file does not exist
  - Source file has more lines than destination file

Configuration:
  Set PIPELINE in config file to customize the processing pipeline.
  Default: log2epusta.php | addIdentifierMIR.php | filter.php
HELP
}

# Count lines in a file, handling .gz transparently
count_lines() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo 0
        return
    fi
    if [[ "$file" == *.gz ]]; then
        zcat "$file" | wc -l
    else
        wc -l < "$file"
    fi
}

# Parse options
FORCE=0
APPEND=0
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        -a|--append)
            APPEND=1
            shift
            ;;
        --)
            shift
            FILES+=("$@")
            break
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            echo "Use --help for usage information." >&2
            exit 1
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# Load config and profile (after option parsing so --help works without config)
if [ ! -f "$SCRIPTDIR/config" ]; then
    echo "Error: Config file not found: $SCRIPTDIR/config" >&2
    echo "Copy config.template to config and set the values." >&2
    exit 1
fi
source "$SCRIPTDIR/config"
source ~/.profile

# If no files given, use all files in ACCESSLOGDIR
if [ ${#FILES[@]} -eq 0 ]; then
    for f in "$ACCESSLOGDIR"/*; do
        [ -f "$f" ] && FILES+=("$f")
    done
fi

# Determine pipeline
if [ -n "$PIPELINE" ]; then
    PIPE="$PIPELINE"
else
    PIPE="$DEFAULT_PIPELINE"
fi

# Process each file
for filename in "${FILES[@]}"; do
    if [ ! -f "$filename" ]; then
        echo "Warning: $filename not found, skipping."
        continue
    fi

    # Determine basename and uncompressed filename
    if [[ "$filename" == *.gz ]]; then
        basename="$(basename "$filename" .log.gz)"
        filename_uncompressed="${filename%.gz}"
    elif [[ "$filename" == *.log ]]; then
        basename="$(basename "$filename" .log)"
        filename_uncompressed="$filename"
    else
        echo "Warning: $filename has unexpected extension, skipping."
        continue
    fi

    destfile="$basename.epusta.log"
    destfile_gz="$basename.epusta.log.gz"
    destpath="$EPUSTALOGDIR/$destfile"
    destpath_gz="$EPUSTALOGDIR/$destfile_gz"

    # Find existing destination file
    existing_dest=""
    if [ -f "$destpath" ]; then
        existing_dest="$destpath"
    elif [ -f "$destpath_gz" ]; then
        existing_dest="$destpath_gz"
    fi

    # Append mode: only process lines after the last UUID in the destination
    if [ "$APPEND" -eq 1 ] && [ -n "$existing_dest" ]; then
        # Extract UUID from last line of destination
        if [[ "$existing_dest" == *.gz ]]; then
            last_line=$(zcat "$existing_dest" | tail -n 1)
        else
            last_line=$(tail -n 1 "$existing_dest")
        fi
        last_uuid=$(echo "$last_line" | cut -d' ' -f1)

        if [ -z "$last_uuid" ]; then
            echo "Warning: Could not extract UUID from last line of $existing_dest, skipping $filename."
            continue
        fi

        # Decompress source if needed
        was_compressed=0
        if [[ "$filename" == *.gz ]]; then
            was_compressed=1
            gzip -d "$filename"
        fi

        # Find the line number of the UUID in the access log
        uuid_line=$(grep -n "^${last_uuid} " "$filename_uncompressed" | tail -n 1 | cut -d: -f1)

        if [ -z "$uuid_line" ]; then
            echo "Warning: UUID $last_uuid not found in $filename, skipping."
            if [ "$was_compressed" -eq 1 ]; then
                gzip "$filename_uncompressed"
            fi
            continue
        fi

        start_line=$((uuid_line + 1))
        total_lines=$(wc -l < "$filename_uncompressed")

        if [ "$start_line" -gt "$total_lines" ]; then
            echo "Skipping: $filename (no new lines after UUID $last_uuid)"
            if [ "$was_compressed" -eq 1 ]; then
                gzip "$filename_uncompressed"
            fi
            continue
        fi

        new_lines=$((total_lines - uuid_line))
        echo "Appending: $filename ($new_lines new lines after UUID $last_uuid)"

        # Run pipeline on new lines only, append to destination
        eval "tail -n +${start_line} '$filename_uncompressed' | $PIPE" >> "$destpath"

        # Recompress source if it was compressed
        if [ "$was_compressed" -eq 1 ]; then
            gzip "$filename_uncompressed"
        fi

        echo "  -> $destpath (appended)"
        continue
    fi

    # Decide whether to parse
    if [ -n "$existing_dest" ] && [ "$FORCE" -eq 0 ]; then
        src_lines=$(count_lines "$filename")
        dest_lines=$(count_lines "$existing_dest")

        if [ "$src_lines" -le "$dest_lines" ]; then
            echo "Skipping: $filename (destination up to date, $dest_lines >= $src_lines lines)"
            continue
        fi
        echo "Reparsing: $filename ($src_lines lines > $dest_lines lines in destination)"
    elif [ -n "$existing_dest" ] && [ "$FORCE" -eq 1 ]; then
        echo "Force parsing: $filename"
    else
        echo "Parsing: $filename (new)"
    fi

    # Remove existing destination to avoid stale data
    [ -f "$destpath" ] && rm "$destpath"
    [ -f "$destpath_gz" ] && rm "$destpath_gz"

    # Decompress source if needed
    was_compressed=0
    if [[ "$filename" == *.gz ]]; then
        was_compressed=1
        gzip -d "$filename"
    fi

    # Run pipeline
    eval "cat '$filename_uncompressed' | $PIPE" > "$destpath"

    # Recompress source if it was compressed
    if [ "$was_compressed" -eq 1 ]; then
        gzip "$filename_uncompressed"
    fi

    echo "  -> $destpath"
done
