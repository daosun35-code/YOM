#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="Features"
GLOB="${TARGET_DIR}/**/*.swift"

violations=0

check() {
  local pattern="$1"
  local description="$2"

  if rg -n --glob "$GLOB" "$pattern" "$TARGET_DIR"; then
    echo "[design-system-guard] violation: ${description}" >&2
    violations=1
  fi
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
check "\\.lineSpacing\\(\\s*[0-9]+(?:\\.[0-9]+)?\\s*\\)" "magic line spacing values are not allowed in Features; use DSLineSpacing"
check "\\.opacity\\(\\s*[0-9]+(?:\\.[0-9]+)?\\s*\\)" "magic opacity values are not allowed in Features; use DSOpacity"

if [[ "$violations" -ne 0 ]]; then
  echo "[design-system-guard] failed" >&2
  exit 1
fi

echo "[design-system-guard] passed"
