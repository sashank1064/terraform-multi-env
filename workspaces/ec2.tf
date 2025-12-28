resource "aws_instance" "roboshop" {
  count                  = length(var.instances)
  ami                    = var.ami_id
  instance_type          = lookup(var.instance_type, terraform.workspace)
  vpc_security_group_ids = [aws_security_group.allow_all.id]

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.Project}-${var.instances[count.index]}-${terraform.workspace}" # mongodb-dev, redis-dev
      Component   = var.instances[count.index]
      Environment = terraform.workspace
    }
  )
}

resource "aws_security_group" "allow_all" {
  name        = "${var.Project}-${var.sg_name}-${terraform.workspace}" # allow-all-dev
  description = var.sg_description

  ingress {
    from_port   = var.from_port
    to_port     = var.to_port
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }

  egress {
    from_port   = var.from_port
    to_port     = var.to_port
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.Project}-${var.sg_name}-${terraform.workspace}"
    }

  )
}