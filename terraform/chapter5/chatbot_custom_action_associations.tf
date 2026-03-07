# ##################################################
# Chatbot Custom Action Associations
# ##################################################
resource "terraform_data" "chatbot_custom_action_association_approve" {
  input = {
    action_arn             = awscc_chatbot_custom_action.approve.id
    chat_configuration_arn = var.chat_configuration_arn
    chatbot_region         = local.chatbot_region
  }

  triggers_replace = [
    awscc_chatbot_custom_action.approve.id,
    var.chat_configuration_arn,
    local.chatbot_region,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      region='${self.input.chatbot_region}'
      action_arn='${self.input.action_arn}'
      chat_configuration='${self.input.chat_configuration_arn}'

      association_count="$(aws chatbot list-associations \
        --region "$region" \
        --chat-configuration "$chat_configuration" \
        --query "length(Associations[?Resource=='$action_arn'])" \
        --output text)"

      if [ -z "$association_count" ] || [ "$association_count" = "0" ] || [ "$association_count" = "None" ]; then
        aws chatbot associate-to-configuration \
          --region "$region" \
          --resource "$action_arn" \
          --chat-configuration "$chat_configuration" >/dev/null
      fi
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      region='${self.input.chatbot_region}'
      action_arn='${self.input.action_arn}'
      chat_configuration='${self.input.chat_configuration_arn}'

      association_count="$(aws chatbot list-associations \
        --region "$region" \
        --chat-configuration "$chat_configuration" \
        --query "length(Associations[?Resource=='$action_arn'])" \
        --output text)"

      if [ -n "$association_count" ] && [ "$association_count" != "0" ] && [ "$association_count" != "None" ]; then
        aws chatbot disassociate-from-configuration \
          --region "$region" \
          --resource "$action_arn" \
          --chat-configuration "$chat_configuration" >/dev/null
      fi
    EOT
  }

  depends_on = [
    aws_iam_policy.chatbot_custom_actions,
  ]
}

resource "terraform_data" "chatbot_custom_action_association_rollback" {
  input = {
    action_arn             = awscc_chatbot_custom_action.rollback.id
    chat_configuration_arn = var.chat_configuration_arn
    chatbot_region         = local.chatbot_region
  }

  triggers_replace = [
    awscc_chatbot_custom_action.rollback.id,
    var.chat_configuration_arn,
    local.chatbot_region,
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      region='${self.input.chatbot_region}'
      action_arn='${self.input.action_arn}'
      chat_configuration='${self.input.chat_configuration_arn}'

      association_count="$(aws chatbot list-associations \
        --region "$region" \
        --chat-configuration "$chat_configuration" \
        --query "length(Associations[?Resource=='$action_arn'])" \
        --output text)"

      if [ -z "$association_count" ] || [ "$association_count" = "0" ] || [ "$association_count" = "None" ]; then
        aws chatbot associate-to-configuration \
          --region "$region" \
          --resource "$action_arn" \
          --chat-configuration "$chat_configuration" >/dev/null
      fi
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      region='${self.input.chatbot_region}'
      action_arn='${self.input.action_arn}'
      chat_configuration='${self.input.chat_configuration_arn}'

      association_count="$(aws chatbot list-associations \
        --region "$region" \
        --chat-configuration "$chat_configuration" \
        --query "length(Associations[?Resource=='$action_arn'])" \
        --output text)"

      if [ -n "$association_count" ] && [ "$association_count" != "0" ] && [ "$association_count" != "None" ]; then
        aws chatbot disassociate-from-configuration \
          --region "$region" \
          --resource "$action_arn" \
          --chat-configuration "$chat_configuration" >/dev/null
      fi
    EOT
  }

  depends_on = [
    aws_iam_policy.chatbot_custom_actions,
  ]
}
