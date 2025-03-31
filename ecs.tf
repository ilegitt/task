resource "aws_ecs_task_definition" "app" {
    family = "${var.app_name}-task"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs_execution_role.arn

    container_definitions = jsonencode([{
        name = "${var.app_name}-container"
        image = "${var.ecr_repository_url}:latest"
        portMappings = [{
            containerPort = 8080
            hostPort      = 8080
        }]
        environment = [
            {
                name = "DB_HOST"
                value = aws_db_instance.main.address
            },
            {
                name = "DB_PORT"
                value = "5432"
            },
            {
                name = "DB_USER"
                value = var.db_username
            },
            {
                name = "DB_PASSWORD"
                value = var.db_password
            },
            {
                name = "DB_NAME"
                value = var.db_name
            }
        ]
    }])
}

# ECS Service
resource "aws_ecs_service" "app" {
    name = "${var.app_name}-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.app.arn
    launch_type = "FARGATE"
    desired_count = 1

    network_configuration {
        subnets = module.vpc.private_subnets
        security_groups = [aws_security_group.ecs.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.main.arn
        container_name = "${var.app_name}-container"
        container_port = 8080
    }
}

# Target Group
resource "aws_lb_target_group" "main" {
    name = "${var.app_name}-tg"
    port = 8080
    protocol = "HTTP"
    vpc_id = module.vpc.vpc_id
    target_type = "ip"
}