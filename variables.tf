variable "aws_region" {
     default = "eu-north-1"
}

variable "app_name" {
     default = "go-app"
}

variable "ecr_repository_url" {
     type = string
}

variable "db_username" {
     type = string
}

variable "db_password" {
     type = string
     sensitive = true
}

variable "db_name" {
     default = "appdb"
}