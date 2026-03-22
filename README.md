# LINE Messaging API Bot

LINEの Messaging API を利用したチャットBot。AWS Lambda + API Gateway でホスティングしている。

## アーキテクチャ

```
ユーザー (LINEアプリ)
    ↓ メッセージ送信 / リッチメニュータップ
LINEプラットフォーム (LINE社のサーバー)
    ↓ Webhook (HTTPS POST)
API Gateway (HTTPSエンドポイントを提供)
    ↓
Lambda関数 (メッセージ処理)
    ↓ Messaging API (返信)
LINEプラットフォーム → ユーザーに返信を表示
```

### 各コンポーネントの役割

| コンポーネント | 役割 | 管理者 |
|---|---|---|
| LINEアプリ | ユーザーが触るUI。メッセージの表示・入力 | LINE社 |
| LINEプラットフォーム | メッセージの中継、ユーザー認証、署名付与 | LINE社 |
| API Gateway | LINEプラットフォームからのWebhookを受けるHTTPSエンドポイント | AWS (SAMで管理) |
| Lambda関数 | 受け取ったメッセージに対する返信ロジック | このリポジトリ |

## Webhookの仕組み

LINEプラットフォームは、ユーザーがメッセージを送るたびに登録済みのWebhook URLにHTTPS POSTリクエストを送信する。

### リクエスト構造

```json
{
  "events": [
    {
      "type": "message",
      "message": { "type": "text", "text": "こんにちは" },
      "replyToken": "xxx",
      "source": { "userId": "Uxxx", "type": "user" }
    }
  ]
}
```

### イベントの種類

| event.type | 内容 |
|---|---|
| message | ユーザーがメッセージを送信 (text, image, video, audio, file, location, sticker) |
| postback | リッチメニューやボタンのタップ時にサーバーだけに送られるデータ |
| follow | 友だち追加 |
| unfollow | ブロック |

### 署名検証

リクエストヘッダの `x-line-signature` をチャネルシークレットで検証し、LINEプラットフォームからの正当なリクエストであることを確認する。

### 返信方法

| 方式 | 用途 | 課金 |
|---|---|---|
| Reply | ユーザーのメッセージに対する即時返信。`replyToken` を使用 | 無料 |
| Push | 任意のタイミングでこちらから送信。`userId` を指定 | 通数カウント (無料枠: 月200通) |

## リッチメニュー

トーク画面下部に表示されるタップ可能なメニュー。Messaging API で作成・登録する。

### 登録の流れ

1. メニュー構造を定義 (ボタン領域、アクション) → `POST /v2/bot/richmenu`
2. メニュー画像をアップロード (2500x843px) → `POST /v2/bot/richmenu/{id}/content`
3. デフォルトメニューとして設定 → `POST /v2/bot/user/all/richmenu/{id}`

### アクションの種類

| type | 動作 |
|---|---|
| message | ユーザーの発言としてテキストを送信。サーバーには通常のメッセージとして届く |
| postback | トーク画面に `displayText` を表示しつつ、サーバーには `data` を送信。手入力と区別可能 |
| uri | 指定URLをブラウザで開く |

現在は postback アクションを使用しており、「あいさつ」「ヘルプ」の2ボタンを設置している。

## 現在のBot機能

| 入力 | 返答 |
|---|---|
| リッチメニュー「あいさつ」 | 「こんにちは！LINE Botです。何でも話しかけてくださいね。」 |
| リッチメニュー「ヘルプ」 | 使い方の説明 |
| その他テキスト | オウム返し |

## プロジェクト構成

```
├── template.yaml                    # SAMテンプレート (Lambda + API Gateway)
├── lambda/
│   ├── src/index.ts                 # Webhookハンドラー (TypeScript)
│   ├── package.json
│   └── tsconfig.json
├── scripts/
│   ├── setup-rich-menu.sh           # リッチメニュー登録スクリプト
│   ├── create-rich-menu-image.py    # リッチメニュー画像生成 (Pillow)
│   └── rich-menu.png               # 生成済みメニュー画像
└── docs/
    └── line-official.md             # LINE公式ドキュメント参照
```

## セットアップ

### 前提条件

- Node.js 22.x
- AWS CLI (`aws configure` 済み)
- SAM CLI
- LINE公式アカウント (Messaging API有効化済み)

### LINE側の準備

1. [LINE Official Account Manager](https://manager.line.biz/) で公式アカウントを作成
2. Messaging API を有効化
3. チャネルシークレットとチャネルアクセストークン (長期) を取得
4. Webhookの利用をオンにする
5. 応答メッセージをオフにする

### デプロイ

```bash
cd lambda && npm install && npx tsc && cd ..

sam build
sam deploy \
  --stack-name line-bot \
  --region ap-northeast-1 \
  --resolve-s3 \
  --capabilities CAPABILITY_IAM \
  --no-confirm-changeset \
  --parameter-overrides \
    "ChannelSecret=<チャネルシークレット>" \
    "ChannelAccessToken=<チャネルアクセストークン>"
```

デプロイ後に出力される Webhook URL を LINE Official Account Manager に設定する。

### デプロイ後の検証

```bash
# 1. 疎通確認 (署名なしなので401が返れば正常)
curl -X POST https://<api-id>.execute-api.ap-northeast-1.amazonaws.com/Prod/webhook \
  -H "Content-Type: application/json" -d '{}'
# 期待値: "Invalid signature" (HTTP 401)

# 2. LINEアプリでBotにメッセージを送り、オウム返しが返ることを確認
```

### リッチメニューの登録

```bash
# 画像生成 (uv + Pillow)
uv run --with Pillow scripts/create-rich-menu-image.py

# リッチメニュー登録
CHANNEL_ACCESS_TOKEN=<トークン> ./scripts/setup-rich-menu.sh
```
