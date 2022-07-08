##############################################################################
# Outputs
##############################################################################

output subnet_ids {
  description = "IDs of subnets created for this tier"
  value       = ibm_is_subnet.subnet.*.id
}  

output subnet_detail_list {
  value       = {
    for zone_name in distinct(local.subnet_list_from_object.*.zone_name):
    zone_name => {
      for subnet in ibm_is_subnet.subnet: 
      subnet.name => {
        id = subnet.id
        cidr = subnet.ipv4_cidr_block 
      } if subnet.zone == zone_name
    }
  }
}

##############################################################################