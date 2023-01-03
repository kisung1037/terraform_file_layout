provider "aws" {
    region = "us-east-2"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    clsuter_name           = "webservers-stage"
    db_remote_state_bucket = "terraform-up-and-running-state-nks"
    db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
}