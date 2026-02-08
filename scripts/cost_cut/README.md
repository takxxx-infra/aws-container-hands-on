# cost_cut scripts

`scripts/cost_cut/main.sh` は、EC2 の起動/停止と、コストが発生するリソースの削除を行う運用スクリプトです。

## 前提

- AWS CLI 認証情報が設定済みであること
- Terraform が利用できること
- リポジトリルートから実行すること

## 実行方法

```bash
chmod +x scripts/cost_cut/main.sh
./scripts/cost_cut/main.sh down
```

`up` を指定すると EC2 起動のみ行います。

```bash
./scripts/cost_cut/main.sh up
```

## Terraform destroy 対象（例）

`main.sh` の `targets` 配列に定義した以下リソースを削除します。

- `aws_vpc_endpoint.ecr_api`
- `aws_vpc_endpoint.ecr_dkr`
- `aws_vpc_endpoint.s3`

削除対象を追加したい場合は、`scripts/cost_cut/main.sh` の `targets` 配列に Terraform のリソースアドレス（例: `aws_xxx.yyy`）を追記してください。

## 注意

- `terraform destroy -auto-approve` を使用するため確認プロンプトは表示されません。
- 実行前に対象 AWS アカウント/プロファイルと対象環境を確認してください。
