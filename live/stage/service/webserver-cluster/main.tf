provider "aws" {
    region = "us-east-2"
}

module "webserver_cluster" {
    source = "github.com/kisung1037/terraform_upNrunning_modules//services/webserver-cluster?ref=v0.0.2"

    cluster_name           = "webservers-stage"
    db_remote_state_bucket = "terraform-up-and-running-state-nks"
    db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

    instance_type = "t2.micro"
    min_size      = 1
    max_size      = 2
}

resource "aws_security_group_rule" "allow_testing_inbound" {
    type = "ingress"
    security_group_id = module.webserver_cluster.alb_security_group_id

    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
}