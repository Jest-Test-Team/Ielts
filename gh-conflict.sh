#!/bin/bash

# ==============================================================================
# GitHub PR 自動合併與衝突處理腳本
#
# 功能:
# - 遍歷指定 GitHub 用戶的所有儲存庫。
# - 查找開啟的 Pull Requests。
# - 自動合併狀態為 "MERGEABLE" 的 PR。
# - 對於有衝突的 PR，提供互動式選項來處理。
# - 修正了在處理儲存庫名稱以連字號 `-` 開頭時，`cd` 命令會失敗的問題。
#
# 使用方法:
# 1. 確認已安裝 GitHub CLI (`gh`) 並且已經通過 `gh auth login` 登入。
# 2. 修改下面的 `BASE_REPO_DIR` 變數，使其指向您存放本地 Git 儲存庫的根目錄。
# 3. 賦予腳本執行權限: `chmod +x gh-conflict.sh`
# 4. 執行此腳本: `./gh-conflict.sh`
# 5. 非互動式執行: `./gh-conflict.sh --non-interactive` (遇到衝突時會自動選擇顯示步驟)
# ==============================================================================

# --- 設定 ---
# 請將此路徑修改為您存放本地 Git 儲存庫的根目錄
# 腳本會在此目錄下尋找與遠端儲存庫同名的資料夾
# 例如: 如果您的專案位於 ~/Documents/Projects/my-repo，請將此處設為 "~/Documents/Projects"
BASE_REPO_DIR="~/Documents/Untitled/AIoT"

# --- 顏色代碼 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- 函數定義 ---

# 顯示錯誤訊息並退出
function die() {
    echo -e "${RED}❌ 錯誤: $1${NC}" >&2
    exit 1
}

# 處理有衝突的 PR
function handle_conflicting_pr() {
    local repo="$1"
    local pr_number="$2"
    local pr_branch="$3"
    local expanded_base_repo_dir="$4"
    local non_interactive_mode="$5"

    echo -e "${YELLOW}⚠️  無法自動合併。狀態: CONFLICTING${NC}"
    echo -e "${YELLOW}⚠️  發現合併衝突，正在嘗試解決...${NC}"
    
    local repo_name
    repo_name=$(echo "$repo" | cut -d'/' -f2)
    local local_repo_dir="${expanded_base_repo_dir}/${repo_name}"
    
    echo -e "${BLUE}ℹ️  正在切換到正確的儲存庫: ${repo}${NC}"
    
    if [ ! -d "$local_repo_dir" ]; then
        echo -e "${YELLOW}⚠️  找不到本地儲存庫: ${local_repo_dir}。${NC}"
        echo -e "${YELLOW}   請確認您的 BASE_REPO_DIR 設定是否正確，以及儲存庫是否已克隆。${NC}"
        return
    fi

    echo -e "${BLUE}ℹ️  找到本地儲存庫: ${repo_name}${NC}"
    
    # --- 修正 ---
    # 使用 `cd --` 來確保即使目錄名稱以 `-` 開頭也能正常運作。
    # 這是原始腳本出錯的地方。
    if ! cd -- "$local_repo_dir"; then
        echo -e "${RED}❌ 切換到儲存庫失敗: ${local_repo_dir}${NC}"
        return
    fi
    # --- 修正結束 ---

    echo -e "${GREEN}✅ 成功切換到儲存庫: ${repo}${NC}"
    
    # 使用 `gh pr checkout` 會自動處理 fetch 和建立本地分支
    echo -e "${BLUE}ℹ️  正在 checkout PR #${pr_number} 以便處理衝突...${NC}"
    
    if ! gh pr checkout "$pr_number"; then
        echo -e "${RED}❌ checkout PR #${pr_number} 失敗。可能遠端分支已被刪除或有其他問題。${NC}"
        cd - > /dev/null # 返回原始目錄
        return
    fi

    echo -e "${YELLOW}⚠️  自動解決失敗，需要手動處理。${NC}"
    
    local choice
    if [ "$non_interactive_mode" = "true" ]; then
        echo -e "${BLUE}ℹ️  非互動模式：自動選擇選項 4。${NC}"
        choice=4
    else
        echo -e "${BLUE}   當前分支為 ${pr_branch}，您可以開始手動解決衝突。${NC}"
        echo ""
        echo -e "${BLUE}ℹ️  請選擇處理方式：${NC}"
        echo "1. 手動解決衝突（腳本將終止，讓您留在目前目錄處理）"
        echo "2. 跳過此 PR（將還原變更並切回主分支）"
        echo "3. 標記為需要人工處理（加上 'needs-manual-resolution' 標籤）"
        echo "4. 僅顯示手動解決步驟"
        read -r -p "請輸入選項 (1-4): " choice
    fi
    
    local main_branch
    main_branch=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
    
    case $choice in
        1)
            echo "✅  腳本已終止。請在目前終端機中手動解決衝突。"
            echo "   完成後，請手動 commit, push 並在 GitHub 上合併。"
            echo "   目前路徑: $(pwd)"
            exit 0
            ;;
        2)
            echo "ℹ️  已跳過 PR #${pr_number}。"
            git merge --abort > /dev/null 2>&1 || git reset --hard HEAD > /dev/null 2>&1
            git checkout "${main_branch}"
            ;;
        3)
            echo "ℹ️  正在標記 PR 為需要人工處理..."
            if gh pr edit "$pr_number" -R "$repo" --add-label "needs-manual-resolution"; then
                echo "✅ 已標記為: needs-manual-resolution"
            else
                echo "❌ 標記失敗。"
            fi
            git checkout "${main_branch}"
            ;;
        4)
            echo "ℹ️  顯示手動解決衝突的步驟："
            echo "1. cd -- \"${local_repo_dir}\""
            echo "2. gh pr checkout ${pr_number}"
            echo "3. git merge origin/${main_branch}"
            echo "4. (解決衝突後) git add . && git commit"
            echo "5. git push origin ${pr_branch}"
            git checkout "${main_branch}"
            ;;
        *)
            echo "無效的選項。將跳過此 PR。"
            git checkout "${main_branch}"
            ;;
    esac
    
    # 返回原始目錄
    cd - > /dev/null
}


# --- 主腳本 ---

# 檢查 gh 是否安裝
command -v gh >/dev/null 2>&1 || die "此腳本需要 GitHub CLI ('gh')。請先安裝。"

# 檢查 gh 是否登入
gh auth status >/dev/null 2>&1 || die "您尚未登入 GitHub CLI。請執行 'gh auth login'。"

# 處理非互動模式
NON_INTERACTIVE=false
if [ "$1" == "--non-interactive" ]; then
    NON_INTERACTIVE=true
fi

# 獲取 GitHub 用戶名
GITHUB_USER=$(gh api user --jq .login) || die "無法獲取 GitHub 用戶名。"

echo -e "${BLUE}🚀 GitHub PR 自動合併與衝突處理腳本${NC}"
if [ "$NON_INTERACTIVE" = "true" ]; then
    echo -e "${YELLOW}Running in non-interactive mode.${NC}"
fi
echo "=================================================="
echo -e "${BLUE}ℹ️  正在為用戶 ${GITHUB_USER} 檢查所有儲存庫...${NC}"

# 展開波浪號路徑
eval expanded_base_repo_dir=$BASE_REPO_DIR
if [[ "$expanded_base_repo_dir" != /* && "$expanded_base_repo_dir" != ~* ]]; then
    expanded_base_repo_dir="$PWD/$expanded_base_repo_dir"
fi

# 獲取所有儲存庫列表
REPOS=$(gh repo list --json nameWithOwner --limit 1000 --jq '.[].nameWithOwner')

if [ -z "$REPOS" ]; then
    echo -e "${YELLOW}⚠️  找不到任何屬於 ${GITHUB_USER} 的儲存庫。${NC}"
    exit 1
fi

for repo in $REPOS; do
    echo "-----------------------------------------------------"
    echo -e "${BLUE}ℹ️  正在檢查儲存庫: ${repo}${NC}"

    PRS=$(gh pr list -R "$repo" --json number,title,mergeable,mergeStateStatus,url,headRefName --jq '.[] | @base64')

    if [ -z "$PRS" ]; then
        echo "  > 沒有找到開啟的 Pull Requests。"
        continue
    fi
    
    original_dir=$(pwd)
    
    for pr_base64 in $PRS; do
        pr_details=$(echo "$pr_base64" | base64 --decode)
        
        pr_number=$(echo "$pr_details" | jq -r '.number')
        pr_title=$(echo "$pr_details" | jq -r '.title')
        pr_mergeable=$(echo "$pr_details" | jq -r '.mergeable')
        pr_status=$(echo "$pr_details" | jq -r '.mergeStateStatus')
        pr_url=$(echo "$pr_details" | jq -r '.url')
        pr_branch=$(echo "$pr_details" | jq -r '.headRefName')

        echo ""
        echo "  > 找到 PR: ${pr_url}"
        echo "    📝 標題: ${pr_title}"
        echo "    🔄 合併狀態: ${pr_mergeable}"
        echo "    📊 合併狀態詳情: ${pr_status}"

        case "$pr_mergeable" in
            "MERGEABLE")
                echo -e "${GREEN}✅ 狀態為可合併。正在嘗試自動合併...${NC}"
                if gh pr merge "$pr_url" --squash --delete-branch; then
                    echo -e "${GREEN}✅ ✅ PR 合併成功！${NC}"
                else
                    echo -e "${RED}⚠️  ⚠️  自動合併失敗。可能是因為狀態檢查未通過。${NC}"
                fi
                ;;
            "CONFLICTING")
                handle_conflicting_pr "$repo" "$pr_number" "$pr_branch" "$expanded_base_repo_dir" "$NON_INTERACTIVE"
                # 返回到腳本執行前的目錄，以防 handle_conflicting_pr 改變了工作目錄
                cd "$original_dir"
                ;;
            "UNKNOWN")
                 echo -e "${YELLOW}🔄 合併狀態未知。通常是因為有檢查正在執行中。${NC}"
                 echo -e "${YELLOW}   您可以嘗試啟用自動合併 (auto-merge) 或稍後重試。${NC}"
                 echo -e "${RED}⚠️  ⚠️  自動合併失敗，請手動處理。${NC}"
                ;;
            *)
                echo -e "${RED}❌ 無法合併 PR #${pr_number}。狀態: ${pr_mergeable} (${pr_status})${NC}"
                ;;
        esac
    done
done

echo ""
echo "-----------------------------------------------------"
echo -e "${GREEN}✅ 所有儲存庫檢查完畢。${NC}"
