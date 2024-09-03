provider "aws" {
  region = "us-east-1" 
}

# Define input variable for the username
variable "user_name" {
  description = "The name of the IAM user to create"
  type        = string
}

# Data block to reference the existing ECS service role by name
data "aws_iam_role" "ecs_service_role" {
  name = "ecs_service_role"
}

# IAM User
resource "aws_iam_user" "user" {
  name = var.user_name
}

# Policy that allows the user to assume the ECS role
resource "aws_iam_policy" "assume_role_policy" {
  name        = "AssumeECSRolePolicy-${var.user_name}"
  description = "Policy that allows the user to assume the ECS role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = data.aws_iam_role.ecs_service_role.arn
      }
    ]
  })
}

# Attach the assume role policy to the user
resource "aws_iam_user_policy_attachment" "user_assume_role_policy_attachment" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

# Create Access Key for the user
resource "aws_iam_access_key" "user_access_key" {
  user = aws_iam_user.user.name
}

# Outputs
output "access_key_id" {
  description = "The access key ID for the user"
  value       = aws_iam_access_key.user_access_key.id
}

output "secret_access_key" {
  description = "The secret access key for the user"
  value       = aws_iam_access_key.user_access_key.secret
  sensitive   = true
}

output "user_name" {
  description = "The IAM username"
  value       = aws_iam_user.user.name
}

resource "null_resource" "save_secret_to_file" {
  # Use a trigger that changes on every apply
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
echo "AWS_ACCESS_KEY_ID=${aws_iam_access_key.user_access_key.id}" > .pmtl.env
echo "AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.user_access_key.secret}" >> .pmtl.env
EOT
  }
}

