# cost_cut scripts

`scripts/cost_cut/main.sh` は、ECS/EC2 の設定切替と、コストが発生するリソースの apply/destroy を行う運用スクリプトです。

## 前提

- AWS CLI 認証情報が設定済みであること
- Terraform が利用できること
- リポジトリルートから実行すること

## 実行方法

```bash
chmod +x scripts/cost_cut/main.sh
./scripts/cost_cut/main.sh down
```

`up` を指定すると起動・適用側の処理を行います。

```bash
./scripts/cost_cut/main.sh up
```

## 動作

- `up`
  - ECS cluster `sbcntr-app` の `containerInsights` を `enhanced` に変更
  - AWS CLI で `Name=sbcntr-pseudo-cloud9` かつ `stopped` の EC2 を探索し、存在すれば起動
  - `targets` 配列に定義したリソースを `terraform apply`
- `down`
  - ECS cluster `sbcntr-app` の `containerInsights` を `enabled` に変更
  - AWS CLI で `Name=sbcntr-pseudo-cloud9` かつ `running` の EC2 を探索し、存在すれば停止
  - `targets` 配列に定義したリソースを `terraform destroy`

## Terraform 対象（例）

`main.sh` の `targets` 配列に定義した以下リソースを対象に apply/destroy を行います。

- `aws_vpc_endpoint.ecr_api`
- `aws_vpc_endpoint.ecr_dkr`
- `aws_vpc_endpoint.s3`

削除対象を追加したい場合は、`scripts/cost_cut/main.sh` の `targets` 配列に Terraform のリソースアドレス（例: `aws_xxx.yyy`）を追記してください。

## 注意

- 実行前に対象 AWS アカウント/プロファイルと対象環境を確認してください。
