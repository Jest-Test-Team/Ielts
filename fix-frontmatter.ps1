# PowerShell script to add frontmatter to markdown files that don't have it
# This script checks for .md files and adds Jekyll frontmatter if missing

# Define directories to process
$directories = @("01_Listening", "02_Reading", "03_Writing", "04_Speaking")

# Function to check if file has frontmatter
function Has-Frontmatter {
    param($filepath)
    $content = Get-Content $filepath -Raw
    return $content.StartsWith("---")
}

# Function to add frontmatter
function Add-Frontmatter {
    param($filepath, $title, $layout = "default")
    
    $content = Get-Content $filepath -Raw
    $frontmatter = @"
---
layout: $layout
title: $title
---

$content
"@
    
    Set-Content $filepath $frontmatter -Encoding UTF8
    Write-Host "✅ Added frontmatter to: $filepath" -ForegroundColor Green
}

# Process each directory
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "📁 Processing directory: $dir" -ForegroundColor Yellow
        
        # Get all .md files recursively
        $mdFiles = Get-ChildItem -Path $dir -Filter "*.md" -Recurse
        
        foreach ($file in $mdFiles) {
            if (-not (Has-Frontmatter $file.FullName)) {
                # Generate title based on filename and directory
                $filename = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                
                # Create appropriate titles based on directory and filename
                $title = switch ($dir) {
                    "01_Listening" {
                        switch ($filename) {
                            "strategy_notes" { "聽力策略指南" }
                            "error_log" { "聽力錯誤記錄" }
                            "pipeline" { "聽力練習流程" }
                            "cambridge-official-ielts-listening-test-resources" { "劍橋 IELTS 聽力資源" }
                            default { "聽力 - $filename" }
                        }
                    }
                    "02_Reading" {
                        switch ($filename) {
                            "strategy_notes" { "閱讀策略指南" }
                            "error_log" { "閱讀錯誤記錄" }
                            "vocabulary" { "閱讀詞彙庫" }
                            default { "閱讀 - $filename" }
                        }
                    }
                    "03_Writing" {
                        if ($filename -match "Task_1") { "寫作 Task 1 - $filename" }
                        elseif ($filename -match "Task_2") { "寫作 Task 2 - $filename" }
                        elseif ($filename -match "strategy") { "寫作策略 - $filename" }
                        elseif ($filename -match "practice") { "寫作練習 - $filename" }
                        elseif ($filename -match "error") { "寫作錯誤 - $filename" }
                        else { "寫作 - $filename" }
                    }
                    "04_Speaking" {
                        switch ($filename) {
                            "phrases_and_idioms" { "口說短語與慣用語" }
                            "topic_practice_log" { "口說話題練習記錄" }
                            "active_recall_drills" { "主動回想練習" }
                            "analytistic" { "口說分析" }
                            default { "口說 - $filename" }
                        }
                    }
                    default { $filename }
                }
                
                Add-Frontmatter $file.FullName $title
            } else {
                Write-Host "⏭️  Skipped (already has frontmatter): $($file.FullName)" -ForegroundColor Gray
            }
        }
    }
}

Write-Host "`n🎉 Frontmatter fix completed!" -ForegroundColor Green
Write-Host "📝 Summary: Added Jekyll frontmatter to all markdown files missing it" -ForegroundColor Cyan
Write-Host "🚀 Ready for Jekyll deployment!" -ForegroundColor Magenta
