provider "aws" {
  region = var.region
}

# ---------------- VPC ----------------

resource "aws_vpc" "main_vpc" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ---------------- Public Subnets ----------------

resource "aws_subnet" "public_subnet" {
  count = 2

  vpc_id = aws_vpc.main_vpc.id

  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block,6,count.index)

  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index}"
  }
}

# ---------------- Private Subnets ----------------

resource "aws_subnet" "private_subnet" {
  count = 2

  vpc_id = aws_vpc.main_vpc.id

  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block,6,count.index + 2)

  # count.index + 2 → selects subnet 2 and subnet 3

  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index}"
  }
}

# ---------------- Internet Gateway ----------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ---------------- Public Route Table ----------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ---------------- Public Route Table Association ----------------

resource "aws_route_table_association" "public_assoc" {
  count = 2

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- NAT Gateway EIP ----------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  #Create this Elastic IP for use inside a VPC

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# ---------------- NAT Gateway ----------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id

  # NAT Gateway is placed in a PUBLIC subnet
  subnet_id = aws_subnet.public_subnet[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "${var.project_name}-nat"
  }
}

# ---------------- Private Route Table ----------------

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ---------------- Private Route Table Association ----------------

resource "aws_route_table_association" "private_assoc" {
  count = 2

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# ---------------- Security Groups ----------------

# Cluster SG

resource "aws_security_group" "cluster_sg" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-cluster-sg"
  }
}

# Node SG

resource "aws_security_group" "node_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Nodes can make outbound connections
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-node-sg"
  }
}

# ---------------- IAM ----------------

resource "aws_iam_role" "cluster_role" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# sts:AssumeRole = permission to take/use an IAM role

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---------------- Node IAM Role ----------------

resource "aws_iam_role" "node_role" {
  name = "${var.project_name}-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# ---------------- EKS Cluster ----------------

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  vpc_config {
    subnet_ids = aws_subnet.private_subnet[*].id

    security_group_ids = [
      aws_security_group.cluster_sg.id
    ]
  }
}

# ---------------- Node Group ----------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.node_role.arn

  # Worker nodes are placed in PRIVATE subnets
  subnet_ids = aws_subnet.private_subnet[*].id

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}

# ---------------- EKS ADDONS ----------------

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}