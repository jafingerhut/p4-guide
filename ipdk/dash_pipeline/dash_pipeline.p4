#include <core.p4>
#include "dash_arch_specific.p4"

#include "dash_headers.p4"
#include "dash_metadata.p4"
#include "dash_parser.p4"
#include "dash_tunnel.p4"
#include "dash_outbound.p4"
#include "dash_inbound.p4"
#include "dash_conntrack.p4"
#include "underlay.p4"

#define MAX_ENI 64

control dash_ingress(
      inout headers_t hdr
    , inout metadata_t meta
#ifdef TARGET_BMV2_V1MODEL
    , inout standard_metadata_t standard_metadata
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
    , in    pna_main_input_metadata_t  istd
    , inout pna_main_output_metadata_t ostd
#endif // TARGET_DPDK_PNA
    )
{
    action drop_action() {
#ifdef TARGET_BMV2_V1MODEL
        mark_to_drop(standard_metadata);
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
        drop_packet();
#endif // TARGET_DPDK_PNA
    }

    action deny() {
        meta.dropped = true;
    }

    action accept() {
    }

#ifdef TARGET_BMV2_V1MODEL
    @SaiCounter[name="lb_fast_path_icmp_in", attr_type="stats"]
    counter(1, CounterType.packets_and_bytes) port_lb_fast_path_icmp_in_counter;
    @SaiCounter[name="lb_fast_path_eni_miss", attr_type="stats"]
    counter(1, CounterType.packets_and_bytes) port_lb_fast_path_eni_miss_counter;
#endif
    
    @SaiTable[name = "vip", api = "dash_vip"]
    table vip {
        key = {
            hdr.u0_ipv4.dst_addr : exact @SaiVal[name = "VIP", type="sai_ip_address_t"];
        }

        actions = {
            accept;
            @defaultonly deny;
        }

        const default_action = deny;
    }

    action set_outbound_direction() {
        meta.direction = dash_direction_t.OUTBOUND;
    }

    action set_inbound_direction() {
        meta.direction = dash_direction_t.INBOUND;
    }

    @SaiTable[name = "direction_lookup", api = "dash_direction_lookup"]
    table direction_lookup {
        key = {
            hdr.u0_vxlan.vni : exact @SaiVal[name = "VNI"];
        }

        actions = {
            set_outbound_direction;
            @defaultonly set_inbound_direction;
        }

        const default_action = set_inbound_direction;
    }

    action set_appliance(EthernetAddress neighbor_mac,
                         EthernetAddress mac) {
        meta.encap_data.underlay_dmac = neighbor_mac;
        meta.encap_data.underlay_smac = mac;
    }

    /* This table API should be implemented manually using underlay SAI */
    @SaiTable[ignored = "true"]
    table appliance {
        key = {
            meta.appliance_id : ternary;
        }

        actions = {
            set_appliance;
        }
    }

#define ACL_GROUPS_PARAM(prefix) \
    @SaiVal[type="sai_object_id_t"] bit<16> ## prefix ##_stage1_dash_acl_group_id, \
    @SaiVal[type="sai_object_id_t"] bit<16> ## prefix ##_stage2_dash_acl_group_id, \
    @SaiVal[type="sai_object_id_t"] bit<16> ## prefix ##_stage3_dash_acl_group_id, \
    @SaiVal[type="sai_object_id_t"] bit<16> ## prefix ##_stage4_dash_acl_group_id, \
    @SaiVal[type="sai_object_id_t"] bit<16> ## prefix ##_stage5_dash_acl_group_id

#define ACL_GROUPS_COPY_TO_META(prefix) \
   meta.stage1_dash_acl_group_id = ## prefix ##_stage1_dash_acl_group_id; \
   meta.stage2_dash_acl_group_id = ## prefix ##_stage2_dash_acl_group_id; \
   meta.stage3_dash_acl_group_id = ## prefix ##_stage3_dash_acl_group_id; \
   meta.stage4_dash_acl_group_id = ## prefix ##_stage4_dash_acl_group_id; \
   meta.stage5_dash_acl_group_id = ## prefix ##_stage5_dash_acl_group_id;

#ifdef TARGET_BMV2_V1MODEL
    @SaiCounter[name="lb_fast_path_icmp_in", attr_type="stats", action_names="set_eni_attrs"]
    counter(MAX_ENI, CounterType.packets_and_bytes) eni_lb_fast_path_icmp_in_counter;
#endif

    action set_eni_attrs(bit<32> cps,
                         bit<32> pps,
                         bit<32> flows,
                         bit<1> admin_state,
                         @SaiVal[type="sai_ip_address_t"] IPv4Address vm_underlay_dip,
                         @SaiVal[type="sai_uint32_t"] bit<24> vm_vni,
                         @SaiVal[type="sai_object_id_t"] bit<16> vnet_id,
                         IPv6Address pl_sip,
                         IPv6Address pl_sip_mask,
                         @SaiVal[type="sai_ip_address_t"] IPv4Address pl_underlay_sip,
                         @SaiVal[type="sai_object_id_t"] bit<16> v4_meter_policy_id,
                         @SaiVal[type="sai_object_id_t"] bit<16> v6_meter_policy_id,
                         @SaiVal[type="sai_dash_tunnel_dscp_mode_t"] dash_tunnel_dscp_mode_t dash_tunnel_dscp_mode,
                         @SaiVal[type="sai_uint8_t"] bit<6> dscp,
                         ACL_GROUPS_PARAM(inbound_v4),
                         ACL_GROUPS_PARAM(inbound_v6),
                         ACL_GROUPS_PARAM(outbound_v4),
                         ACL_GROUPS_PARAM(outbound_v6),
                         bit<1> disable_fast_path_icmp_flow_redirection) {
        meta.eni_data.cps             = cps;
        meta.eni_data.pps             = pps;
        meta.eni_data.flows           = flows;
        meta.eni_data.admin_state     = admin_state;
        meta.eni_data.pl_sip          = pl_sip;
        meta.eni_data.pl_sip_mask     = pl_sip_mask;
        meta.eni_data.pl_underlay_sip = pl_underlay_sip;
        meta.encap_data.underlay_dip  = vm_underlay_dip;
        if (dash_tunnel_dscp_mode == dash_tunnel_dscp_mode_t.PIPE_MODEL) {
            meta.eni_data.dscp = dscp;
        }
        /* vm_vni is the encap VNI used for tunnel between inbound DPU -> VM
         * and not a VNET identifier */
        meta.encap_data.vni           = vm_vni;
        meta.vnet_id                  = vnet_id;

        if (meta.is_overlay_ip_v6 == 1) {
            if (meta.direction == dash_direction_t.OUTBOUND) {
                ACL_GROUPS_COPY_TO_META(outbound_v6);
            } else {
                ACL_GROUPS_COPY_TO_META(inbound_v6);
            }
            meta.meter_policy_id = v6_meter_policy_id;
        } else {
            if (meta.direction == dash_direction_t.OUTBOUND) {
                ACL_GROUPS_COPY_TO_META(outbound_v4);
            } else {
                ACL_GROUPS_COPY_TO_META(inbound_v4);
            }
            meta.meter_policy_id = v4_meter_policy_id;
        }
        
        meta.fast_path_icmp_flow_redirection_disabled = disable_fast_path_icmp_flow_redirection;
    }

    @SaiTable[name = "eni", api = "dash_eni", order=1, isobject="true"]
    table eni {
        key = {
            meta.eni_id : exact @SaiVal[type="sai_object_id_t"];
        }

        actions = {
            set_eni_attrs;
            @defaultonly deny;
        }
        const default_action = deny;
    }

#ifdef TARGET_BMV2_V1MODEL
    direct_counter(CounterType.packets_and_bytes) eni_counter;
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
#ifdef DPDK_SUPPORTS_DIRECT_COUNTER_ON_WILDCARD_KEY_TABLE
    // Omit all direct counters for tables with ternary match keys,
    // because the latest version of p4c-dpdk as of 2023-Jan-26 does
    // not support this combination of features.  If you try to
    // compile it with this code enabled, the error message looks like
    // this:
    //
    // [--Werror=target-error] error: Direct counters and direct meters are unsupported for wildcard match table outbound_acl_stage1:dash_acl_rule|dash_acl
    //
    // This p4c issue is tracking this feature gap in p4c-dpdk:
    // https://github.com/p4lang/p4c/issues/3868
    DirectCounter<bit<64>>(PNA_CounterType_t.PACKETS_AND_BYTES) eni_counter;
#endif // DPDK_SUPPORTS_DIRECT_COUNTER_ON_WILDCARD_KEY_TABLE
#endif // TARGET_DPDK_PNA

    @SaiTable[ignored = "true"]
    table eni_meter {
        key = {
            meta.eni_id : exact @SaiVal[type="sai_object_id_t"];
            meta.direction : exact;
            meta.dropped : exact;
        }

        actions = { NoAction; }

#ifdef TARGET_BMV2_V1MODEL
        counters = eni_counter;
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
#ifdef DPDK_SUPPORTS_DIRECT_COUNTER_ON_WILDCARD_KEY_TABLE
        pna_direct_counter = eni_counter;
#endif // DPDK_SUPPORTS_DIRECT_COUNTER_ON_WILDCARD_KEY_TABLE
#endif // TARGET_DPDK_PNA
    }

    action permit() {
    }

    action tunnel_decap_pa_validate(@SaiVal[type="sai_object_id_t"] bit<16> src_vnet_id) {
        meta.vnet_id = src_vnet_id;
    }

    @SaiTable[name = "pa_validation", api = "dash_pa_validation"]
    table pa_validation {
        key = {
            meta.vnet_id: exact @SaiVal[type="sai_object_id_t"];
            hdr.u0_ipv4.src_addr : exact @SaiVal[name = "sip", type="sai_ip_address_t"];
        }

        actions = {
            permit;
            @defaultonly deny;
        }

        const default_action = deny;
    }

    @SaiTable[name = "inbound_routing", api = "dash_inbound_routing"]
    table inbound_routing {
        key = {
            meta.eni_id: exact @SaiVal[type="sai_object_id_t"];
            hdr.u0_vxlan.vni : exact @SaiVal[name = "VNI"];
            hdr.u0_ipv4.src_addr : ternary @SaiVal[name = "sip", type="sai_ip_address_t"];
        }
        actions = {
            tunnel_decap(hdr, meta);
            tunnel_decap_pa_validate;
            @defaultonly deny;
        }

        const default_action = deny;
    }

    action check_ip_addr_family(@SaiVal[type="sai_ip_addr_family_t", isresourcetype="true"] bit<32> ip_addr_family) {
        if (ip_addr_family == 0) /* SAI_IP_ADDR_FAMILY_IPV4 */ {
            if (meta.is_overlay_ip_v6 == 1) {
                meta.dropped = true;
            }
        } else {
            if (meta.is_overlay_ip_v6 == 0) {
                meta.dropped = true;
            }
        }
    }

    @SaiTable[name = "meter_policy", api = "dash_meter", order = 1, isobject="true"]
    table meter_policy {
        key = {
            meta.meter_policy_id : exact;
        }
        actions = {
            check_ip_addr_family;
        }
    }

    action set_policy_meter_class(bit<16> meter_class) {
        meta.policy_meter_class = meter_class;
    }

    @SaiTable[name = "meter_rule", api = "dash_meter", order = 2, isobject="true"]
    table meter_rule {
        key = {
            meta.meter_policy_id: exact @SaiVal[type="sai_object_id_t", isresourcetype="true", objects="METER_POLICY"];
            hdr.u0_ipv4.dst_addr : ternary @SaiVal[name = "dip", type="sai_ip_address_t"];
        }

     actions = {
            set_policy_meter_class;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
    }
    
    // MAX_METER_BUCKET = MAX_ENI(64) * NUM_BUCKETS_PER_ENI(4096)
    #define MAX_METER_BUCKETS 262144
#ifdef TARGET_BMV2_V1MODEL
    @SaiCounter[name="outbound", action_names="meter_bucket_action", attr_type="counter_attr"]
    counter(MAX_METER_BUCKETS, CounterType.bytes) meter_bucket_outbound;
    @SaiCounter[name="inbound", action_names="meter_bucket_action", attr_type="counter_attr"]
    counter(MAX_METER_BUCKETS, CounterType.bytes) meter_bucket_inbound;
#endif // TARGET_BMV2_V1MODEL
    action meter_bucket_action(@SaiVal[type="sai_uint32_t", skipattr="true"] bit<32> meter_bucket_index) {
        meta.meter_bucket_index = meter_bucket_index;
    }

    @SaiTable[name = "meter_bucket", api = "dash_meter", order = 0, isobject="true"]
    table meter_bucket {
        key = {
            meta.eni_id: exact @SaiVal[type="sai_object_id_t"];
            meta.meter_class: exact;
        }
        actions = {
            meter_bucket_action;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
    }

    action set_eni(@SaiVal[type="sai_object_id_t"] bit<16> eni_id) {
        meta.eni_id = eni_id;
    }

    @SaiTable[name = "eni_ether_address_map", api = "dash_eni", order=0]
    table eni_ether_address_map {
        key = {
            meta.eni_addr : exact @SaiVal[name = "address", type = "sai_mac_t"];
        }

        actions = {
            set_eni;
            @defaultonly deny;
        }
        const default_action = deny;
    }

    action set_acl_group_attrs(@SaiVal[type="sai_ip_addr_family_t", isresourcetype="true"] bit<32> ip_addr_family) {
        if (ip_addr_family == 0) /* SAI_IP_ADDR_FAMILY_IPV4 */ {
            if (meta.is_overlay_ip_v6 == 1) {
                meta.dropped = true;
            }
        } else {
            if (meta.is_overlay_ip_v6 == 0) {
                meta.dropped = true;
            }
        }
    }

    @SaiTable[name = "dash_acl_group", api = "dash_acl", order = 0, isobject="true"]
    table acl_group {
        key = {
            meta.stage1_dash_acl_group_id : exact @SaiVal[name = "dash_acl_group_id"];
        }
        actions = {
            set_acl_group_attrs();
        }
    }

    apply {

#ifdef TARGET_DPDK_PNA
#ifdef DPDK_PNA_SEND_TO_PORT_FIX_MERGED
        // As of 2023-Jan-26, the version of the pna.p4 header file
        // included with p4c defines send_to_port with a parameter
        // that has no 'in' direction.  The following commit in the
        // public pna repo fixes this, but this fix has not yet been
        // copied into the p4c repo.
        // https://github.com/p4lang/pna/commit/b9fdfb888e5385472c34ff773914c72b78b63058
        // Until p4c is updated with this fix, the following line will
        // give a compile-time error.
        send_to_port(istd.input_port);
#endif  // DPDK_PNA_SEND_TO_PORT_FIX_MERGED
#endif // TARGET_DPDK_PNA

        if (meta.is_fast_path_icmp_flow_redirection_packet) {
#ifdef TARGET_BMV2_V1MODEL
            port_lb_fast_path_icmp_in_counter.count(0);
#endif
        }

        if (vip.apply().hit) {
            /* Use the same VIP that was in packet's destination if it's
               present in the VIP table */
            meta.encap_data.underlay_sip = hdr.u0_ipv4.dst_addr;
        } else {
            if (meta.is_fast_path_icmp_flow_redirection_packet) {
#ifdef TARGET_BMV2_V1MODEL
                port_lb_fast_path_eni_miss_counter.count(0);
#endif
            }
        }

        /* If Outer VNI matches with a reserved VNI, then the direction is Outbound - */
        direction_lookup.apply();

        appliance.apply();

        // Save the original DSCP value
        meta.eni_data.dscp = (bit<6>)hdr.u0_ipv4.diffserv;

        /* Outer header processing */

        /* Put VM's MAC in the direction agnostic metadata field */
        meta.eni_addr = meta.direction == dash_direction_t.OUTBOUND  ?
                                          hdr.customer_ethernet.src_addr :
                                          hdr.customer_ethernet.dst_addr;

        if (!eni_ether_address_map.apply().hit) {
            if (meta.is_fast_path_icmp_flow_redirection_packet) {
#ifdef TARGET_BMV2_V1MODEL
                port_lb_fast_path_eni_miss_counter.count(0);
#endif
            }
        }

        if (meta.direction == dash_direction_t.OUTBOUND) {
            tunnel_decap(hdr, meta);
        } else if (meta.direction == dash_direction_t.INBOUND) {
            switch (inbound_routing.apply().action_run) {
                tunnel_decap_pa_validate: {
                    pa_validation.apply();
                    tunnel_decap(hdr, meta);
                }
            }
        }

        /* At this point the processing is done on customer headers */

        meta.is_overlay_ip_v6 = 0;
        meta.ip_protocol = 0;
        meta.dst_ip_addr = 0;
        meta.src_ip_addr = 0;
        if (hdr.customer_ipv6.isValid()) {
            meta.ip_protocol = hdr.customer_ipv6.next_header;
            meta.src_ip_addr = hdr.customer_ipv6.src_addr;
            meta.dst_ip_addr = hdr.customer_ipv6.dst_addr;
            meta.is_overlay_ip_v6 = 1;
        } else if (hdr.customer_ipv4.isValid()) {
            meta.ip_protocol = hdr.customer_ipv4.protocol;
            meta.src_ip_addr = (bit<128>)hdr.customer_ipv4.src_addr;
            meta.dst_ip_addr = (bit<128>)hdr.customer_ipv4.dst_addr;
        }

        if (hdr.customer_tcp.isValid()) {
            meta.src_l4_port = hdr.customer_tcp.src_port;
            meta.dst_l4_port = hdr.customer_tcp.dst_port;
        } else if (hdr.customer_udp.isValid()) {
            meta.src_l4_port = hdr.customer_udp.src_port;
            meta.dst_l4_port = hdr.customer_udp.dst_port;
        }

        eni.apply();
        if (meta.eni_data.admin_state == 0) {
            deny();
        }

        if (meta.is_fast_path_icmp_flow_redirection_packet) {
#ifdef TARGET_BMV2_V1MODEL
            eni_lb_fast_path_icmp_in_counter.count((bit<32>)meta.eni_id);
#endif
        }

        acl_group.apply();


        if (meta.direction == dash_direction_t.OUTBOUND) {
            outbound.apply(hdr, meta);
        } else if (meta.direction == dash_direction_t.INBOUND) {
            inbound.apply(hdr, meta);
        }

        /* Underlay routing */
        meta.dst_ip_addr = (bit<128>)hdr.u0_ipv4.dst_addr;
        underlay.apply(
              hdr
            , meta
    #ifdef TARGET_BMV2_V1MODEL
            , standard_metadata
    #endif // TARGET_BMV2_V1MODEL
    #ifdef TARGET_DPDK_PNA
            , istd
    #endif // TARGET_DPDK_PNA        
        );

        if (meta.meter_policy_en == 1) {
            meter_policy.apply();
            meter_rule.apply();
        }

        {
            if (meta.meter_policy_en == 1) {
                meta.meter_class = meta.policy_meter_class;
            } else {
                meta.meter_class = meta.route_meter_class;
            }
            if ((meta.meter_class == 0) || (meta.mapping_meter_class_override == 1)) {
                meta.meter_class = meta.mapping_meter_class;
            }
        }

        meter_bucket.apply();
        if (meta.direction == dash_direction_t.OUTBOUND) {
#ifdef TARGET_BMV2_V1MODEL
            meter_bucket_outbound.count(meta.meter_bucket_index);
#endif
        } else if (meta.direction == dash_direction_t.INBOUND) {
#ifdef TARGET_BMV2_V1MODEL
            meter_bucket_inbound.count(meta.meter_bucket_index);
#endif
        }

        if (meta.eni_data.dscp_mode == dash_tunnel_dscp_mode_t.PIPE_MODEL) {
            hdr.u0_ipv4.diffserv = (bit<8>)meta.eni_data.dscp;
        }

        eni_meter.apply();

        if (meta.dropped) {
            drop_action();
        }
    }
}

#ifdef TARGET_BMV2_V1MODEL
#include "dash_bmv2_v1model.p4"
#endif // TARGET_BMV2_V1MODEL
#ifdef TARGET_DPDK_PNA
#include "dash_dpdk_pna.p4"
#endif // TARGET_DPDK_PNA
