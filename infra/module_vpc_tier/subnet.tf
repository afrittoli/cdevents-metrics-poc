##############################################################################
# Locals
##############################################################################

locals {
  # Create a list of subnet objects from the CIDR blocks object by flattening all arrays into a single list
  subnet_list_from_object = flatten([
    # For each key in the object create an array
    for i in keys(var.cidr_blocks):
    # Each item in the list contains information about a single subnet
    [
      for j in var.cidr_blocks[i]:
      {
        zone      = index(keys(var.cidr_blocks), i) + 1                         # Zone 1, 2, or 3
        zone_name = "${var.ibm_region}-${index(keys(var.cidr_blocks), i) + 1}"  # Contains region and zone
        cidr      = j                                                           # Subnet CIDR block
        count     = index(var.cidr_blocks[i], j) + 1                            # Count of the subnet within the zone
      }
    ]
  ])
}

##############################################################################


##############################################################################
# Prefixes and subnets
# Name will be <unique_id>-prefix-zone-<zone>-subnet-<count>
##############################################################################

resource ibm_is_vpc_address_prefix subnet_prefix {
  count = length(local.subnet_list_from_object)
  name  = "${var.unique_id}-prefix-zone-${local.subnet_list_from_object[count.index].zone}-subnet-${local.subnet_list_from_object[count.index].count}" 
  zone  = local.subnet_list_from_object[count.index].zone_name
  vpc   = var.vpc_id
  cidr  = local.subnet_list_from_object[count.index].cidr
}

##############################################################################


##############################################################################
# Create Subnets
# Name will be <unique_id>-zone-<zone>-subnet-<number>
##############################################################################

resource ibm_is_subnet subnet {
  count                    = length(local.subnet_list_from_object)
  name                     = "${var.unique_id}-zone-${local.subnet_list_from_object[count.index].zone}-subnet-${local.subnet_list_from_object[count.index].count}"
  vpc                      = var.vpc_id
  resource_group           = var.resource_group
  zone                     = local.subnet_list_from_object[count.index].zone_name
  ipv4_cidr_block          = ibm_is_vpc_address_prefix.subnet_prefix[count.index].cidr
  network_acl              = var.enable_acl_id ? var.acl_id : null
  public_gateway           = length(var.public_gateways) == 0 ? null : var.public_gateways[local.subnet_list_from_object[count.index].zone - 1]
}

##############################################################################