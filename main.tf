# Define AWS provider
provider "aws" {
  region = "eu-central-1" # Change this to your desired region
}

# Create an ECR repository
resource "aws_ecr_repository" "paws_my_container_repository" {
  name = "paws-my-container-repo"
}

# Create an ECS cluster
resource "aws_ecs_cluster" "paws_my_cluster" {
  name = "paws-my-ecs-cluster"
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "paws_ecs_task_execution_role" {
  name = "paws-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach the AmazonECSTaskExecutionRolePolicy to the IAM role
resource "aws_iam_role_policy_attachment" "paws_ecs_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.paws_ecs_task_execution_role.name
}

# Create an ECS task definition
resource "aws_ecs_task_definition" "paws_my_task_definition" {
  family                   = "paws-my-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"                                         # Specify the CPU units for the task
  memory                   = "512"                                         # Specify the memory for the container
  execution_role_arn       = aws_iam_role.paws_ecs_task_execution_role.arn # Specify the execution role ARN

  container_definitions = jsonencode([{
    name  = "paws-my-container",
    image = "${aws_ecr_repository.paws_my_container_repository.repository_url}:latest",
    portMappings = [{
      containerPort = 80,
      hostPort      = 80,
    }]
  }])
}

# Create an ECS service
resource "aws_ecs_service" "paws_my_ecs_service" {
  name            = "paws-my-ecs-service"
  cluster         = aws_ecs_cluster.paws_my_cluster.id
  task_definition = aws_ecs_task_definition.paws_my_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Change as needed

  network_configuration {
    assign_public_ip = true
    subnets          = ["subnet-09562cafe82d33bcb"] # Replace with your subnet IDs
    security_groups  = ["sg-05262ba993d8ada20"]     # Replace with your security group IDs
  }

  #   load_balancer {
  #     target_group_arn = "arn:aws:elasticloadbalancing:region:account-id:targetgroup/paws-my-target-group/xxxxxxxxxxxxxxxxx" # Replace with your target group ARN
  #     container_name   = "paws-my-container"
  #     container_port   = 80
  #   }
}
