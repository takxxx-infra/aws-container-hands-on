# aws-container-hands-on
『AWSコンテナ設計・構築[本格]入門』のハンズオン内容を、Terraform で再現・管理することを目的としています。  
コンテナ技術の基礎から、AWS でのコンテナ実行環境の設計・構築・運用までを学ぶための書籍です。

- 書籍ページ: https://www.sbcr.jp/product/4815626044/

> 本リポジトリは出版社および執筆者とは関係のない個人管理の検証用リポジトリです。  
> 本リポジトリに関する問い合わせを、出版社・執筆者へ行わないでください。

## 目的

- ハンズオンで作成するインフラをコード（IaC）として管理する
- 手動作業を減らし、再現性のある環境構築を行う
- 変更履歴を Git で追跡できる状態にする

## 対象

以下のような用途を想定しています。

- 書籍のハンズオン手順を Terraform に置き換える
- 高コストのリソースを一時的に削除・停止しやすい構成とする
- 進捗に合わせ、構築を再開しやすい構成とする

## 前提

- AWS アカウントを利用できること
- Terraform がインストール済みであること
- AWS CLI 認証情報（`~/.aws/credentials` など）が設定済みであること

## 進め方（基本）

1. Terraform コードを追加・修正する
2. `terraform fmt` で整形する
3. `terraform init` を実行する
4. `terraform plan` で差分を確認する
5. `terraform apply` で反映する

## Terraform ディレクトリ構成

章ごとに root module と state を分離しています。

- `terraform/chapter5`: Chapter5 で構築する基盤リソース
- `terraform/chapter6`: Chapter6 で追加するリソース

`chapter6` から `chapter5` の値は `terraform_remote_state` で参照します。  
参照が必要な値は `terraform/chapter5/outputs.tf` で `output` として公開します。

## 適用順序

依存関係の都合上、以下の順で実行します。

1. `terraform -chdir=terraform/chapter5 init`
2. `terraform -chdir=terraform/chapter5 apply`
3. `terraform -chdir=terraform/chapter6 init`
4. `terraform -chdir=terraform/chapter6 apply`

## コスト削減スクリプト

コストカット用の運用スクリプトを `scripts/cost_cut/` に配置しています。  
詳細な使い方は `scripts/cost_cut/README.md` を参照してください。

## リポジトリ方針

- ハンズオンで構築したリソースは、可能な限り Terraform 管理下に置く
- 手動変更（コンソール操作）を行った場合は、Terraform コードへ必ず反映する
