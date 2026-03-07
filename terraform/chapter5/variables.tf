variable "chatbot_region" {
  description = "Amazon Q Developer in chat applications API を呼び出すリージョン。Slack channel configuration を作成したリージョンを指定します。利用可能リージョンは us-east-2, us-west-2, ap-southeast-1, eu-west-1 です。"
  type        = string
  default     = "us-west-2"
  validation {
    condition = contains([
      "us-east-2",
      "us-west-2",
      "ap-southeast-1",
      "eu-west-1",
    ], var.chatbot_region)
    error_message = "chatbot_region は us-east-2, us-west-2, ap-southeast-1, eu-west-1 のいずれかを指定してください。"
  }
}

variable "approval_sns_topic_arn" {
  description = "Amazon Q Developer が subscribe している SNS トピック ARN。"
  type        = string
  default     = "arn:aws:sns:ap-northeast-1:682120332115:ecs-bg-deployment-sns"
}

variable "chat_configuration_arn" {
  description = "Slack チャンネル設定の ARN。Chatbot custom action の関連付け先です。"
  type        = string
  default     = "arn:aws:chatbot::682120332115:chat-configuration/slack-channel/ecs-bg-deployment"
}

variable "lambda_timeout" {
  description = "ライフサイクルフック Lambda のタイムアウト秒数。"
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "lambda_timeout は 3 以上 900 以下で指定してください。"
  }
}

variable "lambda_memory_size" {
  description = "ライフサイクルフック Lambda のメモリサイズ。"
  type        = number
  default     = 256

  validation {
    condition     = var.lambda_memory_size >= 128
    error_message = "lambda_memory_size は 128 以上で指定してください。"
  }
}

variable "callback_delay_seconds" {
  description = "ライフサイクルフックが IN_PROGRESS を返す際の再呼び出し待機秒数。"
  type        = number
  default     = 60

  validation {
    condition     = var.callback_delay_seconds >= 1 && var.callback_delay_seconds <= 43200
    error_message = "callback_delay_seconds は 1 以上 43200 以下で指定してください。"
  }
}

variable "approval_parameter_prefix" {
  description = "承認状態と通知済みマーカーを配置する SSM Parameter Store のプレフィックス。"
  type        = string
  default     = "/sbcntr/ecs-bg-approval"

  validation {
    condition     = length(trim(trimspace(var.approval_parameter_prefix), "/")) > 0
    error_message = "approval_parameter_prefix は空文字にできません。"
  }
}

variable "chatbot_execution_role_arn" {
  description = "Slack / Amazon Q Developer のカスタムアクションが実行に使う IAM ロール ARN。"
  type        = string
  default     = "arn:aws:iam::682120332115:role/service-role/ecs-bg-deployment-q-role"
}
