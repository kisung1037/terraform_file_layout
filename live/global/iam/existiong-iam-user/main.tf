<<<<<<< HEAD
provider "aws" {
    region = "us-east-2"
}

# resource "aws_iam_user" "example" {
#     count = length(var.user_names)
#     name = var.user_names[count.index]
# }

# output "all_arns" {
#     value = aws_iam_user.example[*].arn
# }

resource "aws_iam_user" "example" {
    for_each = toset(var.user_names)
    name = each.value
}

output "all_users" {
    value = values(aws_iam_user.example)[*].arn
=======
provider "aws" {
    region = "us-east-2"
}

# resource "aws_iam_user" "example" {
#     count = length(var.user_names)
#     name = var.user_names[count.index]
# }

# output "all_arns" {
#     value = aws_iam_user.example[*].arn
# }

resource "aws_iam_user" "example" {
    for_each = toset(var.user_names)
    name = each.value
}

output "all_users" {
    value = values(aws_iam_user.example)[*].arn
>>>>>>> d0b4abce6cc41cdded5f03229212caa1df306ac0
}