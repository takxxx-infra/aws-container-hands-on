# Terraform実装依頼プロンプト

あなたはAWSとTerraformに詳しいシニアクラウドエンジニアです。  
以下の要件に基づき、**Terraformで構築可能な実装一式**を作成してください。

---

## 目的

Amazon ECS の **組み込み Blue/Green デプロイメント**において、  
`POST_TEST_TRAFFIC_SHIFT` のライフサイクルフックで本番切替を一時保留し、  
Slack 上の Amazon Q Developer カスタムアクションから

- 再ルーティング（本番切替を再開）
- ロールバック

を実行できる承認フローを構築したいです。

---

## 前提

以下は **すでに構築済み** とします。

- ECS サービス本体
- ECS の Blue/Green デプロイメント設定のベース
- Amazon Q Developer と Slack の連携
- Amazon Q Developer が subscribe する SNS トピックの存在
- Slack チャンネル設定（Amazon Q Developer / AWS Chatbot 側）の存在

Terraformで今回追加実装したいのは、主に以下です。

- ライフサイクルフック用 Lambda
- Lambda 実行ロール / ポリシー
- 必要な CloudWatch Logs
- 必要に応じた SSM Parameter Store の命名ルール設計
- Amazon Q Developer カスタムアクション作成用の仕組み
- Slack チャンネル設定へカスタムアクションを関連付ける仕組み
- Terraform から `aws chatbot create-custom-action` / `associate-to-configuration` を実行するための実装
  - `null_resource` + `local-exec` でも可
  - 可能であれば冪等性に配慮すること

---

## 実現したい動作

### 1. ECSライフサイクルフック
- 対象ステージ: `POST_TEST_TRAFFIC_SHIFT`
- Lambda が呼ばれる
- Lambda は SSM Parameter Store に承認パラメータが存在するか確認する

### 2. 承認パラメータが存在しない場合
- Lambda は **Amazon Q Developer が subscribe している SNS トピック** にカスタム通知を publish する
- その通知が Slack に届く
- Slack 通知上に、Amazon Q Developer のカスタムアクションとして以下の2ボタンを表示する
  - 再ルーティング
  - ロールバック
- Lambda は ECS ライフサイクルフックの戻り値として `IN_PROGRESS` を返す
- `callBackDelay` は Terraform の変数で調整可能にする
- Lambda の再実行時に毎回通知しないよう、重複通知防止の考慮を入れること

### 3. 承認パラメータが存在する場合
- Lambda は `SUCCEEDED` を返す
- ECS デプロイは次のステージへ進む

### 4. 再ルーティングボタン押下時
- Amazon Q Developer カスタムアクションが AWS CLI を実行する
- その CLI により、対象の承認パラメータを SSM Parameter Store に作成または更新する
- 次回の Lambda 呼び出し時に承認済みとして扱われる

### 5. ロールバックボタン押下時
- Amazon Q Developer カスタムアクションが AWS CLI を実行する
- 対象の ECS Service Deployment をロールバックする

---

## Terraform実装方針

以下の方針で実装してください。

### 必須
- Terraform はできるだけモジュール化しすぎず、まずは理解しやすい構成にする
- ただし、以下は分離してよい
  - Lambda 関連
  - IAM 関連
  - Chatbot / Q Developer カスタムアクション関連
- 変数は必要最低限に絞る
- 命名規則はわかりやすく統一する
- README.md を作成し、適用手順と前提条件を記載する

### Chatbot / Amazon Q Developer カスタムアクション実装について
Terraform の AWS Provider だけではカスタムアクションを直接管理しづらい場合、  
以下のような構成でも可とします。

- `local_file` で JSON 定義ファイルを出力
- `null_resource` + `local-exec` で AWS CLI を実行
  - `aws chatbot create-custom-action`
  - `aws chatbot update-custom-action` が必要なら考慮
  - `aws chatbot associate-to-configuration`
- destroy 時のふるまいも可能な範囲で考慮
- ただし、まずは **apply で作れることを優先**

### Lambda 実装について
- Python で実装する
- `archive_file` で zip 化して Terraform からデプロイできる形にする
- コードは可読性重視
- 適切なログ出力を入れる
- 例外処理を入れる
- 環境変数で以下を渡せるようにする
  - SNS Topic ARN
  - 承認パラメータのプレフィックス
  - callback delay
  - 重複通知制御に必要な値（必要なら）

---

## 通知メッセージ要件

Lambda が SNS に publish するメッセージは、Amazon Q Developer の **custom notification 形式** にすること。

通知には以下を含めること。

### content
- title
- description
- nextSteps
- keywords

### metadata
- summary
- threadId
- enableCustomActions = true
- additionalContext

### additionalContext に含めたい値
- `ActionGroup`
  - 値は例として `ecs-bg-approval`
- `DeploymentId`
- `ServiceDeploymentArn`
- `ParameterName`

---

## カスタムアクション要件

2つのカスタムアクションを作成してください。

### 1. 再ルーティング
- ボタン名: `再ルーティング`
- 対象通知条件:
  - `additionalContext.ActionGroup == ecs-bg-approval`
- 実行内容:
  - `aws ssm put-parameter` で承認パラメータを設定
- パラメータ値は `"approved"` など固定値でよい

### 2. ロールバック
- ボタン名: `ロールバック`
- 対象通知条件:
  - `additionalContext.ActionGroup == ecs-bg-approval`
- 実行内容:
  - `aws ecs stop-service-deployment --stop-type ROLLBACK`

---

## 重要な考慮点

以下を実装・設計に反映してください。

### 1. 重複通知防止
- Lambda が `IN_PROGRESS` で何度も呼ばれる可能性がある
- 毎回 SNS publish しないようにする
- 方法は任せるが、できるだけシンプルにする
- 例:
  - ECS hookDetails を活用する
  - SSM Parameter Store や DynamoDB はできれば増やしたくない
- まずはシンプルな方法を優先

### 2. ServiceDeploymentArn の扱い
- ロールバック実行に必要
- Lambda 内で取得方法を設計すること
- ECS イベントや引数から直接取れない場合の代替案もコメントで説明すること

### 3. Terraformの冪等性
- `null_resource` + `local-exec` を使う場合でも、できるだけ apply のたびに壊れない構成にする
- `triggers` を適切に使う
- 作成済み時の対策を考える
- 完璧でなくてもよいが、意図を README に明記すること

### 4. Chatbotリージョン
- Amazon Q Developer / AWS Chatbot の CLI 対象リージョンに注意すること
- そのため、通常のワークロードリージョン（例: ap-northeast-1）とは別に、
  `chatbot_region` 変数を持てるようにすること

### 5. IAM最小権限
最低限、以下を考慮してください。

#### Lambda実行ロール
- `ssm:GetParameter`
- `sns:Publish`
- 必要に応じて ECS の参照系権限
- CloudWatch Logs 出力権限

#### Amazon Q Developer / Chatbot 用ロール
- 再ルーティング用:
  - `ssm:PutParameter`
- ロールバック用:
  - `ecs:StopServiceDeployment`

可能な範囲で Resource を絞ること。

---

## 期待する成果物

以下を出力してください。

### 1. Terraformコード一式
最低でも以下を含めること

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `iam.tf`
- `lambda.tf`
- `chatbot_custom_actions.tf`
- `versions.tf`

必要なら以下も可

- `locals.tf`
- `data.tf`

### 2. Lambdaソースコード
例:
- `lambda_src/lifecycle_hook_handler.py`

### 3. カスタムアクションJSONテンプレート
Terraformで `local_file` 出力してもよいし、テンプレートファイルでもよい

例:
- `templates/approve-action.json.tftpl`
- `templates/rollback-action.json.tftpl`

### 4. README.md
以下を含めること

- 構成概要
- 前提条件
- 適用方法
- 事前に確認すべきAWS CLIプロファイル/リージョン
- 既存の Slack channel configuration ARN の指定方法
- 注意点
- 想定される制約

---

## 変数として受けたい項目

必要最低限として、以下を variable 化してください。

- `project`
- `env`
- `region`
- `chatbot_region`
- `approval_sns_topic_arn`
- `chat_configuration_arn`
- `lambda_timeout`
- `lambda_memory_size`
- `callback_delay_seconds`
- `approval_parameter_prefix`
- `chatbot_execution_role_arn`
- `tags`

必要なら追加してよいですが、増やしすぎないでください。

---

## 実装時の補足ルール

- コメントは適度に入れる
- Terraform コードは読みやすさ重視
- 変数名・locals 名は意味がわかるものにする
- ハードコードしすぎない
- ただし、過剰な抽象化は不要
- まず動くものを優先
- `terraform apply` ですぐ理解できる実装にする

---

## 出力形式

以下の順で出力してください。

1. 構成の要約
2. ディレクトリ構成
3. Terraformコード全文
4. Lambdaコード全文
5. README全文
6. この実装での注意点
7. 今後の改善案

---

## 追加要望

実装の最後に、以下も必ず書いてください。

- 「この実装で Terraform Provider だけでは扱いづらく、AWS CLI に逃がしている箇所」
- 「apply / destroy 時の注意点」
- 「本番導入前に検証すべき観点」

---

## できれば反映してほしいこと

- Terraform内で `archive_file` を使って Lambda zip を生成する
- `null_resource` の `local-exec` では `set -euo pipefail` 相当の安全策を入れる
- 失敗時に原因が追いやすいように CLI の標準出力/標準エラーを意識する
- JSONテンプレートは `templatefile()` を使ってよい
- `depends_on` を必要な箇所に適切に入れる

---

## 最後に

まずは **一発で動くこと** と **読みやすさ** を優先してください。  
必要以上に複雑なモジュール化や抽象化は不要です。  
実装結果は、そのままローカルで試せる形で具体的に出してください。