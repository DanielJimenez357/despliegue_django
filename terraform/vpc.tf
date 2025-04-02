resource "aws_vpc" "vpc1" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnetPublica" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnetPrivada" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc1.id
}

resource "aws_route_table" "tablaEnrutamiento" {
    vpc_id = aws_vpc.vpc1.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "asociamientoSubnet" {
    subnet_id = aws_subnet.subnetPublica.id
    route_table_id = aws_route_table.tablaEnrutamiento.id
}


