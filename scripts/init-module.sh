#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: scripts/init-module.sh
# 功能描述: 将 code-template 一键初始化派生为新的 CodeBench 微前端业务模块
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

show_help() {
  cat <<EOF
用法:
  bash scripts/init-module.sh [选项]

选项:
  --key <module_key>         模块唯一英文标识（必填，如 monitor、asset_mgr；仅限小写字母开头 + 小写字母/数字/下划线）
  --title <模块中文名称>      门户侧边栏与页面显示标题（默认根据 key 生成）
  --port <后端端口>           Go 后端监听端口，范围 1024-65535（默认: 8091）
  --dev-port <前端调试端口>   Vite 独立开发服务器端口，范围 1024-65535（默认: 5181）
  --table-prefix <表前缀>     共享 PostgreSQL 业务表名前缀，以 _ 结尾（默认: <key>_）
  --icon <Lucide图标名>       CodeBench 门户卡片与菜单图标（默认: Activity）
  --dry-run                  仅预览将要执行的变更，不实际修改任何文件
  --help, -h                 查看帮助说明

示例:
  bash scripts/init-module.sh --key monitor --title "集群监控诊断" --port 8091 --dev-port 5181 --table-prefix mon_
EOF
}

MODULE_KEY=""
MODULE_TITLE=""
BACKEND_PORT="8091"
FRONTEND_PORT="5181"
TABLE_PREFIX=""
MODULE_ICON="Activity"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)
      MODULE_KEY="${2:-}"
      shift 2
      ;;
    --title)
      MODULE_TITLE="${2:-}"
      shift 2
      ;;
    --port)
      BACKEND_PORT="${2:-}"
      shift 2
      ;;
    --dev-port)
      FRONTEND_PORT="${2:-}"
      shift 2
      ;;
    --table-prefix)
      TABLE_PREFIX="${2:-}"
      shift 2
      ;;
    --icon)
      MODULE_ICON="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      log_error "未知参数: $1"
      show_help
      exit 1
      ;;
  esac
done

# 若未通过命令行传入 --key，进入交互式引导模式
if [[ -z "$MODULE_KEY" ]]; then
  if [[ -t 0 ]]; then
    echo "=================================================================="
    echo "        CodeBench 新业务微前端模块初始化向导 (code-template)       "
    echo "=================================================================="
    read -r -p "1. 请输入模块唯一标识 (小写字母开头，如 monitor): " MODULE_KEY
    read -r -p "2. 请输入模块中文名称 [默认: 新业务模块]: " INPUT_TITLE
    [[ -n "$INPUT_TITLE" ]] && MODULE_TITLE="$INPUT_TITLE"
    read -r -p "3. 请输入后端监听端口 [默认: 8091]: " INPUT_PORT
    [[ -n "$INPUT_PORT" ]] && BACKEND_PORT="$INPUT_PORT"
    read -r -p "4. 请输入前端 Vite 调试端口 [默认: 5181]: " INPUT_DEV_PORT
    [[ -n "$INPUT_DEV_PORT" ]] && FRONTEND_PORT="$INPUT_DEV_PORT"
    read -r -p "5. 请输入数据库表前缀 [默认: ${MODULE_KEY}_]: " INPUT_PREFIX
    [[ -n "$INPUT_PREFIX" ]] && TABLE_PREFIX="$INPUT_PREFIX"
  else
    log_error "非交互式终端必须通过 --key 指定模块标识！"
    show_help
    exit 1
  fi
fi

# 1. 严格校验 MODULE_KEY 格式
if [[ ! "$MODULE_KEY" =~ ^[a-z][a-z0-9_]{1,23}$ ]]; then
  log_error "模块标识 '$MODULE_KEY' 不合法！必须以小写字母开头，仅含小写字母、数字或下划线，长度 2-24 位。"
  exit 1
fi

# 2. 检查平台保留路由与核心模块命名冲突
RESERVED_KEYS=(
  "template" "bench" "common" "shield" "pipeline" "pdm" "gate" "proto" "notifier"
  "api" "v1" "admin" "docs" "feedback" "oauth2" "uploads" "login" "assets" "static" "public" "modelgate"
)
for reserved in "${RESERVED_KEYS[@]}"; do
  if [[ "$MODULE_KEY" == "$reserved" ]]; then
    log_error "模块标识 '$MODULE_KEY' 为平台保留关键字或已存在的核心模块，请更换其他名称！"
    exit 1
  fi
done

# 3. 校验端口合法性
validate_port() {
  local p="$1"
  local label="$2"
  if [[ ! "$p" =~ ^[0-9]+$ ]] || (( p < 1024 || p > 65535 )); then
    log_error "${label} '$p' 不合法！请输入 1024-65535 之间的整数端口。"
    exit 1
  fi
}
validate_port "$BACKEND_PORT" "后端端口"
validate_port "$FRONTEND_PORT" "前端调试端口"

if [[ "$BACKEND_PORT" == "$FRONTEND_PORT" ]]; then
  log_error "后端端口与前端调试端口不能相同 ($BACKEND_PORT)！"
  exit 1
fi

# 4. 补全默认表名前缀与模块中文标题
if [[ -z "$TABLE_PREFIX" ]]; then
  TABLE_PREFIX="${MODULE_KEY}_"
fi
if [[ "$TABLE_PREFIX" != *_ ]]; then
  TABLE_PREFIX="${TABLE_PREFIX}_"
fi
if [[ ! "$TABLE_PREFIX" =~ ^[a-z][a-z0-9_]{1,19}_$ ]]; then
  log_error "数据库表前缀 '$TABLE_PREFIX' 不合法！必须以小写字母开头并以 '_' 结尾（例如 mon_）。"
  exit 1
fi

if [[ -z "$MODULE_TITLE" ]]; then
  MODULE_TITLE="新业务模块 (${MODULE_KEY})"
fi

if ! command -v python3 &>/dev/null; then
  log_error "未检测到 python3，请先安装 python3 以执行安全精准替换。"
  exit 1
fi

# 检查模板是否已被初始化过
if ! grep -q "module code-template" "$PROJECT_ROOT/go.mod" 2>/dev/null; then
  log_error "当前工程 go.mod 已不是初始 code-template 状态，为防止重复替换破坏源码，脚本已中止。"
  exit 1
fi

log_info "即将按以下参数初始化新模块："
echo "  - 模块标识 (Key)      : $MODULE_KEY"
echo "  - 模块名称 (Title)    : $MODULE_TITLE"
echo "  - Go 模块名           : code-$MODULE_KEY"
echo "  - 管理员角色          : ${MODULE_KEY}_admin"
echo "  - 数据库表名前缀      : $TABLE_PREFIX"
echo "  - 后端监听端口        : :$BACKEND_PORT"
echo "  - 前端开发端口        : $FRONTEND_PORT"

if [[ "$DRY_RUN" == "true" ]]; then
  log_warn "当前为 --dry-run 预览模式，未修改任何文件。"
  exit 0
fi

export PROJECT_ROOT MODULE_KEY MODULE_TITLE BACKEND_PORT FRONTEND_PORT TABLE_PREFIX

python3 - <<'PYEOF'
import os
from pathlib import Path

root = Path(os.environ["PROJECT_ROOT"])
key = os.environ["MODULE_KEY"]
title = os.environ["MODULE_TITLE"]
port = os.environ["BACKEND_PORT"]
dev_port = os.environ["FRONTEND_PORT"]
table_prefix = os.environ["TABLE_PREFIX"]

pascal_key = "".join(part.capitalize() for part in key.split("_"))
camel_Export = "".join(part.capitalize() if idx > 0 else part for idx, part in enumerate(key.split("_")))

def patch_file(rel_path: str, replacements: list[tuple[str, str]]) -> None:
    p = root / rel_path
    if not p.exists():
        return
    content = p.read_text(encoding="utf-8")
    for old, new in replacements:
        content = content.replace(old, new)
    p.write_text(content, encoding="utf-8")

# 1. 构建与后端配置替换
patch_file("Makefile", [
    ("BINARY          := code-template-server", f"BINARY          := code-{key}-server"),
])

patch_file("go.mod", [
    ("module code-template", f"module code-{key}"),
])

patch_file("config/config.go", [
    ('ModuleKey   = "template"', f'ModuleKey   = "{key}"'),
    ('ServiceName = "Code-Template"', f'ServiceName = "Code-{pascal_key}"'),
    ('AdminRole   = "template_admin"', f'AdminRole   = "{key}_admin"'),
    ('TablePrefix = "tpl_"', f'TablePrefix = "{table_prefix}"'),
    ('DefaultPort = ":8090"', f'DefaultPort = ":{port}"'),
])

patch_file("config.yaml.example", [
    ("Code-Template", f"Code-{pascal_key}"),
    ('port: ":8090"', f'port: ":{port}"'),
    ('external_url: "http://127.0.0.1:8090"', f'external_url: "http://127.0.0.1:{port}"'),
    ('client_id: "code-template"', f'client_id: "code-{key}"'),
    ("tpl_", table_prefix),
])

# 替换所有 Go 源码中的内部包导入路径
for go_file in root.rglob("*.go"):
    if "frontend" in go_file.parts or ".git" in go_file.parts:
        continue
    text = go_file.read_text(encoding="utf-8")
    if '"code-template/' in text:
        go_file.write_text(text.replace('"code-template/', f'"code-{key}/'), encoding="utf-8")

# 2. 前端模块联邦与常量替换
patch_file("frontend/package.json", [
    ('"name": "code-template-frontend"', f'"name": "code-{key}-frontend"'),
    ('"dev": "vite --port 5180"', f'"dev": "vite --port {dev_port}"'),
])

patch_file("frontend/index.html", [
    ("Code-Template 独立开发调试控制台", f"{title} (Code-{pascal_key})"),
])

patch_file("frontend/vite.config.ts", [
    ("appName: 'code-template'", f"appName: 'code-{key}'"),
    ("name: 'template'", f"name: '{key}'"),
    ("base: process.env.VITE_BASE_PATH || '/template/'", f"base: process.env.VITE_BASE_PATH || '/{key}/'"),
    ("port: 5180", f"port: {dev_port}"),
    ("'/template/api'", f"'/{key}/api'"),
    ("http://127.0.0.1:8090", f"http://127.0.0.1:{port}"),
])

patch_file("frontend/src/constants.ts", [
    ("export const MODULE_KEY = 'template';", f"export const MODULE_KEY = '{key}';"),
    ("export const MODULE_TITLE = '示例模板模块';", f"export const MODULE_TITLE = '{title}';"),
    ("export const ADMIN_ROLE = 'template_admin';", f"export const ADMIN_ROLE = '{key}_admin';"),
])

patch_file("frontend/src/menu.ts", [
    ("templateMenuConfig", f"{camel_Export}MenuConfig"),
])
PYEOF

log_success "模块代码与微前端契约已完成全链路替换！"
echo ""
echo "=================================================================="
echo "下一步接入 CodeBench 操作指引："
echo "------------------------------------------------------------------"
echo "1. 生成本地配置并编译验证："
echo "   cp config.yaml.example config.yaml"
echo "   # 请确保 config.yaml 中的 database 与 auth.jwt_secret 与 code-bench 一致"
echo "   make install && make lint && make test && make build"
echo ""
echo "2. 在 ../code-bench/config.yaml 的 gateways 节点下追加以下配置："
echo ""
cat <<YAML
gateways:
  ${MODULE_KEY}:
    url: "http://127.0.0.1:${BACKEND_PORT}"
    title: "${MODULE_TITLE}"
    icon: "${MODULE_ICON}"
    description: "${MODULE_TITLE} 业务子系统"
YAML
echo ""
echo "3. 启动本服务 (./code-${MODULE_KEY}-server) 并重启 code-bench 即可生效！"
echo "=================================================================="
