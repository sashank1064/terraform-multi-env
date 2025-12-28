variable "Project" {

  default = "Roboshop"

}



/* variable "environment" {

### we dont need this, because we are using terraform workspaces now

  default = "dev"
} */

variable "common_tags" {
  default = {
    Project   = "Roboshop"
    terraform = "true"
  }
}

variable "sg_name" {
  default = "allow-all"
}

variable "sg_description" {
  default = "Allow all traffic from all IP"
}

variable "instances" {
  default = ["mongodb", "redis"]

}

variable "from_port" {
  default = 0

}

variable "to_port" {
  default = 0

}

variable "cidr_blocks" {
  default = ["0.0.0.0/0"]

}
variable "ami_id" {
  default = "ami-09c813fb71547fc4f"

}

variable "instance_type" {
  type = map(string)
  default = {
    dev = "t3.micro"
    prod = "t3.small"
  }
}