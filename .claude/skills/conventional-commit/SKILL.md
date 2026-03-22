---
name: conventional-commit
description: Create git commits following the Conventional Commits 1.0.0 specification. Use when the user asks to commit, create a commit, or says /commit. Analyzes staged and unstaged changes, selects the appropriate commit type, and generates a well-structured commit message.
---

# Conventional Commit

Conventional Commits 1.0.0 仕様に従ってコミットを作成する。

## コミットメッセージのフォーマット

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Type の選択基準

| type | 用途 |
|---|---|
| `feat` | 新機能の追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更（空白、フォーマット、セミコロン等） |
| `refactor` | バグ修正でも機能追加でもないコード変更 |
| `perf` | パフォーマンス改善 |
| `test` | テストの追加・修正 |
| `build` | ビルドシステムや外部依存関係の変更（npm, webpack等） |
| `ci` | CI設定ファイルやスクリプトの変更 |
| `chore` | 上記に当てはまらないその他の変更 |

## 破壊的変更 (BREAKING CHANGE)

APIの破壊的変更がある場合、以下のいずれかで明示する：

1. type/scope の直後に `!` を付ける: `feat!: remove deprecated API`
2. フッターに記載: `BREAKING CHANGE: environment variables now take precedence over config files`

## ワークフロー

1. `git status` で未追跡ファイルを確認
2. `git diff` と `git diff --staged` で変更内容を確認
3. `git log --oneline -5` で直近のコミットスタイルを確認
4. 変更内容を分析し、適切な type を選択
5. スコープが明確な場合はスコープを付与（例: `feat(auth):`, `fix(api):`）
6. description は変更の「何を」「なぜ」を簡潔に記述（日本語可）
7. 必要に応じて body に詳細を記述
8. `git add` で関連ファイルをステージング（`git add .` は避け、個別にファイルを指定）
9. コミットを作成

## コミットメッセージの例

```
feat(webhook): LINEメッセージのオウム返し機能を追加
```

```
fix(auth): 署名検証で空文字列の場合にクラッシュする問題を修正
```

```
feat!: 認証APIのレスポンス形式を変更

BREAKING CHANGE: /auth/token のレスポンスが { token: string } から { access_token: string, expires_in: number } に変更
```

## 注意事項

- .env、credentials.json 等のシークレットを含むファイルはコミットしない
- 1つのコミットには1つの論理的な変更のみ含める
- description は命令形で書く（「追加した」ではなく「追加」）
- コミットメッセージは HEREDOC で渡す
