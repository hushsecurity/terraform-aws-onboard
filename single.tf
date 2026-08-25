data "aws_caller_identity" "current" {
}

resource "aws_iam_role" "this" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.hush_account_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = [var.hush_org_id]
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.security_audit ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

data "aws_iam_policy_document" "this" {

  statement {
    sid    = "RoleAssumption"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:PassRole"
    ]
    resources = [aws_iam_role.this.arn]
  }

  statement {
    sid    = "ListRegions"
    effect = "Allow"
    actions = [
      "account:ListRegions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "KmsDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"
    ]
  }

  dynamic "statement" {
    for_each = var.send_events ? [1] : []
    content {
      sid    = "SendEvents"
      effect = "Allow"
      actions = [
        "events:PutRule",
        "events:PutTargets"
      ]
      resources = [
        "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/hush-security-events-*"
      ]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  statement {
    sid    = "CleanupEvents"
    effect = "Allow"
    actions = [
      "events:DeleteRule",
      "events:RemoveTargets"
    ]
    resources = [
      "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/hush-security-events-*"
    ]
  }

  statement {
    sid    = "PutEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "arn:aws:events:*:${var.hush_account_id}:event-bus/*-*-aws-integration-events"
    ]
  }

  dynamic "statement" {
    for_each = var.codeartifact_readonly ? [1] : []
    content {
      sid    = "CodeArtifact"
      effect = "Allow"
      actions = [
        "codeartifact:List*",
        "codeartifact:Describe*",
        "codeartifact:Get*",
        "codeartifact:ReadFromRepository"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.ecr_readonly ? [1] : []
    content {
      sid    = "ECR"
      effect = "Allow"
      actions = [
        "ecr:Describe*",
        "ecr:List*",
        "ecr:Get*",
        "ecr:BatchGet*",
        "ecr:BatchCheck*"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.secrets_manager_readonly ? [1] : []
    content {
      sid    = "SecretsManager"
      effect = "Allow"
      actions = [
        "secretsmanager:List*",
        "secretsmanager:Get*",
        "secretsmanager:Describe*",
        "secretsmanager:BatchGet*"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.ssm_parameter_store_readonly ? [1] : []
    content {
      sid    = "SSMParameterStore"
      effect = "Allow"
      actions = [
        "ssm:List*",
        "ssm:Get*",
        "ssm:Describe*"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.kms_readonly ? [1] : []
    content {
      sid    = "KMS"
      effect = "Allow"
      actions = [
        "kms:List*",
        "kms:Describe*",
        "kms:Get*"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = local.agent_discovery ? [1] : []
    content {
      sid    = "AgentDiscovery"
      effect = "Allow"
      actions = [
        "bedrock:ListAgents",
        "bedrock:GetAgent",
        "bedrock:ListAgentActionGroups",
        "bedrock:GetAgentActionGroup",
        "bedrock-agentcore:ListAgentRuntimes",
        "bedrock-agentcore:GetAgentRuntime",
        "bedrock-agentcore:ListHarnesses",
        "bedrock-agentcore:GetHarness",
        "bedrock-agentcore:GetGateway"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = local.mcp_discovery ? [1] : []
    content {
      sid    = "McpDiscovery"
      effect = "Allow"
      actions = [
        "bedrock-agentcore:ListGateways",
        "bedrock-agentcore:GetGateway",
        "bedrock-agentcore:ListGatewayTargets"
      ]
      resources = ["*"]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.agent_activity_readonly ? [1] : []
    content {
      sid    = "AgentActivity"
      effect = "Allow"
      actions = [
        # DescribeLogGroups also comes from SecurityAudit, but the two toggles
        # are independent: without it here, activity with security_audit off
        # can read groups it cannot find, and the feed is silently empty
        "logs:DescribeLogGroups",
        "logs:FilterLogEvents",
        "logs:GetLogEvents"
      ]
      resources = [
        # runtimes only: the broader bedrock-agentcore and vendedlogs wildcards
        # also cover Memory, whose records carry conversation content this
        # feature does not read and did not ask for
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/bedrock-agentcore/runtimes/*",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/vendedlogs/bedrock-agentcore/gateways/*",
        # both ARN forms: CloudWatch Logs presents a group with and without the
        # trailing :* depending on the call, and the suffixed form alone denies
        # every read of the shared span group while looking correctly set up
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:aws/spans",
        "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:aws/spans:*"
      ]
      dynamic "condition" {
        for_each = var.allowed_regions != null ? [1] : []
        content {
          test     = "StringEquals"
          variable = "aws:RequestedRegion"
          values   = var.allowed_regions
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_readonly && var.s3_tf_state_bucket_arns != null ? [1] : []
    content {
      sid    = "S3TFStateListObjects"
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ]
      resources = var.s3_tf_state_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_readonly ? var.s3_tf_state_bucket_tags : {}
    content {
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ]
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/${statement.key}"
        values   = [statement.value]
      }
    }
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_readonly && var.s3_tf_state_bucket_arns == null && length(var.s3_tf_state_bucket_tags) == 0 ? [1] : []
    content {
      sid    = "S3TFStateBucketsAutoDiscovery"
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets",
        "s3:ListBucket"
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_readonly ? [1] : []
    content {
      sid    = "S3TFStateGetObject"
      effect = "Allow"
      actions = [
        "s3:GetObject"
      ]
      resources = concat(["arn:aws:s3:::*/*tfstate"], coalesce(var.s3_tf_state_object_arns, []))
    }
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_readonly && length(var.s3_tf_state_bucket_tags) > 0 ? [1] : []
    content {
      sid    = "Tags"
      effect = "Allow"
      actions = [
        "tag:GetResources"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "this" {
  name   = local.role_name
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}
