
# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE VPC, IGW, Subnets and NATGW
# 1 VPC
# 1 IGW
# SUBNETS (1 FW MGMT for each AZ, 1 FW DATA for each AZ, 1 GWLBE-OB for each AZ,
#          1 GWLBE-EW for each AZ, 1 TGW Attachment for each AZ,
#          1 NATGW for each AZ)
# 1 NATGW for each AZ
# 1 EIP for each NATGW
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "sec_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name      = "sec-vpc-${random_id.deployment_id.hex}"
    yor_trace = "004cda5f-6f42-4f7f-afd9-c522784afa02"
  }
}

resource "aws_internet_gateway" "sec_vpc_igw" {
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name      = "sec-vpc-igw-${random_id.deployment_id.hex}"
    yor_trace = "c6d66383-0543-427a-8979-dd1bcc166a10"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_mgmt_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/", [split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 0 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name      = "sec-mgmt-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "26efd219-928d-4dcc-b66b-8b913c6012fe"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_data_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/", [split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 5 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name      = "sec-data-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "95b412ab-9b7e-4e53-b99f-d84c2dc7be51"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_agwe_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/", [split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 10 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name      = "sec-gwlbe-ob-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "7409ab0b-b1ca-4cdc-bd3a-eee0ac1aec8b"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_agwe_ew_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/", [split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 15 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name      = "sec-gwlbe-ew-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "562149a1-e536-4a64-b112-d5414c33748d"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_tgwa_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/", [split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 20 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name      = "sec-tgwa-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "5d83e146-bb76-4e71-81b7-e6e7d7b4d1f1"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_subnet" "sec_natgw_subnet" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.sec_vpc.id
  cidr_block        = cidrsubnet(join("/", [split("/", aws_vpc.sec_vpc.cidr_block)[0], "23"]), 5, 25 + count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name      = "sec-natgw-subnet-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "95edc9ad-62dd-4769-922b-4ce3f4ad063a"
  }
  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_eip" "natgw_eip" {
  count      = length(var.availability_zones)
  vpc        = true
  depends_on = [aws_vpc.sec_vpc]
  tags = {
    yor_trace = "883a6334-1759-435b-bf1c-6eb6c4f9d260"
  }
}

resource "aws_nat_gateway" "sec_nat_gw" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.natgw_eip[count.index].id
  subnet_id     = aws_subnet.sec_natgw_subnet[count.index].id
  depends_on    = [aws_subnet.sec_natgw_subnet, aws_eip.natgw_eip]
  tags = {
    yor_trace = "96d31055-1045-4174-967b-0bcf648384c8"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE ROUTE TABLES AND ASSOCIATIONS
# ROUTE TABLES (FW MGMT, FW DATA, GWLBE, NATGW, TGWA)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_default_route_table" "main-mgmt-rt" {
  default_route_table_id = aws_vpc.sec_vpc.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sec_vpc_igw.id
  }

  tags = {
    Name      = "main-fw-mgmt-rt-${random_id.deployment_id.hex}"
    yor_trace = "69d6f6a3-c45c-4744-922b-258b7b84c271"
  }

  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_route_table_association" "main-mgmt-rt-association" {
  count     = length(var.availability_zones)
  subnet_id = aws_subnet.sec_mgmt_subnet[count.index].id

  route_table_id = aws_vpc.sec_vpc.main_route_table_id

  depends_on = [aws_subnet.sec_mgmt_subnet]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "fw-data-rt" {
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name      = "fw-data-rt-${random_id.deployment_id.hex}"
    yor_trace = "9e905d64-71e7-431d-9f5f-52302063dba8"
  }

  depends_on = [aws_vpc.sec_vpc]
}

resource "aws_route_table_association" "app-data-rt-association" {
  count     = length(var.availability_zones)
  subnet_id = aws_subnet.sec_data_subnet[count.index].id

  route_table_id = aws_route_table.fw-data-rt.id

  depends_on = [aws_subnet.sec_data_subnet, aws_route_table.fw-data-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "agwe-rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sec_nat_gw[count.index].id
  }

  tags = {
    Name      = "gwlbe-ob-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "f333b329-11d4-4429-a0ff-803153eb01f9"
  }

  depends_on = [aws_nat_gateway.sec_nat_gw]
}

resource "aws_route_table_association" "agwe-rt-association" {
  count     = length(var.availability_zones)
  subnet_id = aws_subnet.sec_agwe_subnet[count.index].id

  route_table_id = aws_route_table.agwe-rt[count.index].id

  depends_on = [aws_subnet.sec_agwe_subnet, aws_route_table.agwe-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "agwe-ew-rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name      = "gwlbe-ew-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "1833096e-902b-4380-a9f5-9884b79c880d"
  }
}

resource "aws_route_table_association" "agwe-ew-rt-association" {
  count     = length(var.availability_zones)
  subnet_id = aws_subnet.sec_agwe_ew_subnet[count.index].id

  route_table_id = aws_route_table.agwe-ew-rt[count.index].id

  depends_on = [aws_subnet.sec_agwe_ew_subnet, aws_route_table.agwe-ew-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "natgw-rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sec_vpc_igw.id
  }

  tags = {
    Name      = "natgw-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "c630134e-c5a5-4e71-9313-c450e1be4a10"
  }

  depends_on = [aws_subnet.sec_natgw_subnet]
}

resource "aws_route_table_association" "natgw-rt-association" {
  count     = length(var.availability_zones)
  subnet_id = aws_subnet.sec_natgw_subnet[count.index].id

  route_table_id = aws_route_table.natgw-rt[count.index].id

  depends_on = [aws_internet_gateway.sec_vpc_igw, aws_route_table.natgw-rt]
}

# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "tgwa-rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.sec_vpc.id

  tags = {
    Name      = "tgwa-rt-${var.availability_zones[count.index]}-${random_id.deployment_id.hex}"
    yor_trace = "3ab3dd1e-18aa-4087-b6b6-47cab28b00d6"
  }

  depends_on = [aws_subnet.sec_tgwa_subnet]
}

resource "aws_route_table_association" "tgwa-rt-association" {
  count     = length(var.availability_zones)
  subnet_id = aws_subnet.sec_tgwa_subnet[count.index].id

  route_table_id = aws_route_table.tgwa-rt[count.index].id

  depends_on = [aws_route_table.tgwa-rt]
}
