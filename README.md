# Terraform-NR_install
Example tf scripts for installing NR agents

`nr-infra_install-on-aws_ec2-example.tf`

The infra install example will spin up 3 ubuntu t2.micro servers, create a loadbalancer, install Apache web server and New Relic Infra agent and then rename the Apache index.html to show that all 3 servers are working, and then give values for the domains and IPs.

`nr-infra_install-on-fargate-example.tf`

The AWS fargate install example creates an ECS cluster, creates a task definition that has an nginx container and a newrelic infra container that runs as a sidecar collecting metrics about the nginx container, and a service that creates a web service from the task definition, then creates a New Relic Dashboard in insights and gives the link to that dashboard.