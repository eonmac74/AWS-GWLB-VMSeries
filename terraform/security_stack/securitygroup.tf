# ---------------------------------------------------------------------------------------------------------------------
# CREATE SECURITY GROUPS
# 2 SG (FW MGMT, FW DATA)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "fw-mgmt-sg" {
  name        = "fw-mgmt-sg-${random_id.deployment_id.hex}"
  description = "Allow inbound traffic only from Palo Alto Networks"
  vpc_id      = aws_vpc.sec_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.fw_mgmt_sg_list
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "fw-mgmt-sg-${random_id.deployment_id.hex}"
    yor_trace = "23820905-24b2-4401-9686-6e030befc34d"
  }

  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_security_group" "fw-data-sg" {
  name        = "fw-data-sg-${random_id.deployment_id.hex}"
  description = "Allow inbound traffic only from GWLB"
  vpc_id      = aws_vpc.sec_vpc.id

  ingress {
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "fw-data-sg-${random_id.deployment_id.hex}"
    yor_trace = "8a249bec-d0d1-4957-91eb-c06efdad12de"
  }

  depends_on = [aws_vpc.sec_vpc]
}