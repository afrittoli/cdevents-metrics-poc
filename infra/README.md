# Multizone VPC

This module creates a VPC with any number of subnets across 1, 2, or 3 zones. It will create an example ACL and can optionally create public gateways for each zone. 

![Multizone VPC](./.docs/multizone.png)

## Table of Contents

1. [VPC](##VPC)
2. [Subnets](##Subnets)
3. [Public Gateway](##public%20gateway)
4. [Access Control List (ACL)](##Access%20Control%20List)
5. [Module Variables](##module%20variables)
6. [Outputs](##Outputs)
7. [As a Module in a Larger Architecture](##As-a-Module-in-a-Larger-Architecture)

------

## VPC

This module creates a VPC in a single region inside a resource group.

Use IBM Cloud™ Virtual Private Cloud to create your own space in IBM Cloud™. A virtual private cloud (VPC) is a secure, isolated virtual network that combines the security of a private cloud with the availability and scalability of IBM's public cloud. <sup>[1](https://cloud.ibm.com/docs/vpc?topic=vpc-about-vpc)</sup>

### VPC Specific Variables

- `classic_access` - Can be `true` or `false`. 

- You can set up access from a VPC to your IBM Cloud classic infrastructure, including Direct Link connectivity. One VPC per region can communicate with classic resources.<sup>[2](https://cloud.ibm.com/docs/vpc?topic=vpc-about-vpc#about-classic-access)</sup>

#### More Info

- [Read more about VPC](https://cloud.ibm.com/docs/vpc?topic=vpc-about-vpc)

-------

## Subnets

This module creates any of number of subnets in each of up to 3 geographic zones in the region where the VPC was created.

Each subnet consists of a specified IP address range (CIDR block). Subnets are bound to a single zone, and they cannot span multiple zones or regions. Subnets in the same VPC are connected to each other. <sup>[3](https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc#subnets-in-the-vpc)</sup>

-----

## Public Gateway

This module can optionally create public gateways attached to the subnets.

A Public Gateway enables a subnet and all its attached virtual server instances to connect to the internet. Subnets are private by default. After a subnet is attached to the public gateway, all instances in that subnet can connect to the internet. Although each zone has only one public gateway, the public gateway can be attached to multiple subnets.<sup>[4](https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc#public-gateway-for-external-connectivity)</sup>

-----

## Access Control List

This module creates an ACL and attaches it to the subnets

You can use an access control list (ACL) to control all incoming and outgoing traffic in IBM Cloud™ Virtual Private Cloud. An ACL is a built-in, virtual firewall, similar to a security group. In contrast to security groups, ACL rules control traffic to and from the subnets, rather than to and from the instances.<sup>[5](https://cloud.ibm.com/docs/vpc?topic=vpc-using-acls)

-------

## Module Variables

Variable              | Type   | Description                                                                                  | Default
--------------------- | ------ | -------------------------------------------------------------------------------------------- |--------
ibmcloud_api_key      | string | The IBM Cloud platform API key needed to deploy IAM enabled resources                        | 
unique_id             | string | A unique identifier need to provision resources. Must begin with a letter                    | `"asset-multizone"`
ibm_region            | string | IBM Cloud region where all resources will be deployed                                        | 
resource_group        | string | Name of resource group where all infrastructure will be provisioned                          | `"asset-development"`
classic_access        | bool   | Enable VPC Classic Access. Note: only one VPC per region can have classic access             | `false`
enable_public_gateway | bool   | Enable public gateways for subnets, true or false.                                           | `true`
cidr_blocks           |        | An object containing lists of CIDR blocks. Each CIDR block will be used to create a subnet   | `{`<br>`zone-1 = [`<br>`"10.10.10.0/28",`<br>`"10.20.10.0/28",`<br>`"10.30.10.0/28" ],`<br>`zone-2 = [`<br>`"10.40.10.0/28",`<br>`"10.50.10.0/28",`<br>`"10.60.10.0/28" ],`<br>`zone-3 = [`<br>`"10.70.10.0/28",`<br>`"10.80.10.0/28",`<br>`"10.90.10.0/28" ]`<br>`}`
acl_rules             |        | Access control list rule set                                                                 | `[`<br>`{`<br>`name = "allow-all-inbound"`<br>`action = "allow"`<br>`source = "0.0.0.0/0"`<br>`destination = "0.0.0.0/0"`<br>`direction = "inbound"`<br>`},`<br>`{`<br>`name = "allow-all-outbound"`<br>`action = "allow"`<br>`source = "0.0.0.0/0"`<br>`destination = "0.0.0.0/0"`<br>`direction = "outbound"`<br>`}`<br>`]`
security_group_rules  | map    | List of security group rules to be added to default security group                 | `{`<br>`allow_all_inbound = {`<br>`source = "0.0.0.0/0"`<br>`direction = "inbound"`<br>`}`<br>`}
