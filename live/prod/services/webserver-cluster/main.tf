provider "aws" {
    region = "us-east-2"
}

module "webserver_cluster" {
    source = "github.com/kisung1037/terraform_upNrunning_modules//services/webserver-cluster?ref=v0.0.1"

    cluster_name           = "webservers-prod"
    db_remote_state_bucket = "terraform-up-and-running-state-nks"
    db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"

    instance_type = "t2.micro"
    min_size      = 1
    max_size      = 2
    enable_autoscaling = true

    custom_tags = {
        Owner      = "team-foo"
        DeployedBy = "terraform"
    }
}

# resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
#     scheduled_action_name = "scale_out_during_business_hours"
#     min_size         = 2
#     max_size         = 10
#     desired_capacity = 10
#     recurrence       = "0 9 * * *"

#     autoscaling_group_name = module.webserver_cluster.asg_name
# }

# resource "aws_autoscaling_schedule" "scale_in_at_night" {
#     scheduled_action_name = "scale_out_during_business_hours"
#     min_size         = 2
#     max_size         = 10
#     desired_capacity = 10
#     recurrence       = "0 17 * * *"

#     autoscaling_group_name = module.webserver_cluster.asg_name
# }

resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id

    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
}