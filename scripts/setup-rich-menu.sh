#!/bin/bash
# リッチメニューの作成・画像アップロード・デフォルト設定を行うスクリプト
#
# 使い方:
#   CHANNEL_ACCESS_TOKEN=xxx ./scripts/setup-rich-menu.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_PATH="${SCRIPT_DIR}/rich-menu.png"

if [ -z "${CHANNEL_ACCESS_TOKEN:-}" ]; then
  echo "Error: CHANNEL_ACCESS_TOKEN を設定してください"
  exit 1
fi

echo "1. リッチメニューを作成中..."
RICH_MENU_ID=$(curl -s -X POST https://api.line.me/v2/bot/richmenu \
  -H "Authorization: Bearer ${CHANNEL_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "size": { "width": 2500, "height": 843 },
    "selected": true,
    "name": "メインメニュー",
    "chatBarText": "メニュー",
    "areas": [
      {
        "bounds": { "x": 0, "y": 0, "width": 1250, "height": 843 },
        "action": { "type": "postback", "data": "action=greeting", "displayText": "あいさつ" }
      },
      {
        "bounds": { "x": 1250, "y": 0, "width": 1250, "height": 843 },
        "action": { "type": "postback", "data": "action=help", "displayText": "ヘルプ" }
      }
    ]
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['richMenuId'])")

echo "   richMenuId: ${RICH_MENU_ID}"

echo "2. 画像をアップロード中..."
curl -s -X POST "https://api-data.line.me/v2/bot/richmenu/${RICH_MENU_ID}/content" \
  -H "Authorization: Bearer ${CHANNEL_ACCESS_TOKEN}" \
  -H "Content-Type: image/png" \
  --data-binary "@${IMAGE_PATH}" > /dev/null

echo "3. デフォルトリッチメニューに設定中..."
curl -s -X POST "https://api.line.me/v2/bot/user/all/richmenu/${RICH_MENU_ID}" \
  -H "Authorization: Bearer ${CHANNEL_ACCESS_TOKEN}" > /dev/null

echo ""
echo "完了! リッチメニューが設定されました。"
