locals {
  chatbot_custom_action_command = {
    approve  = "ssm put-parameter --name $P --value ${local.approval_action_value} --type String --region ${local.region}"
    rollback = "ssm put-parameter --name $R --value ${local.rollback_action_value} --type String --region ${local.region}"
  }
}

# ##################################################
# Chatbot Custom Action Definitions
# ##################################################
resource "awscc_chatbot_custom_action" "approve" {
  provider    = awscc.chatbot
  action_name = local.approve_action_name
  alias_name  = local.approve_action_name

  definition = {
    command_text = local.chatbot_custom_action_command.approve
  }

  attachments = [
    {
      button_text       = "🔁 再ルーティング"
      notification_type = "Custom"
      criteria = [
        {
          operator      = "EQUALS"
          variable_name = "A"
          value         = local.approval_action_group
        }
      ]
      variables = {
        A = "event.metadata.additionalContext.ActionGroup"
        P = "event.metadata.additionalContext.ParameterName"
      }
    }
  ]
}

resource "awscc_chatbot_custom_action" "rollback" {
  provider    = awscc.chatbot
  action_name = local.rollback_action_name
  alias_name  = local.rollback_action_name

  definition = {
    command_text = local.chatbot_custom_action_command.rollback
  }

  attachments = [
    {
      button_text       = "🔙 ロールバック"
      notification_type = "Custom"
      criteria = [
        {
          operator      = "EQUALS"
          variable_name = "A"
          value         = local.approval_action_group
        }
      ]
      variables = {
        A = "event.metadata.additionalContext.ActionGroup"
        R = "event.metadata.additionalContext.RollbackParameterName"
      }
    }
  ]
}
