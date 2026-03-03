#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="Features"
FEATURE_GLOB="${TARGET_DIR}/**/*.swift"
DESIGN_SYSTEM_DIR="Shared/DesignSystem"
DESIGN_SYSTEM_GLOB="${DESIGN_SYSTEM_DIR}/**/*.swift"

violations=0

check_glob() {
  local search_dir="$1"
  local glob="$2"
  local pattern="$3"
  local description="$4"

  if rg -n --glob "$glob" "$pattern" "$search_dir"; then
    echo "[design-system-guard] violation: ${description}" >&2
    violations=1
  fi
}

check() {
  check_glob "$TARGET_DIR" "$FEATURE_GLOB" "$1" "$2"
}

check_design_system() {
  check_glob "$DESIGN_SYSTEM_DIR" "$DESIGN_SYSTEM_GLOB" "$1" "$2"
}

# 1) 禁止页面层直接构造颜色或直接使用 Color.*
check "\\bColor\\s*\\(" "raw color construction is not allowed in Features; use DSColor tokens"
check "\\bColor\\.[A-Za-z_][A-Za-z0-9_]*" "direct Color.* usage is not allowed in Features; use DSColor tokens"

# 2) 禁止固定字号正文
check "\\.font\\(\\.system\\(size:" "fixed-size .font(.system(size:)) is not allowed in Features"

# 3) 禁止未注册 spacing/radius/border 魔法数字
check "spacing:\\s*[0-9]+(?:\\.[0-9]+)?" "magic spacing values are not allowed in Features; use DSSpacing"
check "cornerRadius:\\s*[0-9]+(?:\\.[0-9]+)?" "magic radius values are not allowed in Features; use DSRadius"
check "lineWidth:\\s*[0-9]+(?:\\.[0-9]+)?" "magic border widths are not allowed in Features; use DSBorder"
check "\\.padding\\(\\s*[0-9]+(?:\\.[0-9]+)?\\s*\\)" "magic padding values are not allowed in Features; use DSSpacing"
check "\\.padding\\([^,]+,\\s*[0-9]+(?:\\.[0-9]+)?\\s*\\)" "magic padding values are not allowed in Features; use DSSpacing"
check "\\.padding\\(\\s*\\.[A-Za-z]+\\s*\\)" "implicit default padding is not allowed in Features; use DSSpacing explicitly"
check "\\.lineSpacing\\(\\s*[0-9]+(?:\\.[0-9]+)?\\s*\\)" "magic line spacing values are not allowed in Features; use DSLineSpacing"
check "\\.opacity\\(\\s*[0-9]+(?:\\.[0-9]+)?\\s*\\)" "magic opacity values are not allowed in Features; use DSOpacity"
check "lineWidth:\\s*DSBorder\\.[A-Za-z_][A-Za-z0-9_]*\\s*[*\\/+-]\\s*[0-9]+(?:\\.[0-9]+)?" "border width arithmetic with magic numbers is not allowed in Features; add a semantic DSBorder token"

# 4) 设计系统层禁止在样式消费侧写透明度小数魔法值（应先落到 DSOpacity token）
check_design_system "\\.opacity\\([^)]*[0-9]+\\.[0-9]+[^)]*\\)" "magic opacity decimals are not allowed in Shared/DesignSystem; define DSOpacity tokens first"

if [[ "$violations" -ne 0 ]]; then
  echo "[design-system-guard] failed" >&2
  exit 1
fi

echo "[design-system-guard] passed"
