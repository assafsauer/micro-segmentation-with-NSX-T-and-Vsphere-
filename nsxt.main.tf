# Data Sources we need for reference later
data "nsxt_policy_transport_zone" "overlay_tz" {
    display_name = "Overlay"
}

data "nsxt_policy_edge_node" "edge_node_1" {
    edge_cluster_path   = data.nsxt_policy_edge_cluster.edge_cluster.path
    display_name        = "EDGE-1"  
}
 
data "nsxt_policy_transport_zone" "vlan_tz" {
    display_name = "VLAN"
}
 
data "nsxt_policy_edge_cluster" "edge_cluster" {
    display_name = "CLUSTER-EDGE-1"
}
 
data "nsxt_policy_service" "ssh" {
    display_name = "SSH"
}
 
data "nsxt_policy_service" "http" {
    display_name = "HTTP"
}
 
data "nsxt_policy_service" "https" {
    display_name = "HTTPS"
}
 
# NSX-T Manager Credentials
provider "nsxt" {
    host                     = var.nsx_manager
    username                 = var.username
    password                 = var.password
    allow_unverified_ssl     = true
    max_retries              = 10
    retry_min_delay          = 500
    retry_max_delay          = 5000
    retry_on_status_codes    = [429]
}





 
# Create NSX-T VLAN Segments
resource "nsxt_policy_vlan_segment" "vlan101" {
    display_name = "vlan101"
    description = "VLAN Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.vlan_tz.path
    vlan_ids = ["0"]
}
 
 
 
# Create Tier-0 Gateway
resource "nsxt_policy_tier0_gateway" "tier0_gw" {
    display_name              = "TF_Tier_0"
    description               = "Tier-0 provisioned by Terraform"
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = false
    enable_firewall           = false
    force_whitelisting        = true
    ha_mode                   = "ACTIVE_STANDBY"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
 
    bgp_config {
        ecmp            = false              
        local_as_num    = "65003"
        inter_sr_ibgp   = false
        multipath_relax = false
    }
 
    tag {
        scope = "color"
        tag   = "blue"
    }
}
 
# Create Tier-0 Gateway Uplink Interfaces
resource "nsxt_policy_tier0_gateway_interface" "uplink1" {
    display_name        = "Uplink-01"
    description         = "Uplink to VLAN101"
    type                = "EXTERNAL"
    edge_node_path      = data.nsxt_policy_edge_node.edge_node_1.path
    gateway_path        = nsxt_policy_tier0_gateway.tier0_gw.path
    segment_path        = nsxt_policy_vlan_segment.vlan101.path
    subnets             = ["192.168.1.13/24"]
    mtu                 = 1600
}
 




resource "nsxt_policy_tier1_gateway" "tier1_gw" {
    description               = "Tier-1 provisioned by Terraform"
    display_name              = "TF-Tier-1-01"
    nsx_id                    = "predefined_id"
    edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
    failover_mode             = "NON_PREEMPTIVE"
    default_rule_logging      = "false"
    enable_firewall           = "true"
    enable_standby_relocation = "false"
    force_whitelisting        = "true"
    tier0_path                = nsxt_policy_tier0_gateway.tier0_gw.path
    route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED" , "TIER1_NAT", "TIER1_LB_VIP"]

}
# Create NSX-T Overlay Segments
resource "nsxt_policy_segment" "tf2_segment_web" {
    display_name        = "isolated_net"
    description         = "Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
}
 
# Create NSX-T Overlay Segments
resource "nsxt_policy_segment" "tf_segment_web" {
    display_name        = "ms_overlay_segmant" 
    description         = "Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
    connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw.path
 
    subnet {   
        cidr        = "172.16.10.1/24"
        # dhcp_ranges = ["172.16.10.50-172.16.10.100"] 
     
        # dhcp_v4_config {
        #     lease_time  = 36000
        #     dns_servers = ["10.29.12.197"]
        # }
    }
} 




# Create NSX-T Overlay Segments
resource "nsxt_policy_segment" "t1_int" {
    display_name        = "ms_t1_int" 
    description         = "Segment created by Terraform"
    transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
}

resource "nsxt_policy_tier1_gateway_interface" "if1" {
  display_name           = "segment1_interface"
  description            = "connection to segment1"
  gateway_path           = nsxt_policy_tier1_gateway.tier1_gw.path
  segment_path           = nsxt_policy_segment.t1_int.path
  subnets                = ["10.4.1.1/24"]
  mtu                    = 1600
}

resource "nsxt_policy_static_route" "route1" {
  display_name = "sroute"
  gateway_path = nsxt_policy_tier0_gateway.tier0_gw.path
  network      = "0.0.0.0/0"

  next_hop {
    admin_distance = "2"
    ip_address     = "192.168.1.30"
  }

  next_hop {
    admin_distance = "4"
    ip_address = "192.168.1.1"
  }

  tag {
    scope = "color"
    tag   = "blue"
  }
}
