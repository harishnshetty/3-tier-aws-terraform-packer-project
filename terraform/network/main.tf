resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
  
}



# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
    tags = {
        Name        = "${var.project_name}-igw"
        Environment = var.environment
    }
}


# Public Subnets 1a
resource "aws_subnet" "public_subnets_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.public_subnets_1a
  availability_zone = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-1a"
    Environment = var.environment
  }
}
# Public Subnets 1b
resource "aws_subnet" "public_subnets_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.public_subnets_1b
  availability_zone = var.az2
  map_public_ip_on_launch = true    
    tags = {
        Name        = "${var.project_name}-public-subnet-1b"
        Environment = var.environment
    }
}
# Public Subnets 1c

resource "aws_subnet" "public_subnets_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.public_subnets_1c
  availability_zone = var.az3
  map_public_ip_on_launch = true    
    tags = {
        Name        = "${var.project_name}-public-subnet-1c"
        Environment = var.environment
    }
}

# Private Subnets Web 1a
resource "aws_subnet" "web_private_subnets_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.web_private_subnets_1a
  availability_zone = var.az1
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-web_private_subnets_1a"
        Environment = var.environment
    }
}



# Private Subnets Web 1b
resource "aws_subnet" "web_private_subnets_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.web_private_subnets_1b
  availability_zone = var.az2
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-web_private_subnets_1b"
        Environment = var.environment
    }
}

# Private Subnets Web 1c
resource "aws_subnet" "web_private_subnets_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.web_private_subnets_1c
  availability_zone = var.az3
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-web_private_subnets_1c"
        Environment = var.environment
    }
}   

# Private Subnets App 1a
resource "aws_subnet" "app_private_subnets_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.app_private_subnets_1a
  availability_zone = var.az1
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-app_private_subnets_1a"
        Environment = var.environment
    }
}

# Private Subnets App 1b
resource "aws_subnet" "app_private_subnets_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.app_private_subnets_1b
  availability_zone = var.az2
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-app_private_subnets_1b"
        Environment = var.environment
    }
}

# Private Subnets App 1a
resource "aws_subnet" "app_private_subnets_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.app_private_subnets_1c
  availability_zone = var.az3
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-app_private_subnets_1c"
        Environment = var.environment
    }
}

# Private Subnets Database 1a
resource "aws_subnet" "database_private_subnets_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.database_private_subnets_1a
  availability_zone = var.az1
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-database_private_subnets_1a"
        Environment = var.environment   
    }
}

# Private Subnets Database 1b
resource "aws_subnet" "database_private_subnets_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.database_private_subnets_1b
  availability_zone = var.az2
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-database_private_subnets_1b"
        Environment = var.environment   
    }
}

# Private Subnets Database 1c
resource "aws_subnet" "database_private_subnets_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block       = var.database_private_subnets_1c
  availability_zone = var.az3
  map_public_ip_on_launch = false
    tags = {
        Name        = "${var.project_name}-database_private_subnets_1a"
        Environment = var.environment   
    }
}

resource "aws_eip" "nat1a" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-1a"
    Environment = var.environment
  }
  
}

resource "aws_eip" "nat1b" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-1b"
    Environment = var.environment
  }
  
}


resource "aws_eip" "nat1c" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip-1c"
    Environment = var.environment
  }
  
}

resource "aws_nat_gateway" "nat1a" {
  allocation_id = aws_eip.nat1a.id
  subnet_id     = aws_subnet.public_subnets_1a.id

  tags = {
    Name        = "${var.project_name}-nat-gateway-1a"
    Environment = var.environment
  }
  
}

resource "aws_nat_gateway" "nat1b" {
  allocation_id = aws_eip.nat1b.id
  subnet_id     = aws_subnet.public_subnets_1b.id

  tags = {
    Name        = "${var.project_name}-nat-gateway-1b"
    Environment = var.environment
  }
  
}

resource "aws_nat_gateway" "nat1c" {
  allocation_id = aws_eip.nat1c.id
  subnet_id     = aws_subnet.public_subnets_1c.id

  tags = {
    Name        = "${var.project_name}-nat-gateway-1c"
    Environment = var.environment
  }
  
}

# Route Table for Public Subnets

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
    }
    tags = {
        Name        = "${var.project_name}-public-rt"
        Environment = var.environment
    }

}


# Route Table for Web Private Subnets
resource "aws_route_table" "web_private_rt_1a" {
  vpc_id = aws_vpc.main.id
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1a.id
    }
    tags = {
        Name        = "${var.project_name}-web-private-rt-1a"
        Environment = var.environment
    }
}

resource "aws_route_table" "web_private_rt_1b" {
  vpc_id = aws_vpc.main.id
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1b.id
    }
    tags = {
        Name        = "${var.project_name}-web-private-rt-1b"
        Environment = var.environment
    }
}

resource "aws_route_table" "web_private_rt_1c" {
  vpc_id = aws_vpc.main.id
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1c.id
    }
    tags = {
        Name        = "${var.project_name}-web-private-rt-1c"
        Environment = var.environment
    }
}

# Route Table for App Private Subnets
resource "aws_route_table" "app_private_rt_1a" {
  vpc_id = aws_vpc.main.id
    route { 
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1a.id
    }
    tags = {
        Name        = "${var.project_name}-app-private-rt-1a"
        Environment = var.environment
    }
}

resource "aws_route_table" "app_private_rt_1b" {
  vpc_id = aws_vpc.main.id
    route { 
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1b.id
    }
    tags = {
        Name        = "${var.project_name}-app-private-rt-1b"
        Environment = var.environment
    }
}

resource "aws_route_table" "app_private_rt_1c" {
  vpc_id = aws_vpc.main.id
    route { 
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1c.id
    }
    tags = {
        Name        = "${var.project_name}-app-private-rt-1c"
        Environment = var.environment
    }
}

# Route Table for Database Private Subnets
resource "aws_route_table" "database_private_rt_1a" {
  vpc_id = aws_vpc.main.id  
    route { 
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1a.id
    }
    tags = {
        Name        = "${var.project_name}-database-private-rt-1a"
        Environment = var.environment
    }
}

resource "aws_route_table" "database_private_rt_1b" {
  vpc_id = aws_vpc.main.id  
    route { 
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1b.id
    }
    tags = {
        Name        = "${var.project_name}-database-private-rt-1b"
        Environment = var.environment
    }
}


resource "aws_route_table" "database_private_rt_1c" {
  vpc_id = aws_vpc.main.id  
    route { 
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat1c.id
    }
    tags = {
        Name        = "${var.project_name}-database-private-rt-1c"
        Environment = var.environment
    }
}

# Route Table Associations
resource "aws_route_table_association" "public_rt_assoc_1a" {
  subnet_id      = aws_subnet.public_subnets_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_rt_assoc_1b" {
  subnet_id      = aws_subnet.public_subnets_1b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_rt_assoc_1c" {
  subnet_id      = aws_subnet.public_subnets_1c.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "web_private_rt_assoc_1a" {
  subnet_id      = aws_subnet.web_private_subnets_1a.id
  route_table_id = aws_route_table.web_private_rt_1a.id
}

resource "aws_route_table_association" "web_private_rt_assoc_1b" {
  subnet_id      = aws_subnet.web_private_subnets_1b.id
  route_table_id = aws_route_table.web_private_rt_1b.id
}

resource "aws_route_table_association" "web_private_rt_assoc_1c" {
  subnet_id      = aws_subnet.web_private_subnets_1c.id
  route_table_id = aws_route_table.web_private_rt_1c.id
}

resource "aws_route_table_association" "app_private_rt_assoc_1a" {
  subnet_id      = aws_subnet.app_private_subnets_1a.id
  route_table_id = aws_route_table.app_private_rt_1a.id
}

resource "aws_route_table_association" "app_private_rt_assoc_1b" {
  subnet_id      = aws_subnet.app_private_subnets_1b.id
  route_table_id = aws_route_table.app_private_rt_1b.id
}

resource "aws_route_table_association" "app_private_rt_assoc_1c" {
  subnet_id      = aws_subnet.app_private_subnets_1c.id
  route_table_id = aws_route_table.app_private_rt_1c.id
}

resource "aws_route_table_association" "database_private_rt_assoc_1a" {
  subnet_id      = aws_subnet.database_private_subnets_1a.id
  route_table_id = aws_route_table.database_private_rt_1a.id
}

resource "aws_route_table_association" "database_private_rt_assoc_1b" {
  subnet_id      = aws_subnet.database_private_subnets_1b.id
  route_table_id = aws_route_table.database_private_rt_1b.id
}


resource "aws_route_table_association" "database_private_rt_assoc_1c" {
  subnet_id      = aws_subnet.database_private_subnets_1c.id
  route_table_id = aws_route_table.database_private_rt_1c.id
}

resource "aws_security_group" "jump_sg" {
  name        = "${var.project_name}-jump_sg"
  description = "Security group for jump servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name        = "${var.project_name}-jump-sg"
    Environment = var.environment
  }
}


resource "aws_security_group" "frontend_alb_sg" {
  name        = "${var.project_name}-1_frontend_alb_sg"
  description = "Security group for frontend servers"
  vpc_id      = aws_vpc.main.id

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
    Name        = "${var.project_name}-1_frontend_alb_sg"
    Environment = var.environment
  }
}


resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-2_web_sg"
  description = "Security group for 2_web_sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb_sg.id]  
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-2_web_sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "backend_alb_sg" {
  name        = "${var.project_name}-3-backend-alb-sg"
  description = "Security group for 3 backend servers"
    vpc_id      = aws_vpc.main.id

    ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-3-backend-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "app-sg" {
  name        = "${var.project_name}-4-app-sg"
  description = "Security group for 4 app instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-4-app-sg"
    Environment = var.environment
  }
}



# Self-referencing SSH rule
resource "aws_security_group_rule" "app_sg_self_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app-sg.id
  source_security_group_id = aws_security_group.app-sg.id
}


resource "aws_security_group" "rds" {
  name        = "${var.project_name}-5-rds-sg"
  description = "Security group for 5 RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-5-rds-sg"
    Environment = var.environment
  }
}
