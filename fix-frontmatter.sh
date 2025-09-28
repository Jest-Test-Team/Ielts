#!/bin/bash

# Bash script to add frontmatter to markdown files that don't have it
# This script checks for .md files and adds Jekyll frontmatter if missing

# Define directories to process
directories=("01_Listening" "02_Reading" "03_Writing" "04_Speaking")

# Function to check if file has frontmatter
has_frontmatter() {
    local filepath="$1"
    head -1 "$filepath" | grep -q "^---$"
}

# Function to add frontmatter
add_frontmatter() {
    local filepath="$1"
    local title="$2"
    local layout="${3:-default}"
    
    # Create temporary file with frontmatter + original content
    {
        echo "---"
        echo "layout: $layout"
        echo "title: $title"
        echo "---"
        echo ""
        cat "$filepath"
    } > "${filepath}.tmp"
    
    mv "${filepath}.tmp" "$filepath"
    echo "✅ Added frontmatter to: $filepath"
}

# Function to get appropriate title
get_title() {
    local dir="$1"
    local filename="$2"
    
    case "$dir" in
        "01_Listening")
            case "$filename" in
                "strategy_notes") echo "聽力策略指南" ;;
                "error_log") echo "聽力錯誤記錄" ;;
                "pipeline") echo "聽力練習流程" ;;
                "cambridge-official-ielts-listening-test-resources") echo "劍橋 IELTS 聽力資源" ;;
                *) echo "聽力 - $filename" ;;
            esac
            ;;
        "02_Reading")
            case "$filename" in
                "strategy_notes") echo "閱讀策略指南" ;;
                "error_log") echo "閱讀錯誤記錄" ;;
                "vocabulary") echo "閱讀詞彙庫" ;;
                *) echo "閱讀 - $filename" ;;
            esac
            ;;
        "03_Writing")
            if [[ "$filename" =~ Task_1 ]]; then
                echo "寫作 Task 1 - $filename"
            elif [[ "$filename" =~ Task_2 ]]; then
                echo "寫作 Task 2 - $filename"
            elif [[ "$filename" =~ strategy ]]; then
                echo "寫作策略 - $filename"
            elif [[ "$filename" =~ practice ]]; then
                echo "寫作練習 - $filename"
            elif [[ "$filename" =~ error ]]; then
                echo "寫作錯誤 - $filename"
            else
                echo "寫作 - $filename"
            fi
            ;;
        "04_Speaking")
            case "$filename" in
                "phrases_and_idioms") echo "口說短語與慣用語" ;;
                "topic_practice_log") echo "口說話題練習記錄" ;;
                "active_recall_drills") echo "主動回想練習" ;;
                "analytistic") echo "口說分析" ;;
                *) echo "口說 - $filename" ;;
            esac
            ;;
        *) echo "$filename" ;;
    esac
}

# Process each directory
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "📁 Processing directory: $dir"
        
        # Find all .md files recursively
        while IFS= read -r -d '' file; do
            if ! has_frontmatter "$file"; then
                # Get filename without extension
                filename=$(basename "$file" .md)
                
                # Get appropriate title
                title=$(get_title "$dir" "$filename")
                
                add_frontmatter "$file" "$title"
            else
                echo "⏭️  Skipped (already has frontmatter): $file"
            fi
        done < <(find "$dir" -name "*.md" -type f -print0)
    fi
done

echo ""
echo "🎉 Frontmatter fix completed!"
echo "📝 Summary: Added Jekyll frontmatter to all markdown files missing it"
echo "🚀 Ready for Jekyll deployment!"
