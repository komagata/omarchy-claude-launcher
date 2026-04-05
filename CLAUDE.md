# CLAUDE.md

このファイルは Claude Code が omarchy-claude-launcher を触るときに参照する開発コンテキスト。

## プロジェクトの目的

Claude Code の外部利用が API ベースに移行して OpenClaw (claude.ai の UI) がほぼ使えなくなった。OpenClaw の「複数プロジェクトをサイドバーから即切替」「他プロジェクトを踏まえた横断的な示唆」といった使い勝手を Claude Code に持ってくるためのランチャー。

omarchy ユーザー向けの OSS。GitHub: https://github.com/komagata/omarchy-claude-launcher

## アーキテクチャ

- **1 キーバインド（Super+I）** → walker popup でプロジェクト選択 → tmux ウィンドウで Claude が起動
- **単一 tmux セッション** "claude" を維持し、1 プロジェクト = 1 ウィンドウで管理
- 初回: alacritty を起動してセッション attach / 2回目以降: 同じ alacritty 内に新規ウィンドウ追加 + hyprctl でフォーカス
- 永続性は 2 層: tmux（OS 起動中は生存）+ Claude の会話履歴（`~/.claude/projects/<cwd-slug>/` に永続保存、`claude -c` で復元）

## ディレクトリレイアウト前提（固定 depth=2）

```
$CLAUDE_LAUNCHER_WORKS_DIR/<namespace>/<name>/
```

例: `~/Works/komagata/siro-pc/`, `~/Works/fjordllc/bootcamp/`

フラット（depth=1）はサポートしない（README で明記）。

## 環境変数

| 変数 | デフォルト |
|---|---|
| `CLAUDE_LAUNCHER_WORKS_DIR` | `$HOME/Works` |
| `CLAUDE_LAUNCHER_DEFAULT_NS` | 未設定（未設定時は `ns/name` 必須）|
| `CLAUDE_LAUNCHER_TERMINAL` | `$TERMINAL` → `alacritty` |
| `CLAUDE_LAUNCHER_SESSION` | `claude` |
| `CLAUDE_LAUNCHER_DEBUG` | 未設定（`1` で `/tmp/claude-launcher.log` に出力）|

## 既知のハマりどころ

- **ghostty + NVIDIA**: RTX 4070 など、mesa llvmpipe フォールバックに落ちる環境で ghostty をサブプロセス起動すると LLVM error でクラッシュ（`fs_variant_partial`）。alacritty で回避。
- **ghostty `gtk-single-instance=detect`**: 既存インスタンスを検出すると `-e` で渡したコマンドを無視して即終了する。alacritty or `--gtk-single-instance=false` で回避。
- **tmux セッションの root コマンドに `claude -c` を直書きすると trust prompt 後にセッションが死ぬ**: trust 受理後に claude が exit するため。`bash -lc 'while true; do claude -c || claude; read -r || break; done'` でラップして再起動ループ化する。
- **walker の選択結果プレフィックス除去**: `${var#??}` はマルチバイト文字と相性が悪い。`${rel#● }`・`${rel#  }` で明示的に除去すること。

## ファイル構成

```
omarchy-claude-launcher/
├── README.md              # 英語ドキュメント
├── LICENSE                # MIT
├── CLAUDE.md              # このファイル
├── bin/
│   └── claude-launcher    # メインスクリプト
├── install.sh             # 対話的インストーラ
├── examples/
│   └── hypr-keybind.conf  # Hyprland キーバインド例
├── docs/
│   ├── screenshot.png     # walker picker UI
│   └── terminal.png       # tmux タブのターミナル
└── .gitignore
```

## 開発コマンド

```bash
# 構文チェック
bash -n bin/claude-launcher

# デバッグ実行（walker は必要）
CLAUDE_LAUNCHER_DEBUG=1 ./bin/claude-launcher

# ログ確認
tail -f /tmp/claude-launcher.log

# インストール（ローカル環境に）
./install.sh
```

## 公開スコープの方針

以下は **含めない**（komagata 個人のグローバルメモリ機能として別管理）:
- `~/.claude/profile.md` / `~/.claude/active-projects.md` の生成・更新
- `claude-seed-projects` スクリプト
- CLAUDE.md への `@import` 追記

ランチャーは「プロジェクト切替」という機能に徹する。グローバルメモリは使いたい人が自分で組む。

## 残タスク・アイデア

- **ブログ記事**: `~/Works/komagata/docs-komagata-org/tmp/drafts/omarchy-claude-launcher.md` にドラフト済み。管理画面から投稿する必要あり（本番 DB 直接アクセス不可）。
- デモ GIF（asciinema or peek）を docs/ に追加できれば README がより伝わる
- install.sh に uninstall オプション
- flat layout（depth=1）のサポート要望が来たら検討
- `CLAUDE_LAUNCHER_NEW_PROJECT_HOOK` のようなフック（新規作成時に `git init` など自動実行）
- walker 以外のランチャー（rofi, fuzzel）対応
- グローバルメモリ機能を汎用化して別 OSS 化する可能性あり（現在は komagata 個人環境で検証中）

## 個人環境との関係

komagata の `~/.local/bin/claude-launcher` はこのリポジトリの `bin/claude-launcher` へのシンボリックリンク。つまり**このリポジトリを更新すれば本人の環境に即反映される**。個人環境固有の設定は `~/.config/hypr/envs.conf` と `~/.bashrc` に環境変数として分離してある。
