#!/usr/bin/env bash
# 一键安装 AI agent skills，并可选自动克隆依赖到项目根目录
# 支持 Cursor、Codex、Claude Code 等读取 SKILL.md 的开发工具。
# 用法：
#   在 AI-Skills 仓库根目录执行: ./scripts/install.sh
#   仅安装 Skills（不下载 SDK 源码）: ./scripts/install.sh --skills-only

set -e

SKILLS_ONLY=false
if [[ "${1:-}" == "--skills-only" ]]; then
  SKILLS_ONLY=true
fi

# 若当前不在 AI-Skills 仓库内，尝试通过 git 找到仓库根
REPO_ROOT="${REPO_ROOT:-}"
if [[ -z "$REPO_ROOT" ]]; then
  if [[ -d "skills" ]]; then
    REPO_ROOT="."
  elif [[ -d ".git" ]]; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
  fi
fi

if [[ -z "$REPO_ROOT" || ! -d "$REPO_ROOT/skills" ]]; then
  echo "错误: 请在 AI-Skills 仓库根目录下执行此脚本，或设置 REPO_ROOT 指向该目录。"
  echo "示例: git clone https://github.com/0xfnzero/AI-Skills.git && cd AI-Skills && ./scripts/install.sh"
  exit 1
fi

cd "$REPO_ROOT"
SOURCE_SKILLS_DIR="$REPO_ROOT/skills"

install_for_tool() {
  local tool_name="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  for skill in "$SOURCE_SKILLS_DIR"/*/; do
    if [[ -d "$skill" && -f "$skill/SKILL.md" ]]; then
      local name
      name=$(basename "$skill")
      rm -rf "$target_dir/$name"
      mkdir -p "$target_dir/$name"
      cp -R "$skill"/. "$target_dir/$name/"
      echo "已为 $tool_name 安装 skill: $name"
    fi
  done
  echo "$tool_name Skills 已复制到: $target_dir"
}

install_for_tool "Cursor" "${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"
install_for_tool "Codex" "${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
install_for_tool "Claude Code" "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

if [[ "$SKILLS_ONLY" == true ]]; then
  echo "已跳过 SDK 源码克隆（--skills-only）。"
  exit 0
fi

# 自动克隆或更新依赖到项目根目录（已存在则 git pull 拉取最新）
clone_or_update_repo() {
  local url_ssh="$1"
  local name="$2"
  local target="$REPO_ROOT/$name"
  if [[ -d "$target/.git" ]]; then
    echo "已存在，拉取最新: $name"
    (cd "$target" && git pull) || echo "警告: $name 拉取失败，请手动进入该目录执行 git pull"
    return 0
  fi
  if [[ -d "$target" ]]; then
    echo "警告: $target 已存在但非 git 仓库，跳过。若需重新克隆请先移除该目录。"
    return 0
  fi
  echo "正在克隆 $name ..."
  if git clone --depth 1 "$url_ssh" "$target" 2>/dev/null; then
    echo "已克隆: $name (SSH)"
    return 0
  fi
  local url_https="https://github.com/0xfnzero/${name}.git"
  if git clone --depth 1 "$url_https" "$target"; then
    echo "已克隆: $name (HTTPS)"
  else
    echo "警告: 克隆失败 $name，请检查网络或手动执行: git clone $url_https $target"
    return 0
  fi
}

clone_or_update_repo "git@github.com:0xfnzero/sol-parser-sdk.git" "sol-parser-sdk"
clone_or_update_repo "git@github.com:0xfnzero/sol-trade-sdk.git" "sol-trade-sdk"
clone_or_update_repo "git@github.com:0xfnzero/solana-streamer.git" "solana-streamer"
clone_or_update_repo "git@github.com:0xfnzero/sol-safekey.git" "sol-safekey"
clone_or_update_repo "git@github.com:0xfnzero/sol-parser-sdk-nodejs.git" "sol-parser-sdk-nodejs"
clone_or_update_repo "git@github.com:0xfnzero/sol-parser-sdk-python.git" "sol-parser-sdk-python"
clone_or_update_repo "git@github.com:0xfnzero/sol-parser-sdk-golang.git" "sol-parser-sdk-golang"
clone_or_update_repo "git@github.com:0xfnzero/sol-trade-sdk-nodejs.git" "sol-trade-sdk-nodejs"
clone_or_update_repo "git@github.com:0xfnzero/sol-trade-sdk-python.git" "sol-trade-sdk-python"
clone_or_update_repo "git@github.com:0xfnzero/sol-trade-sdk-golang.git" "sol-trade-sdk-golang"

echo ""
echo "安装完成。"
echo "  - Skills 源目录: $SOURCE_SKILLS_DIR"
echo "  - 已安装到 Cursor/Codex/Claude Code 的用户级 skills 目录"
echo "  - 项目根目录已就绪: Rust SDK、solana-streamer、sol-safekey，以及 parser/trade 的 Node.js/Python/Go SDK 源码"
