provider "aws" {
  region = "us-east-1"
}
data "aws_ecs_task_definition" "dan_terraform_example" {
  depends_on      = [aws_ecs_task_definition.dan_terraform_example]
  task_definition = aws_ecs_task_definition.dan_terraform_example.family
}
resource "aws_ecs_cluster" "testnginx" {
  name = "test_cluster_nginx"
}
resource "aws_ecs_task_definition" "dan_terraform_example" {
  family                   = "nginx_with_NR1_infra"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  execution_role_arn       = <YOUR ECS TASK EXECUTION ROLE>
  container_definitions    = <<DEFINITION
  [
   {
      "name":"nginx",
      "image":"nginx:latest",
      "memory":256,
      "cpu":256,
      "portMappings":[
         {
            "containerPort":80,
            "protocol":"tcp"
         }
      ],
      "logConfiguration":{
            "logDriver":"awslogs",
            "options":{
               "awslogs-group":"/ecs/ngnx",
               "awslogs-region":"us-east-1",
               "awslogs-stream-prefix":"ecs"
            }
        }       
   },
   {
      "environment":[
         {
            "name":"NRIA_LICENSE_KEY",
            "value": <ENTER YOUR LICENSE>
         },        
         {
            "name":"NRIA_OVERRIDE_HOST_ROOT",
            "value":""
         },
         {
            "name":"NRIA_IS_FORWARD_ONLY",
            "value":"true"
         },
         {
            "name":"FARGATE",
            "value":"true"
         },
         {
            "name":"ENABLE_NRI_ECS",
            "value":"true"
         },
         {
            "name":"NRIA_PASSTHROUGH_ENVIRONMENT",
            "value":"ECS_CONTAINER_METADATA_URI,ENABLE_NRI_ECS,FARGATE"
         },
         {
            "name":"NRIA_CUSTOM_ATTRIBUTES",
            "value":"{\"nrDeployMethod\":\"downloadPage\"}"
         }
      ],
      "cpu":256,
      "memoryReservation":512,
      "image":"newrelic/infrastructure-bundle:1.6.0",
      "name":"newrelic-infra",
      "logConfiguration":{
            "logDriver":"awslogs",
            "options":{
               "awslogs-group":"/aws/connect/dantest",
               "awslogs-region":"us-east-1",
               "awslogs-stream-prefix":"ecs"
            }
        }          
   }
]
DEFINITION
}

resource "aws_ecs_service" "nrtest" {
  name            = "nrtest"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.testnginx.id
  desired_count   = 1
  task_definition = "${aws_ecs_task_definition.dan_terraform_example.family}:${max(aws_ecs_task_definition.dan_terraform_example.revision, data.aws_ecs_task_definition.dan_terraform_example.revision)}"
  network_configuration {
    subnets          = <YOUR SUBNETS>
    assign_public_ip = true
  }
}

provider "newrelic" {}

resource "newrelic_dashboard" "fargateexampledash" {
  title             = "AWS Fargate Dashboard"
  icon              = "line-chart"
  grid_column_count = 12
  widget {
    title      = "Tasks"
    nrql       = "SELECT filter(uniqueCount(`label.com.amazonaws.ecs.task-arn`), where status ='RUNNING') As Running, filter(uniqueCount(`label.com.amazonaws.ecs.task-arn`), where status = 'STOPPED') AS Stopped FROM ContainerSample "
    visualization = "billboard"
    width      = 4
    height     = 3
    row        = 1
    column     = 1
  }
  widget {
    title      = "Container Names"
    nrql       = "SELECT uniques(ecsContainerName) FROM ContainerSample"
    visualization = "uniques_list"
    width      = 4
    height     = 3
    row        = 1
    column     = 5
  }
  widget {
    title      = "Image Names"
    nrql       = "SELECT uniques(imageName) FROM ContainerSample"
    visualization = "uniques_list"
    width      = 4
    height     = 3
    row        = 1
    column     = 9
  }
  widget {
    title      = "Max CPU Limits "
    nrql       = "SELECT max(`docker.container.cpuLimitCores`) FROM Metric SINCE 30 MINUTES AGO TIMESERIES"
    visualization = "line_chart"
    width      = 4
    height     = 3
    row        = 4
    column     = 1
  }
  widget {
    title      = "CPU Usage "
    nrql       = "SELECT average(`docker.container.cpuPercent`*100) FROM Metric WHERE  ecsLaunchType ='fargate' SINCE 30 MINUTES AGO TIMESERIES facet docker.ecsContainerName"
    visualization = "faceted_line_chart"
    width      = 4
    height     = 3
    row        = 4
    column     = 5
  }
  widget {
    title      = "Memory Usage"
    nrql       = "SELECT latest(`docker.container.memoryUsageLimitPercent`*100) FROM Metric WHERE ecsLaunchType = 'fargate' SINCE 30 MINUTES AGO TIMESERIES facet docker.ecsContainerName"
    visualization = "faceted_line_chart"
    width      = 4
    height     = 3
    row        = 4
    column     = 9
  }
  widget {
    title      = "Network Requests(Bytes)"
    nrql       = "SELECT latest(`docker.container.networkRxBytesPerSecond`) FROM Metric WHERE ecsLaunchType = 'fargate' SINCE 30 MINUTES AGO TIMESERIES"
    visualization = "line_chart"
    width      = 4
    height     = 3
    row        = 7
    column     = 5
  }
  widget {
    title      = "Restart count"
    nrql       = "SELECT sum(`docker.container.restartCount`) FROM Metric WHERE ecsLaunchType = 'fargate' SINCE 30 MINUTES AGO"
    visualization = "billboard"
    width      = 4
    height     = 3
    row        = 7
    column     = 9
  }
}
output "dashboard_link" {
   value = newrelic_dashboard.fargateexampledash.dashboard_url
}