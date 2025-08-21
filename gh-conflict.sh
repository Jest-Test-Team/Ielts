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
# 5. 腳本會自動處理所有衝突：
#    - 對於 Snyk PR，會嘗試使用 --admin 參數強制合併
#    - 對於其他衝突 PR，會標記為 'needs-manual-resolution' 並繼續執行
# ==============================================================================

# --- 設定 ---
# 請將此路徑修改為您存放本地 Git 儲存庫的根目錄
# 腳本會在此目錄下尋找與遠端儲存庫同名的資料夾
# 例如: 如果您的專案位於 ~/Documents/Projects/my-repo，請將此處設為 "~/Documents/Projects"
BASE_REPO_DIR="~/Documents/Untitled"

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
    
    # 初始化變數
    local HAS_STASHED=false

    echo -e "${YELLOW}⚠️  無法自動合併。狀態: CONFLICTING${NC}"
    echo -e "${YELLOW}⚠️  發現合併衝突，正在嘗試解決...${NC}"
    
    local repo_name
    repo_name=$(echo "$repo" | cut -d'/' -f2)
    local local_repo_dir="${expanded_base_repo_dir}/${repo_name}"
    
    # 檢查是否為 Snyk 發起的 PR
    local is_snyk_pr=false
    if [[ "$pr_title" == *"[Snyk]"* ]]; then
        is_snyk_pr=true
        echo -e "${BLUE}ℹ️  檢測到 Snyk 發起的 PR，將使用強制覆蓋模式${NC}"
    fi
    
    echo -e "${BLUE}ℹ️  正在切換到正確的儲存庫: ${repo}${NC}"
    
    if [ ! -d "$local_repo_dir" ]; then
        echo -e "${YELLOW}⚠️  找不到本地儲存庫: ${local_repo_dir}${NC}"
        echo -e "${BLUE}ℹ️  嘗試自動克隆儲存庫 ${repo}...${NC}"
        
        # 創建父目錄（如果不存在）
        mkdir -p "$expanded_base_repo_dir"
        
        # 嘗試克隆儲存庫
        if gh repo clone "$repo" "$local_repo_dir"; then
            echo -e "${GREEN}✅ 成功克隆儲存庫: ${repo}${NC}"
        else
            echo -e "${RED}❌ 克隆儲存庫失敗: ${repo}${NC}"
            echo -e "${YELLOW}   可能原因: 網絡問題、權限問題或儲存庫不存在${NC}"
        return
        fi
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
    
    # 檢查是否有未提交的變更
    if git status --porcelain | grep -q .; then
        echo -e "${YELLOW}⚠️  檢測到本地未提交的變更，嘗試自動 stash...${NC}"
        
        # 創建一個包含時間戳的 stash 訊息
        stash_message="自動 stash 由腳本創建於 $(date '+%Y-%m-%d %H:%M:%S')"
        
        if git stash push -m "$stash_message"; then
            echo -e "${GREEN}✅ 成功 stash 本地變更${NC}"
            # 記錄我們創建了 stash，以便稍後提醒用戶
            HAS_STASHED=true
        else
            echo -e "${RED}❌ stash 本地變更失敗${NC}"
            echo -e "${YELLOW}⚠️  嘗試強制 checkout，這可能會覆蓋本地變更${NC}"
        fi
    fi
    
    # 使用 `gh pr checkout` 會自動處理 fetch 和建立本地分支
    echo -e "${BLUE}ℹ️  正在 checkout PR #${pr_number} 以便處理衝突...${NC}"
    
    # 檢查 PR 是否仍然存在
    if ! gh pr view "$pr_number" -R "$repo" &>/dev/null; then
        echo -e "${YELLOW}⚠️  PR #${pr_number} 可能已不存在或無法訪問${NC}"
        echo -e "${BLUE}ℹ️  嘗試關閉或刪除此 PR...${NC}"
        gh pr close "$pr_number" -R "$repo" --delete-branch &>/dev/null || true
        cd - > /dev/null # 返回原始目錄
        return
    fi
    
    # 嘗試直接獲取 PR 的分支名稱
    local pr_branch_name
    pr_branch_name=$(gh pr view "$pr_number" -R "$repo" --json headRefName --jq .headRefName 2>/dev/null)
    if [ -z "$pr_branch_name" ]; then
        echo -e "${RED}❌ 無法獲取 PR #${pr_number} 的分支名稱${NC}"
        cd - > /dev/null # 返回原始目錄
        return
    fi
    
    # 嘗試直接 fetch 和 checkout 分支，而不是使用 gh pr checkout
    if ! git fetch origin "$pr_branch_name:$pr_branch_name" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  無法 fetch PR 分支，可能已被刪除，嘗試使用 gh pr checkout...${NC}"
        if ! gh pr checkout "$pr_number" 2>/dev/null; then
            echo -e "${RED}❌ checkout PR #${pr_number} 失敗。${NC}"
            echo -e "${YELLOW}   可能原因: 遠端分支已被刪除、本地有未提交變更或分支名稱衝突${NC}"
            echo -e "${BLUE}ℹ️  嘗試標記 PR 為需要人工處理並繼續...${NC}"
            
            # 嘗試關閉或標記 PR
            if [[ "$pr_title" == *"[Snyk]"* ]]; then
                echo -e "${BLUE}ℹ️  這是 Snyk PR，嘗試關閉...${NC}"
                gh pr close "$pr_number" -R "$repo" --delete-branch &>/dev/null || true
            else
                # 檢查標籤是否存在，不存在則創建
                if ! gh label list -R "$repo" --json name --jq '.[] | .name' | grep -q "needs-manual-resolution"; then
                    echo "ℹ️  標籤 'needs-manual-resolution' 不存在，正在創建..."
                    if gh label create "needs-manual-resolution" -R "$repo" -c "#FF0000" -d "需要手動解決衝突的 PR"; then
                        echo "✅ 已創建標籤: needs-manual-resolution"
                    else
                        echo "❌ 創建標籤失敗，可能沒有足夠權限。"
                    fi
                fi
                
                # 添加標籤到 PR
                if gh pr edit "$pr_number" -R "$repo" --add-label "needs-manual-resolution"; then
                    echo "✅ 已標記為: needs-manual-resolution"
                else
                    echo "❌ 標記失敗。"
                fi
            fi
            
            # 如果我們之前創建了 stash，提醒用戶
            if [ "$HAS_STASHED" = true ]; then
                echo -e "${BLUE}ℹ️  您有未處理的 stash，可以使用 'git stash list' 和 'git stash pop' 恢復${NC}"
            fi
            
            cd - > /dev/null # 返回原始目錄
            return
        fi
    else
        # 成功 fetch 了分支，現在切換到它
        if ! git checkout "$pr_branch_name" 2>/dev/null; then
            echo -e "${RED}❌ 切換到分支 ${pr_branch_name} 失敗${NC}"
            cd - > /dev/null # 返回原始目錄
            return
        fi
    fi

    echo -e "${YELLOW}⚠️  自動解決失敗，需要手動處理。${NC}"
    
    # 根據 PR 類型選擇處理方式
    if [ "$is_snyk_pr" = true ]; then
        # Snyk PR 使用強制覆蓋模式
        local choice=5
        echo -e "${BLUE}ℹ️  Snyk PR 自動選擇：強制覆蓋模式${NC}"
    else
        # 其他 PR 標記為需要人工處理
        local choice=3
        echo -e "${BLUE}ℹ️  其他 PR 自動選擇：標記為需要人工處理，繼續執行腳本${NC}"
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
            
            # 切換回主分支
            if git checkout "${main_branch}"; then
                echo -e "${GREEN}✅ 已切換回主分支${NC}"
            else
                echo -e "${RED}❌ 切換回主分支失敗${NC}"
            fi
            
            # 如果之前有 stash，提醒用戶
            if [ "$HAS_STASHED" = true ]; then
                echo -e "${BLUE}ℹ️  您有未處理的 stash，可以使用 'git stash list' 和 'git stash pop' 恢復${NC}"
            fi
            ;;
        3)
            echo "ℹ️  正在標記 PR 為需要人工處理..."
            # 檢查標籤是否存在，不存在則創建
            if ! gh label list -R "$repo" --json name --jq '.[] | .name' | grep -q "needs-manual-resolution"; then
                echo "ℹ️  標籤 'needs-manual-resolution' 不存在，正在創建..."
                if gh label create "needs-manual-resolution" -R "$repo" -c "#FF0000" -d "需要手動解決衝突的 PR"; then
                    echo "✅ 已創建標籤: needs-manual-resolution"
                else
                    echo "❌ 創建標籤失敗，可能沒有足夠權限。"
                fi
            fi
            
            # 添加標籤到 PR
            if gh pr edit "$pr_number" -R "$repo" --add-label "needs-manual-resolution"; then
                echo "✅ 已標記為: needs-manual-resolution"
            else
                echo "❌ 標記失敗。"
            fi
            
            # 切換回主分支
            if git checkout "${main_branch}"; then
                echo -e "${GREEN}✅ 已切換回主分支${NC}"
            else
                echo -e "${RED}❌ 切換回主分支失敗${NC}"
            fi
            
            # 如果之前有 stash，提醒用戶
            if [ "$HAS_STASHED" = true ]; then
                echo -e "${BLUE}ℹ️  您有未處理的 stash，可以使用 'git stash list' 和 'git stash pop' 恢復${NC}"
            fi
            ;;
        4)
            echo "ℹ️  顯示手動解決衝突的步驟："
            echo "1. cd -- \"${local_repo_dir}\""
            echo "2. gh pr checkout ${pr_number}"
            echo "3. git merge origin/${main_branch}"
            echo "4. (解決衝突後) git add . && git commit"
            echo "5. git push origin ${pr_branch}"
            
            # 切換回主分支
            if git checkout "${main_branch}"; then
                echo -e "${GREEN}✅ 已切換回主分支${NC}"
            else
                echo -e "${RED}❌ 切換回主分支失敗${NC}"
            fi
            
            # 如果之前有 stash，提醒用戶
            if [ "$HAS_STASHED" = true ]; then
                echo -e "${BLUE}ℹ️  您有未處理的 stash，可以使用 'git stash list' 和 'git stash pop' 恢復${NC}"
            fi
            ;;
        5)
            echo "ℹ️  Snyk PR 強制覆蓋模式："
            echo "正在強制合併 PR #${pr_number}..."
            
            # 檢查 PR 是否仍然存在
            if ! gh pr view "$pr_number" -R "$repo" &>/dev/null; then
                echo -e "${YELLOW}⚠️  PR #${pr_number} 可能已不存在或無法訪問${NC}"
                echo -e "${BLUE}ℹ️  嘗試關閉或刪除此 PR...${NC}"
                gh pr close "$pr_number" -R "$repo" --delete-branch &>/dev/null || true
                git checkout "${main_branch}" &>/dev/null || true
                return
            fi
            
            # 強制合併 Snyk PR (使用 --admin 參數來繞過檢查)
            if gh pr merge "$pr_number" -R "$repo" --squash --delete-branch --admin; then
                echo -e "${GREEN}✅ Snyk PR 強制合併成功！${NC}"
            else
                echo -e "${YELLOW}⚠️  強制合併失敗，嘗試使用 --rebase 模式..."
                if gh pr merge "$pr_number" -R "$repo" --rebase --delete-branch --admin; then
                    echo -e "${GREEN}✅ Snyk PR 強制合併成功！${NC}"
                else
                    echo -e "${RED}❌ 強制合併失敗，嘗試啟用自動合併..."
                    if gh pr merge "$pr_number" -R "$repo" --auto --squash 2>/dev/null; then
                        echo -e "${GREEN}✅ 已啟用自動合併，PR 將在通過檢查後自動合併${NC}"
                    else
                        echo -e "${RED}❌ 所有嘗試都失敗，標記為需要人工處理${NC}"
                        # 檢查標籤是否存在，不存在則創建
                        if ! gh label list -R "$repo" --json name --jq '.[] | .name' | grep -q "needs-manual-resolution"; then
                            echo "ℹ️  標籤 'needs-manual-resolution' 不存在，正在創建..."
                            if gh label create "needs-manual-resolution" -R "$repo" -c "#FF0000" -d "需要手動解決衝突的 PR"; then
                                echo "✅ 已創建標籤: needs-manual-resolution"
                            else
                                echo "❌ 創建標籤失敗，可能沒有足夠權限。"
                            fi
                        fi
                        
                        # 添加標籤到 PR
                        if gh pr edit "$pr_number" -R "$repo" --add-label "needs-manual-resolution"; then
                            echo "✅ 已標記 PR #${pr_number} 為: needs-manual-resolution"
                            # 添加 URL 以便後續查看
                            echo "${pr_url}"
                        else
                            echo "❌ 標記失敗。"
                        fi
                    fi
                fi
            fi
            # 切換回主分支
            if git checkout "${main_branch}"; then
                echo -e "${GREEN}✅ 已切換回主分支${NC}"
            else
                echo -e "${RED}❌ 切換回主分支失敗，可能已經在主分支上${NC}"
            fi
            
            # 如果之前有 stash，提醒用戶
            if [ "$HAS_STASHED" = true ]; then
                echo -e "${BLUE}ℹ️  您有未處理的 stash，可以使用 'git stash list' 和 'git stash pop' 恢復${NC}"
            fi
            ;;
        *)
            echo "無效的選項。將跳過此 PR。"
            
            # 切換回主分支
            if git checkout "${main_branch}"; then
                echo -e "${GREEN}✅ 已切換回主分支${NC}"
            else
                echo -e "${RED}❌ 切換回主分支失敗${NC}"
            fi
            
            # 如果之前有 stash，提醒用戶
            if [ "$HAS_STASHED" = true ]; then
                echo -e "${BLUE}ℹ️  您有未處理的 stash，可以使用 'git stash list' 和 'git stash pop' 恢復${NC}"
            fi
            ;;
    esac
    
    # 返回原始目錄
    cd - > /dev/null
}


# --- 主腳本 ---

# 檢查 gh 是否安裝
command -v gh >/dev/null 2>&1 || die "此腳本需要 GitHub CLI ('gh')。請先安裝。"

# 檢查 gh 是否登入
# 直接嘗試獲取用戶名，這是更可靠的方式來檢查認證狀態
echo -e "${BLUE}ℹ️  正在檢查 GitHub CLI 認證狀態...${NC}"

# 嘗試最多 3 次獲取用戶名
for i in {1..3}; do
    if GITHUB_USER=$(gh api user --jq .login 2>/dev/null); then
        break
    else
        echo -e "${YELLOW}⚠️  GitHub CLI 認證可能有問題，嘗試重新認證 (嘗試 $i/3)...${NC}"
        # 嘗試重新登入
        gh auth status >/dev/null 2>&1 || gh auth refresh -h github.com -s user >/dev/null 2>&1
        sleep 2
    fi
    
    # 如果是最後一次嘗試且仍然失敗
    if [ $i -eq 3 ] && ! GITHUB_USER=$(gh api user --jq .login 2>/dev/null); then
        die "無法獲取 GitHub 用戶名。請確保您已登入 GitHub CLI (執行 'gh auth login')。"
    fi
done

echo -e "${GREEN}✅ GitHub CLI 認證狀態正常 - 已登入為 ${GITHUB_USER}${NC}"

# 腳本現在自動處理所有衝突，無需非互動模式
# 用戶名已在上面的認證檢查中獲取

echo -e "${BLUE}🚀 GitHub PR 自動合併與衝突處理腳本${NC}"
echo -e "${GREEN}✅ 自動模式：Snyk PR 將使用強制覆蓋，其他衝突 PR 會自動標記${NC}"
echo "=================================================="
echo -e "${BLUE}ℹ️  正在為用戶 ${GITHUB_USER} 檢查所有儲存庫...${NC}"

# 展開波浪號路徑
eval expanded_base_repo_dir=$BASE_REPO_DIR
if [[ "$expanded_base_repo_dir" != /* && "$expanded_base_repo_dir" != ~* ]]; then
    expanded_base_repo_dir="$PWD/$expanded_base_repo_dir"
fi

# 獲取所有儲存庫列表
echo -e "${BLUE}ℹ️  正在獲取儲存庫列表...${NC}"

# 嘗試最多 3 次獲取儲存庫列表
for i in {1..3}; do
    REPOS=$(gh repo list --json nameWithOwner --limit 1000 --jq '.[].nameWithOwner' 2>/dev/null)
    if [ -n "$REPOS" ]; then
        break
    else
        echo -e "${YELLOW}⚠️  獲取儲存庫列表失敗，嘗試重新獲取 (嘗試 $i/3)...${NC}"
        sleep 2
    fi
    
    # 如果是最後一次嘗試且仍然失敗
    if [ $i -eq 3 ] && [ -z "$REPOS" ]; then
    echo -e "${YELLOW}⚠️  找不到任何屬於 ${GITHUB_USER} 的儲存庫。${NC}"
    exit 1
fi
done

for repo in $REPOS; do
    echo "-----------------------------------------------------"
    echo -e "${BLUE}ℹ️  正在檢查儲存庫: ${repo}${NC}"

    # 嘗試最多 3 次獲取 PR 列表
    local prs_found=false
    for i in {1..3}; do
        PRS=$(gh pr list -R "$repo" --json number,title,mergeable,mergeStateStatus,url,headRefName --jq '.[] | @base64' 2>/dev/null)
        
        if [ -n "$PRS" ]; then
            prs_found=true
            break
        else
            # 只有在第一次嘗試失敗時才顯示重試訊息
            if [ $i -eq 1 ]; then
                echo -e "${YELLOW}⚠️  獲取 PR 列表失敗，嘗試重新獲取...${NC}"
            fi
            sleep 2
        fi
    done
    
    if [ "$prs_found" = false ]; then
        echo "  > 沒有找到開啟的 Pull Requests。"
        continue
    fi
    
    original_dir=$(pwd)
    
    for pr_base64 in $PRS; do
        # 解碼 PR 詳情並處理可能的錯誤
        pr_details=""
        if ! pr_details=$(echo "$pr_base64" | base64 --decode 2>/dev/null); then
            echo -e "${YELLOW}⚠️  解碼 PR 詳情失敗，跳過...${NC}"
            continue
        fi
        
        # 提取 PR 資訊並檢查是否有效
        pr_number=$(echo "$pr_details" | jq -r '.number' 2>/dev/null)
        pr_title=$(echo "$pr_details" | jq -r '.title' 2>/dev/null)
        pr_mergeable=$(echo "$pr_details" | jq -r '.mergeable' 2>/dev/null)
        pr_status=$(echo "$pr_details" | jq -r '.mergeStateStatus' 2>/dev/null)
        pr_url=$(echo "$pr_details" | jq -r '.url' 2>/dev/null)
        pr_branch=$(echo "$pr_details" | jq -r '.headRefName' 2>/dev/null)
        
        # 檢查是否獲取了所有必要資訊
        if [ -z "$pr_number" ] || [ -z "$pr_title" ] || [ -z "$pr_mergeable" ] || [ -z "$pr_url" ]; then
            echo -e "${YELLOW}⚠️  無法獲取完整的 PR 資訊，跳過...${NC}"
            continue
        fi

        echo ""
        echo "  > 找到 PR: ${pr_url}"
        echo "    📝 標題: ${pr_title}"
        echo "    🔄 合併狀態: ${pr_mergeable}"
        echo "    📊 合併狀態詳情: ${pr_status}"

        case "$pr_mergeable" in
            "MERGEABLE")
                echo -e "${GREEN}✅ 狀態為可合併。正在嘗試自動合併...${NC}"
                # 檢查 PR 是否仍然存在
                if ! gh pr view "$pr_number" -R "$repo" &>/dev/null; then
                    echo -e "${YELLOW}⚠️  PR #${pr_number} 可能已不存在或無法訪問，跳過${NC}"
                    continue
                fi
                
                if gh pr merge "$pr_url" --squash --delete-branch; then
                    echo -e "${GREEN}✅ ✅ PR 合併成功！${NC}"
                else
                    echo -e "${RED}⚠️  ⚠️  自動合併失敗。${NC}"
                    echo -e "${YELLOW}   可能原因: ${NC}"
                    echo -e "${YELLOW}   - 狀態檢查未通過（CI/CD 測試失敗）${NC}"
                    echo -e "${YELLOW}   - 需要審核（Review）${NC}"
                    echo -e "${YELLOW}   - 分支保護規則阻止合併${NC}"
                    echo -e "${YELLOW}   - 合併時發生衝突${NC}"
                    
                    # 嘗試啟用自動合併
                    echo -e "${BLUE}ℹ️  嘗試啟用自動合併...${NC}"
                    if gh pr merge "$pr_url" --auto --squash 2>/dev/null; then
                        echo -e "${GREEN}✅ 已啟用自動合併，PR 將在通過檢查後自動合併${NC}"
                    else
                        echo -e "${YELLOW}⚠️  無法啟用自動合併，可能需要手動處理${NC}"
                        echo -e "${BLUE}ℹ️  建議: 手動檢查 PR 狀態: 'gh pr view ${pr_url}'${NC}"
                    fi
                fi
                ;;
            "CONFLICTING")
                handle_conflicting_pr "$repo" "$pr_number" "$pr_branch" "$expanded_base_repo_dir"
                # 返回到腳本執行前的目錄，以防 handle_conflicting_pr 改變了工作目錄
                cd "$original_dir"
                ;;
            "UNKNOWN")
                echo -e "${YELLOW}🔄 合併狀態未知。${NC}"
                echo -e "${YELLOW}   可能原因: ${NC}"
                echo -e "${YELLOW}   - 檢查正在執行中（CI/CD 測試）${NC}"
                echo -e "${YELLOW}   - GitHub API 暫時性問題${NC}"
                echo -e "${YELLOW}   - PR 剛剛建立，狀態尚未更新${NC}"
                echo -e "${BLUE}ℹ️  建議: ${NC}"
                echo -e "${BLUE}   - 嘗試啟用自動合併: 'gh pr merge ${pr_url} --auto'${NC}"
                echo -e "${BLUE}   - 稍後重新執行此腳本${NC}"
                echo -e "${BLUE}   - 查看 PR 狀態: 'gh pr view ${pr_url}'${NC}"
                echo -e "${RED}⚠️  自動合併失敗，請手動處理。${NC}"
                ;;
            *)
                echo -e "${RED}❌ 無法合併 PR #${pr_number}。狀態: ${pr_mergeable} (${pr_status})${NC}"
                echo -e "${YELLOW}   未知的合併狀態，可能是: ${NC}"
                echo -e "${YELLOW}   - PR 已關閉或已合併${NC}"
                echo -e "${YELLOW}   - PR 被鎖定${NC}"
                echo -e "${YELLOW}   - 分支已被刪除${NC}"
                echo -e "${YELLOW}   - GitHub API 返回了未處理的狀態${NC}"
                echo -e "${BLUE}ℹ️  建議: 手動檢查 PR 狀態: 'gh pr view ${pr_url}'${NC}"
                ;;
        esac
    done
done

echo ""
echo "-----------------------------------------------------"
echo -e "${GREEN}✅ 所有儲存庫檢查完畢。${NC}"
