# chapter5 ECS Blue/Green 承認フロー

## 構成概要
このディレクトリでは、既存の ECS Blue/Green デプロイメントに対して以下を追加しています。

- `POST_TEST_TRAFFIC_SHIFT` で呼ばれるライフサイクルフック Lambda
- SSM Parameter Store を使った承認状態管理
- Amazon Q Developer / AWS Chatbot custom action による Slack からの承認とロールバック
- `awscc` provider で管理する custom action 定義
- 既存の Slack channel configuration へ custom action を関連付ける補助処理

動作概要は以下です。

1. ECS のテストトラフィック切替後に Lambda が呼ばれます。
2. 初回デプロイで source revision が存在しない場合は、Slack 通知せず `SUCCEEDED` を返して次の stage へ進みます。
3. 通常デプロイで承認パラメータとロールバック要求パラメータの両方が無ければ SNS に custom notification を publish します。
4. Slack に `再ルーティング` / `ロールバック` ボタン付き通知が届きます。
5. `再ルーティング` で承認パラメータを作成します。
6. `ロールバック` でロールバック要求パラメータを作成します。
7. 次回 Lambda 呼び出しで `approved` があれば `SUCCEEDED` を返し、本番切替を再開します。
8. 次回 Lambda 呼び出しで `rollback` があれば `FAILED` を返し、ECS のロールバックへ進みます。
9. `SUCCEEDED` / `FAILED` を返す直前に、deployment 単位の SSM パラメータを自動削除します。

## 追加ファイル
- `variables.tf`
- `iam_role.tf`
- `iam_policy.tf`
- `lambda.tf`
- `chatbot_custom_actions.tf`
- `chatbot_custom_action_associations.tf`
- `lambda_src/lifecycle_hook_handler.py`
- `tests/test_lifecycle_hook_handler.py`
- `README.md`

## 前提条件
以下は事前に準備済みである前提です。

- ECS サービス本体
- ECS Blue/Green デプロイメントのベース設定
- Amazon Q Developer と Slack の連携
- Amazon Q Developer が subscribe する SNS トピック
- 既存の Slack channel configuration
- `aws` CLI v2

## 入力変数
最低限、以下を指定してください。

- `approval_sns_topic_arn`
- `chat_configuration_arn`
- `approval_parameter_prefix`
- `chatbot_execution_role_arn`
- `chatbot_region`

必要に応じて以下を調整します。

- `lambda_timeout`
- `lambda_memory_size`
- `callback_delay_seconds`

`callback_delay_seconds` に `0` を指定すると、Lambda は `callBackDelay` を返さず ECS のデフォルト再実行間隔 30 秒を使います。

### 変数例
```hcl
approval_sns_topic_arn     = "arn:aws:sns:ap-northeast-1:123456789012:sbcntr-q-approval"
chat_configuration_arn     = "arn:aws:chatbot::123456789012:chat-configuration/slack-channel/example"
approval_parameter_prefix  = "/sbcntr/ecs-bg-approval"
chatbot_execution_role_arn = "arn:aws:iam::123456789012:role/AmazonQDeveloperChatRole"
chatbot_region             = "ap-southeast-1"
lambda_timeout             = 30
lambda_memory_size         = 256
callback_delay_seconds     = 0
```

## Slack channel configuration ARN の指定方法
既存の Slack チャンネル設定 ARN を `chat_configuration_arn` に渡します。

確認例:
```sh
aws chatbot describe-slack-channel-configurations --region <chatbot_region>
```

`chatbot_region` には Slack channel configuration を作成したリージョンを指定してください。Amazon Q Developer in chat applications API の利用可能リージョンは `us-east-2` `us-west-2` `ap-southeast-1` `eu-west-1` です。ワークロードリージョンの `ap-northeast-1` は指定できません。

## 適用手順
新規環境では以下の順で適用します。

1. 有効な AWS 認証情報を設定します。
2. `terraform init` を実行します。
3. `terraform plan` を実行します。
4. `terraform apply` を実行します。
5. `aws chatbot list-custom-actions --region <chatbot_region>` で custom action が作成されたことを確認します。
6. `aws chatbot list-associations --region <chatbot_region> --chat-configuration <chat_configuration_arn>` でチャンネル設定に関連付けられたことを確認します。
7. frontend service の Blue/Green デプロイを実行し、Slack 通知を確認します。

### custom action の確認例
```sh
aws chatbot get-custom-action --region <chatbot_region> --custom-action-arn <approve_action_arn> --query 'CustomAction.Definition.CommandText' --output text
aws chatbot get-custom-action --region <chatbot_region> --custom-action-arn <rollback_action_arn> --query 'CustomAction.Definition.CommandText' --output text
aws ssm get-parameters-by-path --path <approval_parameter_prefix> --recursive --region ap-northeast-1 --query 'Parameters[].Name' --output text
```

## 既存 CLI 実装からの移行手順
すでに旧実装の custom action を apply 済みなら、先に import してください。import せずに apply すると、既存 action と名前衝突する可能性があります。

1. `terraform init` を実行します。
2. 既存 action の ARN を確認します。
3. 以下の import を実行します。

```sh
terraform import awscc_chatbot_custom_action.approve <approve_action_arn>
terraform import awscc_chatbot_custom_action.rollback <rollback_action_arn>
```

4. `terraform plan` で差分を確認します。
5. 問題なければ `terraform apply` を実行します。

確認例:
```sh
aws chatbot list-custom-actions --region <chatbot_region>
```

## 適用前に確認すべき AWS CLI プロファイル / リージョン
- `terraform apply` を実行するシェルで AWS CLI 認証が有効であること
- Chatbot custom action 作成 API の呼び先リージョンが `chatbot_region` と一致していること
- ワークロードのリージョンは既存 `locals.tf` の `local.region` に従うこと

## custom action 管理方針
custom action 定義は `awscc_chatbot_custom_action` で Terraform 管理します。既存の Slack channel configuration 自体は Terraform 管理していないため、関連付けだけは `terraform_data` + `aws chatbot associate-to-configuration` で補助しています。

この構成により、custom action 本体は HCL で読めるようにしつつ、既存の Slack 設定 ARN をそのまま再利用できます。

## 通知重複防止
同一 deployment に対して毎回通知しないよう、以下の 3 種類の SSM パラメータを使います。

- 承認パラメータ: `.../approved`
- ロールバック要求パラメータ: `.../rollback`
- 通知済みマーカー: `.../notification-sent`

Lambda は `notification-sent` を `Overwrite=false` で作成できた最初の 1 回だけ SNS に publish します。
終端判定で `SUCCEEDED` または `FAILED` を返すタイミングでは、これら 3 つのパラメータを自動削除します。

## 出力値
主な出力値は以下です。

- ALB DNS 名
- frontend の test listener URL
- 承認 Lambda の ARN / 関数名
- custom action 名
- custom action ARN
- 承認パラメータ prefix

## apply / destroy 時の注意点
- `terraform apply` 実行環境には `aws` CLI が必要です。
- custom action 定義は `chatbot_region` 側で作成されます。
- 関連付け処理は `terraform_data` の `local-exec` で実行されるため、CLI 実行に失敗すると apply 全体が失敗します。
- `chat_configuration_arn` を変更すると、旧設定との関連付け解除と新設定への関連付けが実行されます。

## 注意点と制約
- custom action の `CommandText` は API 側の制約を考慮し、100 文字未満に収まるコマンドを使っています。
- そのため action 内の変数名は `A` `P` `R` の短い識別子を使っています。
- custom action の `CommandText` は Amazon Q の CLI 構文に合わせ、`aws` プレフィックスなしで定義しています。
- `ロールバック` アクションは `ssm put-parameter --name $R --value rollback --type String --overwrite --region ...` を使っています。
- custom action の `Variables` は custom notification の `metadata.additionalContext` から値を引く前提です。
- `ロールバック` は即時反映ではなく、次回の lifecycle hook callback で Lambda が `FAILED` を返したタイミングで反映されます。デフォルト設定では `callBackDelay` を返さないため、ECS の既定間隔 30 秒ごとに再実行されます。
- 初回デプロイは比較対象の source revision が無いため、Slack 通知で保留せず自動的に次の stage へ進みます。
- Lambda は deployment ごとに一意なパラメータ名を生成し、`SUCCEEDED` / `FAILED` を返す直前に承認済みパラメータ、ロールバック要求パラメータ、通知済みマーカーを自動削除します。
- Slack channel configuration 自体は Terraform 管理していないため、Amazon Q の command support と guardrail は別途有効である前提です。

## 本番導入前に検証すべき観点
- `POST_TEST_TRAFFIC_SHIFT` で Lambda が期待どおり呼ばれること
- 同一 deployment で通知が 1 回しか飛ばないこと
- `再ルーティング` ボタンで承認パラメータが正しい名前で作成されること
- `ロールバック` ボタンでロールバック要求パラメータが正しい名前で作成されること
- 同一 deployment に `approved` と `rollback` が両方ある場合に `rollback` が優先されること
- 初回デプロイで Slack 通知なしに次の stage へ進むこと
- `SUCCEEDED` / `FAILED` の返却時に deployment 単位の SSM パラメータが削除されること
- デフォルト設定では最大 30 秒程度で lifecycle hook が `FAILED` を返し、ECS がロールバックへ進むこと
- `chatbot_region` がワークロードリージョンと異なる場合でも custom action を正しく作成・関連付けできること
- 既存 CLI 実装から import した後に不要な recreate が発生しないこと
