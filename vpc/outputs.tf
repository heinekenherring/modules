output "subnet_ids" {
  value = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "vpc_id" {
  value = aws_vpc.eks.id
}

output "cidr_block" {
  value = aws_vpc.eks.cidr_block
}

output "network_acl_id" {
  value = aws_vpc.eks.default_network_acl_id
}