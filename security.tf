# ALB security group

resource "aws_security_group" "alb" {
    name = "${var.app_name}-alb-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# ECS Security Group

resource "aws_security_group" "ecs" {
    name = "${var.app_name}-ecs-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# RDS Security group

resource "aws_security_group" "rds" {
    name = "${var.app_name}-rds-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [aws_security_group.ecs.id]
    }
}

# ECS Execution Role

resource "aws_iam_role" "ecs_execution_role" {
    name = "${var.app_name}-ecs-execution-role"

    assume_role_policy = jsonencode({
        version = "2012-10-17"
        statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {Service = "ecs-tasks.amazonaws.com"}
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy"{
    role = aws_iam_role.ecs_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}