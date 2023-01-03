provider "aws" {
    region = "us-east-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    clsuter_name           = "webservers-prod"
    db_remote_state_bucket = "terraform-up-and-running-state-nks"
    db_remote_state_key    = "prod/data-stores/mysql/terraform.tfstate"
}