provider "aws" {
    region = "us-east-2"
}

resource "aws_db_instance" "stage_db" {
    identifier_prefix = "terraform-up-and-running-stage"
    engine            = "mysql"
    allocated_storage = 10
    instance_class    = "db.t2.micro"
    db_name           = "stage_database"
    username          = "admin"
    skip_final_snapshot = true

    password = var.db_password
}



terraform {
  backend "s3" {
    bucket          = "terraform-up-and-running-state-nks"
    key             = "stage/data-stores/mysql/terraform.tfstate"
    region          = "us-east-2"

    dynamodb_table  = "terraform-up-and-running-locks"
    encrypt         = true
  }
}