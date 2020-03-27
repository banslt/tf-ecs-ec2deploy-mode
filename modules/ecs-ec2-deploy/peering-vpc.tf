data "aws_vpc" "master" {
  cidr_block = "172.22.0.0/16"
}

data "aws_caller_identity" "master" {
  provider = aws.master
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "master" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = data.aws_vpc.master.id
  peer_owner_id = data.aws_caller_identity.master.account_id
  peer_region   = var.aws_region
  auto_accept   = false
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "master" {
  provider                  = aws.master
  vpc_peering_connection_id = aws_vpc_peering_connection.master.id
  auto_accept               = true
}

# Creating routes between vpc
data "aws_route_tables" "main" {
  vpc_id= aws_vpc.main.id
  depends_on = [aws_route_table.private ]
}

data "aws_route_tables" "master" {
  provider    = aws.master
  vpc_id      = data.aws_vpc.master.id
}

resource "aws_route" "main_to_master" {
  route_table_id            = aws_vpc.main.main_route_table_id
  destination_cidr_block    = data.aws_vpc.master.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.master.id
    depends_on                = [aws_subnet.public]
}

# resource "aws_route" "master_to_main" {
#   provider                  = aws.master
#   route_table_id            = flatten(data.aws_route_tables.master.ids)[count.index]
#   destination_cidr_block    = aws_vpc.main.cidr_block
#   vpc_peering_connection_id = aws_vpc_peering_connection.master.id
#   depends_on                = [ aws_vpc_peering_connection.master,
#                                 aws_route.main_to_master
#    ]
# }
