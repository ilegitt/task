provider "aws" {
    region = var.aws_region
}

module "vpc" {
    source = "terraform-aws-modules/vpc/aws/"
    version = "~> 5.0"

    name = "${var.app_name}-vpc"
    cidr = "10.0.0.0/16"
    azs = ["${var.aws_region}a", "${var.aws_region}b"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
    enable_nat_gateway = true
    single_nat_gateway = true
}

resource "aws_ecs_cluster" "main" {
    name = "${var.app_name}-cluster"
}

resource "aws_lb" "main" {

    name = "${var.app_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb.id]
    subnets = module.vpc.public_subnets
}

resource "aws_lb_listener" "main" {
    load_balancer_arn = aws_lb.main.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.main.arn
    }

}

resource "aws_lb_target_group" "main" {
    name     = "${var.app_name}-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = module.vpc.vpc_id
}

resource "aws_db_instance" "main" {
    identifier = "${var.app_name}-db"
    engine = "postgres"
    engine_version = "15"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    username = var.db_username
    password = var.db_password
    db_subnet_group_name = aws_db_subnet_group.main.name
    vpc_security_group_ids = [aws_security_group.rds.id]
    skip_final_snapshot = true
}

resource "aws_db_subnet_group" "main" {
    name = "${var.app_name}-db-subnet-group"
    subnet_ids = module.vpc.private_subnets
}