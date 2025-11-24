# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

ruby-block-toggle.nvimは、Rubyのブロック記法（`do ~ end` と `{}`）を相互に変換するNeovimプラグイン。nvim-treesitterを使用してRubyのASTを解析し、カーソル位置に最も近いブロックを検出して変換する。

## 依存関係

- nvim-treesitter
- Treesitter Ruby parser (`:TSInstall ruby`)

## 開発時のテスト方法

### 自動テスト（plenary.nvim）

plenary.nvimを使った自動テストを実装済み。以下のコマンドで実行：

```bash
# 全テストを実行
make test

# 特定のテストファイルを実行
make test-file FILE=tests/unit/toggle_spec.lua

# またはdirectで実行
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "lua require('plenary.test_harness').test_directory('tests/unit/', { minimal_init = 'tests/minimal_init.lua' })"
```

**テスト前の準備:**
- plenary.nvimをインストール
- nvim-treesitterとRubyパーサーをインストール（`:TSInstall ruby`）

**テスト構造:**
- `tests/unit/toggle_spec.lua`: ブロック変換のテスト
- `tests/unit/treesitter_spec.lua`: Treesitter関連のテスト
- `tests/helpers.lua`: テスト用ヘルパー関数
- `tests/fixtures/blocks.rb`: テスト用サンプルコード

### 手動テスト

1. sample.rbを開いて手動でテスト
2. Neovimで`:source plugin/ruby-block-toggle.lua`を実行してプラグインをリロード
3. `:RubyBlockToggle`コマンドを実行して動作確認

## アーキテクチャ

### モジュール構成

- **plugin/ruby-block-toggle.lua**: プラグインのエントリーポイント。`:RubyBlockToggle`コマンドを定義
- **lua/ruby-block-toggle/init.lua**: メインモジュール。設定管理と依存関係チェックを実施
- **lua/ruby-block-toggle/toggle.lua**: ブロック変換ロジック。インデントを保持しながら`do~end` ⇔ `{}`を変換
- **lua/ruby-block-toggle/treesitter.lua**: Treesitterとのインターフェース。ブロック検出の3段階戦略を実装
- **lua/ruby-block-toggle/utils.lua**: 通知ユーティリティ
- **lua/ruby-block-toggle/types/treesitter.lua**: 型定義（LuaLS用）

### ブロック検出の3段階戦略（重要）

`treesitter.lua`の`find_nearest_block()`関数は、以下の優先順位でブロックを検出：

1. **カーソル行優先**: カーソル行でブロックが開始している場合、そのブロックを選択
   - 同一行に複数のブロックがある場合は最小範囲（最も内側）を選択
2. **親ノード探索**: カーソル行にブロックがない場合、親ノードを辿って最も近い親ブロックを選択
3. **最近接ブロック**: 上記で見つからない場合、バッファ全体から距離計算で最も近いブロックを選択

この戦略により、ネストされたブロックでも直感的な挙動を実現。

### ブロック変換の仕組み（Treesitterベース）

`toggle.lua`の変換関数は、Treesitterを使ってキーワードの正確な位置を特定し、`vim.api.nvim_buf_set_text()`で直接置換する方式を採用：

- **convert_doend_to_brace()**: `do ~ end` → `{}`
  1. `treesitter.get_block_keywords()`でキーワードノードを取得
  2. `end`キーワードを`}`に置換（位置ずれ防止のため先に実行）
  3. `do`キーワードを`{`に置換

- **convert_brace_to_doend()**: `{}` → `do ~ end`
  1. `treesitter.get_block_keywords()`でキーワードノードを取得
  2. `}`キーワードを`end`に置換
  3. `{`キーワードを`do`に置換

**重要な設計上の利点:**
- 1行ブロック（`foo do 1 end`）と複数行ブロックを統一的に処理
- 正規表現に依存しないため、コメントや文字列内のキーワードに影響されない
- キーワードのみを置換するため、インデントやコメントは自動的に保持される
- 以前の正規表現ベースの実装にあった「1行ブロックで`end`が置換されない」バグが解消

## コーディング規約

- LuaLSの型アノテーション（`---@class`, `---@param`, `---@return`）を使用
- エラーハンドリングは`pcall`を使用
- 通知は`utils.notify_*`関数を使用（ログレベル管理のため）
- TreesitterのノードタイプはRuby parser仕様に従う：
  - `do_block`: `do ~ end`形式のブロック
  - `block`: `{}`形式のブロック
  - `do`, `end`, `{`, `}`: キーワードノード（子ノードとして存在）
  - `block_parameters`: ブロックパラメータ（例: `|x, y|`）

## 重要な実装詳細

### treesitter.get_block_keywords()

ブロックノードからキーワードを抽出する関数。`node:iter_children()`で子ノードを走査し、以下を返す：

```lua
{
  opening_keyword = TSNode,  -- "do" or "{"
  closing_keyword = TSNode,  -- "end" or "}"
  block_parameters = TSNode  -- optional
}
```

### バッファの直接編集

`vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, replacement)`を使用してキーワード位置を直接置換。この方法により：
- 行全体を読み書きする必要がない
- 位置情報が正確なため、エッジケースに強い
- コードがシンプルになる
