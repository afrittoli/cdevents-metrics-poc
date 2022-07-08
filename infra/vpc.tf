##############################################################################
# This file creates the VPC, Zones, subnets and public gateway for the VPC
# a separate file sets up the load balancers, listeners, pools and members
##############################################################################


##############################################################################
# Create a VPC
##############################################################################

resource ibm_is_vpc vpc {
  name           = "${var.unique_id}-vpc"
  resource_group = data.ibm_resource_group.resource_group.id
  classic_access = var.classic_access
}

##############################################################################


##############################################################################
# Public Gateways (Optional)
##############################################################################

resource ibm_is_public_gateway gateway {
  count          = var.enable_public_gateway ? length(keys(var.cidr_blocks)) : 0
  name           = "${var.unique_id}-public-gateway-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.resource_group.id
  zone           = "${var.ibm_region}-${count.index + 1}"
}

##############################################################################


##############################################################################
# Multizone subnets
##############################################################################

module subnets {
  source           = "./module_vpc_tier" 
  ibm_region       = var.ibm_region 
  unique_id        = var.unique_id                  
  acl_id           = ibm_is_network_acl.multizone_acl.id
  cidr_blocks      = var.cidr_blocks
  vpc_id           = ibm_is_vpc.vpc.id
  resource_group   = data.ibm_resource_group.resource_group.id
  public_gateways  = ibm_is_public_gateway.gateway.*.id
}

##############################################################################


