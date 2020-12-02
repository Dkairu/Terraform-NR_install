provider "aws" {
      region = "us-east-1"
}

variable "count" {
  	default = 3
}
variable "azs" {
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
resource "aws_instance" "dan_terraform_example" {
        ami = "ami-5c66ea23"
        instance_type = "t2.micro"
        availability_zone = "${element(var.azs, count.index)}"
        key_name = "test-key"
        security_groups= ["EC2 Security"]
        count = "${var.count}"
	tags {
        Name = "NewRelic Web server ${count.index+1}"
	 }

	user_data = <<-EOF
		#!/bin/bash
		sudo apt-get install apache2 -y
		sudo sed -i 's/It\ works!/Server\ ${count.index+1} works!/g' /var/www/html/index.html
		echo "license_key: <ENTER LICENSE KEY HERE>" | sudo tee -a /etc/newrelic-infra.yml
		curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add -
			printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
		sudo apt-get update
		sudo apt-get install newrelic-infra -y
		EOF
}
resource "aws_elb" "dan_elb" {
	instances = ["${aws_instance.dan_terraform_example.*.id}"]
	cross_zone_load_balancing = true
	availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
	name = "ELB-TF"
	listener {
		instance_port = 80
    		instance_protocol = "http"
    		lb_port = 80
    		lb_protocol = "http"
 	}
}
output "addresses" {
	value = ["${aws_instance.dan_terraform_example.*.public_ip}"]
	value = ["${aws_elb.dan_elb.dns_name}"]
}
