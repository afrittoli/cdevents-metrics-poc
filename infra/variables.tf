##############################################################################
# Account Variables
##############################################################################

variable TF_VERSION {
 default     = "0.13"
 description = "The version of the Terraform engine that's used in the Schematics workspace."
}

variable ibmcloud_api_key {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
}

variable unique_id {
    description = "A unique identifier need to provision resources. Must begin with a letter"
    type        = string
    default     = "asset-multizone"

    validation  {
      error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
      condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.unique_id))
    }
}

variable ibm_region {
    description = "IBM Cloud region where all resources will be deployed"
    type        = string

    validation  {
      error_message = "Must use an IBM Cloud region. Use `ibmcloud regions` with the IBM Cloud CLI to see valid regions."
      condition     = can(
        contains([
          "au-syd",
          "jp-tok",
          "eu-de",
          "eu-gb",
          "us-south",
          "us-east"
        ], var.ibm_region)
      )
    }
}

variable resource_group {
    description = "Name of resource group where all infrastructure will be provisioned"
    type        = string
    default     = "asset-development"

    validation  {
      error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
      condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.resource_group))
    }
}

##############################################################################


##############################################################################
# Network variables
##############################################################################

variable classic_access {
  description = "Enable VPC Classic Access. Note: only one VPC per region can have classic access"
  type        = bool
  default     = false
}

variable enable_public_gateway {
  description = "Enable public gateways for subnets, true or false."
  type        = bool
  default     = false
}

variable cidr_blocks {
  description = "An object containing lists of CIDR blocks. Each CIDR block will be used to create a subnet"
  default     = {
    zone-1 = [
      "10.10.10.0/28",
      "10.20.10.0/28",
      "10.30.10.0/28"
    ],

    zone-2 = [
      "10.40.10.0/28",
      "10.50.10.0/28",
      "10.60.10.0/28"
    ],

    zone-3 = [
      "10.70.10.0/28",
      "10.80.10.0/28",
      "10.90.10.0/28"
    ]
  }

  validation {
    error_message = "The var.cidr_blocks objects must have 1, 2, or 3 keys."
    condition     = length(keys(var.cidr_blocks)) <= 3 && length(keys(var.cidr_blocks)) >= 1
  }

  validation {
    error_message = "Each list must have at least one CIDR block."
    condition     = length(distinct(
      [
        for zone in keys(var.cidr_blocks):
        false if length(var.cidr_blocks[zone]) == 0
      ]
    )) == 0
  }

  validation {
    error_message = "Each item in each list must contain a valid CIDR block."
    condition     = length(
      distinct(
        flatten([
          for zone in keys(var.cidr_blocks):
          false if length([
            for cidr in var.cidr_blocks[zone]:
            false if !can(regex("^(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2}).(2[0-5][0-9]|1[0-9]{1,2}|[0-9]{1,2})\\/(3[0-2]|2[0-9]|1[0-9]|[0-9])$", cidr))
          ]) > 0
        ])
      )
    ) == 0
  }

}

variable acl_rules {
  description = "Access control list rule set"
  default     = [
    {
      name        = "roks-create-worker-nodes-inbound"
      action      = "allow"
      source      = "161.26.0.0/16"
      destination = "0.0.0.0/0"
      direction   = "inbound"
    },
    {
      name        = "roks-nodes-to-service-inbound"
      action      = "allow"
      source      = "166.8.0.0/14"
      destination = "0.0.0.0/0"
      direction   = "inbound"
    },
        {
      name        = "roks-create-worker-nodes-outbound"
      action      = "allow"
      destination = "161.26.0.0/16"
      source      = "0.0.0.0/0"
      direction   = "outbound"
    },
    {
      name        = "roks-nodes-to-service-outbound"
      action      = "allow"
      destination = "166.8.0.0/14"
      source      = "0.0.0.0/0"
      direction   = "outbound"
    },
    {
      name        = "allow-all-inbound"
      action      = "allow"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
    },
    {
      name        = "allow-all-outbound"
      action      = "allow"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "outbound"
    }
  ]
  
  validation {
    error_message = "ACL Rules can only contain the fields `name`, `action`, `source`, `destination`, `direction`, `tcp`, `icmp` and `udp`."
    condition     = length(distinct(
      # Create a flat array of results
      flatten([
        # For each ACL object
        for rule in var.acl_rules: [
          # Check ACL rule keys
          for field in keys(rule): 
            # Return false if there are any invalid keys
            false if !contains(
              ["name", "action", "source", "destination", "direction", "tcp", "icmp", "udp"],
              field
            )
        ]
      ])
    )) == 0 # Should be 0 invalid keys
  }

  validation {
    error_message = "ACL rules can only have one of `icmp`, `udp`, or `tcp`."
    condition     = length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.acl_rules:
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for field in keys(rule):
            true if contains(["icmp","udp", "tcp"], field)
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }

  validation {
    error_message = "ACL rules must contain at least `name`, `action`, `source`, `destination`, and `direction` fields."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.acl_rules:
        # Return false if the keys do not contain all five fields
        false if length([
          for field in keys(rule):
          true if contains(["name", "action", "source", "destination", "direction"], field)
        ]) < 5
      ])
    )) == 0 # No object should contain less than 5 of the 5 required fields
  }

  validation {
    error_message = "ACL rule actions can only be `allow` or `deny`."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.acl_rules:
        # Return false action is not valid
        false if !contains(["allow", "deny"], rule.action)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule direction can only be `inbound` or `outbound`."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.acl_rules:
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.acl_rules:
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

  validation {
    error_message = "`tcp` blocks must contain the `port_min`, `port_max`, `source_port_min`, and `source_port_max` fields."
    condition     = length(distinct(
      flatten([
        # Get all rules with a `tcp` field
        for tcp_rule in [ for rule in var.acl_rules: rule.tcp if contains(keys(rule), "tcp")]: 
        # Return false if it does not contain all four fields
        false if length([
          for field in keys(tcp_rule):
          field if contains(["port_min", "port_max", "source_port_min", "source_port_max"], field)
        ]) != 4
      ])
    )) == 0
  }

  validation {
    error_message = "`udp` blocks must contain the `port_min`, `port_max`, `source_port_min`, and `source_port_max` fields."
    condition     = length(distinct(
      flatten([
        # Get all rules with `udp` field
        for udp_rule in [ for rule in var.acl_rules: rule.udp if contains(keys(rule), "udp")]: 
        # Return false if it does not contain all four fields
        false if length([
          for field in keys(udp_rule):
          field if contains(["port_min", "port_max", "source_port_min", "source_port_max"], field)
        ]) != 4
      ])
    )) == 0
  }

  validation {
    error_message = "`icmp` blocks must contain the `type` and `code` fields."
    condition     = length(distinct(
      flatten([
        # Get all rules with `icmp` field
        for icmp_rule in [ for rule in var.acl_rules: rule.icmp if contains(keys(rule), "icmp")]: 
        # Return false if it does not contain both fields
        false if length([
          for field in keys(icmp_rule):
          field if contains(["type", "code"], field)
        ]) != 2
      ])
    )) == 0
  }

}


variable security_group_rules {
  description = "List of security group rules to be added to default security group"
  default     = {
    allow_all_inbound = {
      source    = "0.0.0.0/0"
      direction = "inbound"
    }
  }

  validation {
    error_message = "Security group rules can only contain `direction`, `source`, `tcp`, `udp`, and `icmp` fields."
    condition     = length(flatten([
      # Convert rules from object to array and search
      for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
      # Return false if there are fields other than these five used
      false if length([
        for field in keys(rule):
        true if !contains(["direction", "source", "tcp", "udp", "icmp"], field)
      ]) > 0
    ])) == 0
  }

  validation {
    error_message = "Security group rules can only contain one `icmp`, `tcp`, or `udp` field."
    condition     = length(flatten([
      # Convert rules from object to array and search
      for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
      false if length([
        for field in keys(rule):
        true if contains(["icmp", "tcp", "udp"], field)
      ]) > 1
    ])) == 0
  }

  validation {
    error_message = "Security group rules must contain `direction` and `source` fields."
    condition     = length(flatten([
      # Convert rules from object to array and search
      for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
      false if length([
        for field in keys(rule):
        true if contains(["direction", "source"], field)
      ]) != 2
    ])) == 0 
  }

  validation {
    error_message = "Security group rules direction must be `inbound` or `outbound`."
    condition     = length(flatten([
      # Convert rules from object to array and search
      for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
      false if !contains(["inbound", "outbound"], rule.direction)
    ])) == 0 
  }
  
  validation {
    error_message = "Security group `tcp` blocks must contain `port_min` and `port_max` fields."
    condition     = length(flatten([
      for tcp_rule in [
        # Get TCP blocks from all rules
        for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
        rule.tcp if contains(keys(rule), "tcp")
      ]: 
      
      # If blocks do not contain both fields, return false
      false if length([
        for field in keys(tcp_rule):
        # Return true if search finds fields
        true if contains(["port_min", "port_max"], field)
      ]) != 2 
    ])) == 0
  }

  validation {
    error_message = "Security group `udp` blocks must contain `port_min` and `port_max` fields."
    condition     = length(flatten([
      for udp_rule in [
        # Get UDP blocks from all rules
        for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
        rule.udp if contains(keys(rule), "udp")
      ]: 
      
      # If blocks do not contain both fields, return false
      false if length([
        for field in keys(udp_rule):
        # Return true if search finds fields
        true if contains(["port_min", "port_max"], field)
      ]) != 2 
    ])) == 0
  }

  validation {
    error_message = "Security group `icmp` blocks must contain `type` and `code` fields."
    condition     = length(flatten([
      for icmp_rule in [
        # Get ICMP blocks from all rules
        for rule in [ for object_rule in keys(var.security_group_rules): var.security_group_rules[object_rule] ]:
        rule.icmp if contains(keys(rule), "icmp")
      ]: 
      
      # If blocks do not contain both fields, return false
      false if length([
        for field in keys(icmp_rule):
        # Return true if search finds fields
        true if contains(["type", "code"], field)
      ]) != 2 
    ])) == 0
  }

}

##############################################################################

