##############################################################################
# Change Default Security Group (Optional)
##############################################################################

locals {
      security_group_rules = merge(
            {
                  # Allow traffic on peer subnets
                  # for i in var.cidr_blocks:
                  # "allow_traffic_subnet_${index(var.cidr_blocks, i) + 1}" => {
                  #       source    = i
                  #       direction = "inbound"
                  # }
            },
            var.security_group_rules
      )
}

resource ibm_is_security_group_rule default_vpc_sg_rules {
      for_each  = local.security_group_rules
      group     = ibm_is_vpc.vpc.default_security_group
      direction = each.value.direction
      remote    = each.value.source

      ##############################################################################
      # Dynamicaly create ICMP Block
      ##############################################################################

      dynamic icmp {

            # Runs a for each loop, if the rule block contains icmp, it looks through the block
            # Otherwise the list will be empty        

            for_each = (
                  contains(keys(each.value), "icmp")
                  ? [each.value]
                  : []
            )
                  # Conditianally add content if sg has icmp
                  content {
                        type = lookup(
                              lookup(
                                    each.value, 
                                    "icmp"
                              ), 
                              "type"
                        )
                        code = lookup(
                              lookup(
                                    each.value, 
                                    "icmp"
                              ), 
                              "code"
                        )
                  }
      } 

      ##############################################################################

      ##############################################################################
      # Dynamically create TCP Block
      ##############################################################################

      dynamic tcp {

            # Runs a for each loop, if the rule block contains tcp, it looks through the block
            # Otherwise the list will be empty     

            for_each = (
                  contains(keys(each.value), "tcp")
                  ? [each.value]
                  : []
            )

                  # Conditionally adds content if sg has tcp
                  content {

                        port_min = lookup(
                              lookup(
                                    each.value, 
                                    "tcp"
                              ), 
                              "port_min"
                        )

                        port_max = lookup(
                              lookup(
                                    each.value, 
                                    "tcp"
                              ), 
                              "port_max"
                        )
                  }
      } 

      ##############################################################################

      ##############################################################################
      # Dynamically create UDP Block
      ##############################################################################

      dynamic udp {

            # Runs a for each loop, if the rule block contains udp, it looks through the block
            # Otherwise the list will be empty     

            for_each = (
                  contains(keys(each.value), "udp")
                  ? [each.value]
                  : []
            )

                  # Conditionally adds content if sg has tcp
                  content {
                        port_min = lookup(
                              lookup(
                                    each.value, 
                                    "udp"
                              ), 
                              "port_min"
                        )
                        port_max = lookup(
                              lookup(
                                    each.value, 
                                    "udp"
                              ), 
                              "port_max"
                        )
                  }
      } 

      ##############################################################################

}

##############################################################################