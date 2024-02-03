
struct ethernet_t {
	bit<48> dst_addr
	bit<48> src_addr
	bit<16> ether_type
}

struct ipv4_t {
	bit<8> version_ihl
	bit<8> diffserv
	bit<16> total_len
	bit<16> identification
	bit<16> flags_frag_offset
	bit<8> ttl
	bit<8> protocol
	bit<16> hdr_checksum
	bit<32> src_addr
	bit<32> dst_addr
}

struct ipv4options_t {
	varbit<320> options
}

struct ipv6_t {
	;oldname:version_traffic_class_flow_label
	bit<32> version_traffic_class_flow_la0
	bit<16> payload_length
	bit<8> next_header
	bit<8> hop_limit
	bit<128> src_addr
	bit<128> dst_addr
}

struct udp_t {
	bit<16> src_port
	bit<16> dst_port
	bit<16> length
	bit<16> checksum
}

struct tcp_t {
	bit<16> src_port
	bit<16> dst_port
	bit<32> seq_no
	bit<32> ack_no
	bit<16> data_offset_res_ecn_flags
	bit<16> window
	bit<16> checksum
	bit<16> urgent_ptr
}

struct vxlan_t {
	bit<8> flags
	bit<24> reserved
	bit<24> vni
	bit<8> reserved_2
}

struct dpdk_pseudo_header_t {
	bit<64> pseudo
	bit<64> pseudo_0
}

struct outbound_route_vnet_0_arg_t {
	bit<16> dst_vnet_id
}

struct outbound_route_vnet_direct_0_arg_t {
	bit<16> dst_vnet_id
	bit<32> is_overlay_ip_v4_or_v6
	bit<128> overlay_ip
}

struct outbound_set_tunnel_mapping_0_arg_t {
	bit<32> underlay_dip
	bit<48> overlay_dmac
	bit<32> use_dst_vnet_vni
}

struct outbound_set_vnet_attrs_0_arg_t {
	bit<24> vni
}

struct set_acl_group_attrs_arg_t {
	bit<32> ip_addr_family
}

struct set_appliance_arg_t {
	bit<48> neighbor_mac
	bit<48> mac
}

struct set_eni_arg_t {
	bit<16> eni_id
}

struct set_eni_attrs_arg_t {
	bit<32> cps
	bit<32> pps
	bit<32> flows
	bit<32> admin_state
	bit<32> vm_underlay_dip
	bit<24> vm_vni
	bit<16> vnet_id
	bit<16> inbound_v4_stage1_dash_acl_group_id
	bit<16> inbound_v4_stage2_dash_acl_group_id
	bit<16> inbound_v4_stage3_dash_acl_group_id
	bit<16> inbound_v4_stage4_dash_acl_group_id
	bit<16> inbound_v4_stage5_dash_acl_group_id
	bit<16> inbound_v6_stage1_dash_acl_group_id
	bit<16> inbound_v6_stage2_dash_acl_group_id
	bit<16> inbound_v6_stage3_dash_acl_group_id
	bit<16> inbound_v6_stage4_dash_acl_group_id
	bit<16> inbound_v6_stage5_dash_acl_group_id
	bit<16> outbound_v4_stage1_dash_acl_group_id
	bit<16> outbound_v4_stage2_dash_acl_group_id
	bit<16> outbound_v4_stage3_dash_acl_group_id
	bit<16> outbound_v4_stage4_dash_acl_group_id
	bit<16> outbound_v4_stage5_dash_acl_group_id
	bit<16> outbound_v6_stage1_dash_acl_group_id
	bit<16> outbound_v6_stage2_dash_acl_group_id
	bit<16> outbound_v6_stage3_dash_acl_group_id
	bit<16> outbound_v6_stage4_dash_acl_group_id
	bit<16> outbound_v6_stage5_dash_acl_group_id
}

struct vxlan_decap_pa_validate_arg_t {
	bit<16> src_vnet_id
}

header ethernet instanceof ethernet_t
header ipv4 instanceof ipv4_t
header ipv4options instanceof ipv4options_t
header ipv6 instanceof ipv6_t
header udp instanceof udp_t
header tcp instanceof tcp_t
header vxlan instanceof vxlan_t
header inner_ethernet instanceof ethernet_t
header inner_ipv4 instanceof ipv4_t
header inner_ipv6 instanceof ipv6_t
header inner_udp instanceof udp_t
header inner_tcp instanceof tcp_t
header MainControlT_hdr_0_udp instanceof udp_t
header MainControlT_hdr_0_vxlan instanceof vxlan_t
;oldname:MainControlT_hdr_0_inner_ethernet
header MainControlT_hdr_0_inner_ethe1 instanceof ethernet_t
header MainControlT_hdr_0_inner_ipv4 instanceof ipv4_t
header MainControlT_hdr_0_inner_ipv6 instanceof ipv6_t
header MainControlT_hdr_0_inner_udp instanceof udp_t
header MainControlT_hdr_0_inner_tcp instanceof tcp_t
header MainControlT_hdr_1_udp instanceof udp_t
header MainControlT_hdr_1_vxlan instanceof vxlan_t
;oldname:MainControlT_hdr_1_inner_ethernet
header MainControlT_hdr_1_inner_ethe2 instanceof ethernet_t
header MainControlT_hdr_1_inner_ipv4 instanceof ipv4_t
header MainControlT_hdr_1_inner_ipv6 instanceof ipv6_t
header MainControlT_hdr_1_inner_udp instanceof udp_t
header MainControlT_hdr_1_inner_tcp instanceof tcp_t
header MainControlT_hdr_7_udp instanceof udp_t
header MainControlT_hdr_7_vxlan instanceof vxlan_t
;oldname:MainControlT_hdr_7_inner_ethernet
header MainControlT_hdr_7_inner_ethe3 instanceof ethernet_t
header MainControlT_hdr_7_inner_ipv4 instanceof ipv4_t
header MainControlT_hdr_7_inner_ipv6 instanceof ipv6_t
header MainControlT_hdr_7_inner_udp instanceof udp_t
header MainControlT_hdr_7_inner_tcp instanceof tcp_t
header MainControlT_hdr_8_ethernet instanceof ethernet_t
header MainControlT_hdr_8_ipv4 instanceof ipv4_t
header MainControlT_hdr_8_ipv6 instanceof ipv6_t
header MainControlT_hdr_8_udp instanceof udp_t
header MainControlT_hdr_8_tcp instanceof tcp_t
header MainControlT_hdr_8_vxlan instanceof vxlan_t
;oldname:MainControlT_hdr_8_inner_ethernet
header MainControlT_hdr_8_inner_ethe4 instanceof ethernet_t
header MainControlT_hdr_8_inner_ipv4 instanceof ipv4_t
header MainControlT_hdr_8_inner_ipv6 instanceof ipv6_t
header MainControlT_hdr_8_inner_udp instanceof udp_t
header MainControlT_hdr_8_inner_tcp instanceof tcp_t
header MainControlT_hdr_9_ethernet instanceof ethernet_t
header MainControlT_hdr_9_ipv4 instanceof ipv4_t
header MainControlT_hdr_9_ipv6 instanceof ipv6_t
header MainControlT_hdr_9_udp instanceof udp_t
header MainControlT_hdr_9_tcp instanceof tcp_t
header MainControlT_hdr_9_vxlan instanceof vxlan_t
;oldname:MainControlT_hdr_9_inner_ethernet
header MainControlT_hdr_9_inner_ethe5 instanceof ethernet_t
header MainControlT_hdr_9_inner_ipv4 instanceof ipv4_t
header MainControlT_hdr_9_inner_ipv6 instanceof ipv6_t
header MainControlT_hdr_9_inner_udp instanceof udp_t
header MainControlT_hdr_9_inner_tcp instanceof tcp_t
header dpdk_pseudo_header instanceof dpdk_pseudo_header_t

struct metadata_t {
	bit<16> pna_pre_input_metadata_parser_error
	bit<32> pna_main_input_metadata_input_port
	bit<8> local_metadata__dropped0
	bit<16> local_metadata__direction1
	bit<24> local_metadata__encap_data_vni2
	bit<32> local_metadata__encap_data_underlay_sip4
	bit<32> local_metadata__encap_data_underlay_dip5
	bit<48> local_metadata__encap_data_underlay_smac6
	bit<48> local_metadata__encap_data_underlay_dmac7
	bit<48> local_metadata__encap_data_overlay_dmac8
	bit<48> local_metadata__eni_addr9
	bit<16> local_metadata__vnet_id10
	bit<16> local_metadata__dst_vnet_id11
	bit<16> local_metadata__eni_id12
	bit<32> local_metadata__eni_data_cps13
	bit<32> local_metadata__eni_data_pps14
	bit<32> local_metadata__eni_data_flows15
	bit<32> local_metadata__eni_data_admin_state16
	bit<8> local_metadata__appliance_id18
	bit<32> local_metadata__is_overlay_ip_v619
	bit<32> local_metadata__is_lkup_dst_ip_v620
	bit<8> local_metadata__ip_protocol21
	bit<128> local_metadata__dst_ip_addr22
	bit<128> local_metadata__src_ip_addr23
	bit<128> local_metadata__lkup_dst_ip_addr24
	bit<8> local_metadata__conntrack_data_allow_in25
	bit<8> local_metadata__conntrack_data_allow_out26
	bit<16> local_metadata__src_l4_port27
	bit<16> local_metadata__dst_l4_port28
	bit<16> local_metadata__stage1_dash_acl_group_id29
	bit<16> local_metadata__stage2_dash_acl_group_id30
	bit<16> local_metadata__stage3_dash_acl_group_id31
	bit<16> local_metadata__stage4_dash_acl_group_id32
	bit<16> local_metadata__stage5_dash_acl_group_id33
	bit<32> pna_main_output_metadata_output_port
	bit<32> dash_ingress_outbound_ConntrackOut_conntrackOut_retval
	bit<32> dash_ingress_outbound_ConntrackOut_conntrackOut_retval_0
	;oldname:dash_ingress_outbound_ConntrackOut_conntrackOut_ipv4_protocol
	bit<8> dash_ingress_outbound_ConntrackOut_conntrackOut_ipv4_protoc6
	bit<16> dash_ingress_outbound_ConntrackOut_conntrackOut_retval_1
	bit<16> dash_ingress_outbound_ConntrackOut_conntrackOut_retval_2
	;oldname:dash_ingress_outbound_ConntrackOut_conntrackOut_local_metadata__eni_id12
	bit<16> dash_ingress_outbound_ConntrackOut_conntrackOut_local_metad7
	bit<32> dash_ingress_outbound_ConntrackIn_conntrackIn_retval
	bit<32> dash_ingress_outbound_ConntrackIn_conntrackIn_retval_0
	bit<8> dash_ingress_outbound_ConntrackIn_conntrackIn_ipv4_protocol
	bit<16> dash_ingress_outbound_ConntrackIn_conntrackIn_retval_1
	bit<16> dash_ingress_outbound_ConntrackIn_conntrackIn_retval_2
	;oldname:dash_ingress_outbound_ConntrackIn_conntrackIn_local_metadata__eni_id12
	bit<16> dash_ingress_outbound_ConntrackIn_conntrackIn_local_metadat8
	;oldname:dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_to_pa_local_metadata__dst_vnet_id11
	bit<16> dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_to9
	;oldname:dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_to_pa_local_metadata__is_lkup_dst_ip_v620
	bit<32> dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_t10
	;oldname:dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_to_pa_local_metadata__lkup_dst_ip_addr24
	bit<128> dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_t11
	bit<32> dash_ingress_inbound_ConntrackIn_conntrackIn_retval
	bit<32> dash_ingress_inbound_ConntrackIn_conntrackIn_retval_0
	bit<8> dash_ingress_inbound_ConntrackIn_conntrackIn_ipv4_protocol
	bit<16> dash_ingress_inbound_ConntrackIn_conntrackIn_retval_1
	bit<16> dash_ingress_inbound_ConntrackIn_conntrackIn_retval_2
	;oldname:dash_ingress_inbound_ConntrackIn_conntrackIn_local_metadata__eni_id12
	bit<16> dash_ingress_inbound_ConntrackIn_conntrackIn_local_metadat12
	bit<32> dash_ingress_inbound_ConntrackOut_conntrackOut_retval
	bit<32> dash_ingress_inbound_ConntrackOut_conntrackOut_retval_0
	bit<8> dash_ingress_inbound_ConntrackOut_conntrackOut_ipv4_protocol
	bit<16> dash_ingress_inbound_ConntrackOut_conntrackOut_retval_1
	bit<16> dash_ingress_inbound_ConntrackOut_conntrackOut_retval_2
	;oldname:dash_ingress_inbound_ConntrackOut_conntrackOut_local_metadata__eni_id12
	bit<16> dash_ingress_inbound_ConntrackOut_conntrackOut_local_metad13
	bit<16> dash_ingress_eni_meter_local_metadata__eni_id12
	bit<16> dash_ingress_eni_meter_local_metadata__direction1
	bit<8> dash_ingress_eni_meter_local_metadata__dropped0
	bit<16> dash_ingress_pa_validation_local_metadata__vnet_id10
	bit<32> dash_ingress_pa_validation_ipv4_src_addr
	bit<24> dash_ingress_inbound_routing_vxlan_vni
	bit<32> dash_ingress_inbound_routing_ipv4_src_addr
	bit<8> MainParserT_parser_tmp
	bit<8> MainParserT_parser_tmp_0
	bit<8> MainParserT_parser_tmp_2
	bit<8> MainParserT_parser_tmp_3
	bit<8> MainParserT_parser_tmp_4
	bit<8> MainParserT_parser_tmp_6
	bit<8> MainParserT_parser_tmp_7
	bit<8> MainParserT_parser_tmp_9
	bit<8> MainParserT_parser_tmp_10
	bit<8> MainParserT_parser_tmp_11
	bit<8> MainParserT_parser_tmp_13
	bit<8> MainParserT_parser_tmp_14
	bit<8> MainParserT_parser_tmp_15
	bit<8> MainParserT_parser_tmp_16
	bit<8> MainParserT_parser_tmp_17
	bit<8> MainParserT_parser_tmp_18
	bit<16> MainParserT_parser_tmp_21
	bit<16> MainParserT_parser_tmp_22
	bit<8> MainParserT_parser_tmp_23
	bit<8> MainParserT_parser_tmp_24
	bit<8> MainParserT_parser_tmp_25
	bit<8> MainParserT_parser_tmp_26
	bit<16> MainControlT_tmp
	bit<16> MainControlT_tmp_0
	bit<16> MainControlT_tmp_1
	bit<32> MainControlT_tmp_3
	bit<16> MainControlT_tmp_4
	bit<16> MainControlT_tmp_5
	bit<16> MainControlT_tmp_6
	bit<16> MainControlT_tmp_8
	bit<16> MainControlT_tmp_9
	bit<16> MainControlT_tmp_10
	bit<32> MainControlT_tmp_12
	bit<16> MainControlT_tmp_13
	bit<16> MainControlT_tmp_14
	bit<16> MainControlT_tmp_15
	bit<16> MainControlT_tmp_17
	bit<16> MainControlT_tmp_18
	bit<16> MainControlT_tmp_19
	bit<32> MainControlT_tmp_21
	bit<16> MainControlT_tmp_22
	bit<16> MainControlT_tmp_23
	bit<16> MainControlT_tmp_24
	bit<16> MainControlT_tmp_26
	bit<16> MainControlT_tmp_27
	bit<16> MainControlT_tmp_28
	bit<32> MainControlT_tmp_30
	bit<16> MainControlT_tmp_31
	bit<16> MainControlT_tmp_32
	bit<16> MainControlT_tmp_33
	bit<8> MainControlT_tmp_35
	bit<8> MainControlT_tmp_36
	bit<16> MainControlT_tmp_37
	bit<16> MainControlT_tmp_38
	bit<16> MainControlT_tmp_39
	bit<8> MainControlT_tmp_40
	bit<8> MainControlT_tmp_41
	bit<16> MainControlT_tmp_42
	bit<16> MainControlT_tmp_43
	bit<16> MainControlT_tmp_44
	bit<16> MainControlT_inner_ip_len
	bit<16> MainControlT_inner_ip_len_0
	bit<48> MainControlT_tmp_45
	bit<48> MainControlT_inbound_tmp
	bit<8> MainControlT_outbound_acl_hasReturned
	bit<8> MainControlT_inbound_acl_hasReturned
	bit<32> MainControlT_retval
	bit<32> MainControlT_retval_0
	bit<16> MainControlT_retval_1
	bit<16> MainControlT_retval_2
	bit<32> MainControlT_retval_3
	bit<32> MainControlT_retval_4
	bit<16> MainControlT_retval_5
	bit<16> MainControlT_retval_6
	bit<32> MainControlT_retval_7
	bit<32> MainControlT_retval_8
	bit<16> MainControlT_retval_9
	bit<16> MainControlT_retval_10
	bit<32> MainControlT_retval_11
	bit<32> MainControlT_retval_12
	bit<16> MainControlT_retval_13
	bit<16> MainControlT_retval_14
	bit<32> MainParserT_parser_tmp_28_extract_tmp
	bit<8> new_timeout
	bit<8> timeout_id
	bit<8> new_timeout_0
	bit<8> timeout_id_0
	bit<8> new_timeout_1
	bit<8> timeout_id_1
	bit<8> new_timeout_2
	bit<8> timeout_id_2
}
metadata instanceof metadata_t

regarray direction size 0x100 initval 0
action NoAction args none {
	return
}

action vxlan_decap_1 args none {
	invalidate h.MainControlT_hdr_0_inner_ethe1
	invalidate h.MainControlT_hdr_0_inner_ipv4
	invalidate h.MainControlT_hdr_0_inner_ipv6
	invalidate h.MainControlT_hdr_0_vxlan
	invalidate h.MainControlT_hdr_0_udp
	invalidate h.MainControlT_hdr_0_inner_tcp
	invalidate h.MainControlT_hdr_0_inner_udp
	return
}

action outbound_ConntrackOut_conntrackOut_allow_0 args none {
	mov m.MainControlT_tmp h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp 0xA
	mov m.MainControlT_tmp_0 m.MainControlT_tmp
	and m.MainControlT_tmp_0 0x3F
	mov m.MainControlT_tmp_1 m.MainControlT_tmp_0
	and m.MainControlT_tmp_1 0x3F
	mov m.MainControlT_tmp_3 m.MainControlT_tmp_1
	and m.MainControlT_tmp_3 0x5
	jmpeq LABEL_END_55 m.MainControlT_tmp_3 0x0
	mov m.new_timeout 0x0
	rearm m.new_timeout
	LABEL_END_55 :	rearm
	mov m.local_metadata__conntrack_data_allow_out26 1
	return
}

action outbound_ConntrackOut_conntrackOut_miss_0 args none {
	mov m.MainControlT_tmp_4 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_4 0xA
	mov m.MainControlT_tmp_5 m.MainControlT_tmp_4
	and m.MainControlT_tmp_5 0x3F
	mov m.MainControlT_tmp_6 m.MainControlT_tmp_5
	and m.MainControlT_tmp_6 0x3F
	jmpneq LABEL_END_56 m.MainControlT_tmp_6 0x2
	jmpneq LABEL_END_56 m.local_metadata__direction1 0x2
	mov m.timeout_id 0x2
	learn outbound_ConntrackOut_conntrackOut_allow_0 m.timeout_id
	LABEL_END_56 :	return
}

action outbound_acl_permit_0 args none {
	return
}

action outbound_acl_permit_1 args none {
	return
}

action outbound_acl_permit_2 args none {
	return
}

action outbound_acl_permit_and_continue_0 args none {
	return
}

action outbound_acl_permit_and_continue_1 args none {
	return
}

action outbound_acl_permit_and_continue_2 args none {
	return
}

action outbound_acl_deny_0 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_acl_deny_1 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_acl_deny_2 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_acl_deny_and_continue_0 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_acl_deny_and_continue_1 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_acl_deny_and_continue_2 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_ConntrackIn_conntrackIn_allow_0 args none {
	mov m.MainControlT_tmp_8 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_8 0xA
	mov m.MainControlT_tmp_9 m.MainControlT_tmp_8
	and m.MainControlT_tmp_9 0x3F
	mov m.MainControlT_tmp_10 m.MainControlT_tmp_9
	and m.MainControlT_tmp_10 0x3F
	mov m.MainControlT_tmp_12 m.MainControlT_tmp_10
	and m.MainControlT_tmp_12 0x5
	jmpeq LABEL_END_58 m.MainControlT_tmp_12 0x0
	mov m.new_timeout_0 0x0
	rearm m.new_timeout_0
	LABEL_END_58 :	rearm
	mov m.local_metadata__conntrack_data_allow_in25 1
	return
}

action outbound_ConntrackIn_conntrackIn_miss_0 args none {
	mov m.MainControlT_tmp_13 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_13 0xA
	mov m.MainControlT_tmp_14 m.MainControlT_tmp_13
	and m.MainControlT_tmp_14 0x3F
	mov m.MainControlT_tmp_15 m.MainControlT_tmp_14
	and m.MainControlT_tmp_15 0x3F
	jmpneq LABEL_END_59 m.MainControlT_tmp_15 0x2
	jmpneq LABEL_END_59 m.local_metadata__direction1 0x1
	mov m.timeout_id_0 0x2
	learn outbound_ConntrackIn_conntrackIn_allow_0 m.timeout_id_0
	LABEL_END_59 :	return
}

action outbound_route_vnet_0 args instanceof outbound_route_vnet_0_arg_t {
	mov m.local_metadata__dst_vnet_id11 t.dst_vnet_id
	return
}

action outbound_route_vnet_direct_0 args instanceof outbound_route_vnet_direct_0_arg_t {
	mov m.local_metadata__dst_vnet_id11 t.dst_vnet_id
	mov m.local_metadata__lkup_dst_ip_addr24 t.overlay_ip
	mov m.local_metadata__is_lkup_dst_ip_v620 t.is_overlay_ip_v4_or_v6
	return
}

action outbound_route_direct_0 args none {
	return
}

action outbound_drop_0 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_drop_1 args none {
	mov m.local_metadata__dropped0 1
	return
}

action outbound_set_tunnel_mapping_0 args instanceof outbound_set_tunnel_mapping_0_arg_t {
	jmpneq LABEL_END_61 t.use_dst_vnet_vni 0x1
	mov m.local_metadata__vnet_id10 m.local_metadata__dst_vnet_id11
	LABEL_END_61 :	mov m.local_metadata__encap_data_overlay_dmac8 t.overlay_dmac
	mov m.local_metadata__encap_data_underlay_dip5 t.underlay_dip
	return
}

action outbound_set_vnet_attrs_0 args instanceof outbound_set_vnet_attrs_0_arg_t {
	mov m.local_metadata__encap_data_vni2 t.vni
	return
}

action inbound_ConntrackIn_conntrackIn_allow_0 args none {
	mov m.MainControlT_tmp_17 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_17 0xA
	mov m.MainControlT_tmp_18 m.MainControlT_tmp_17
	and m.MainControlT_tmp_18 0x3F
	mov m.MainControlT_tmp_19 m.MainControlT_tmp_18
	and m.MainControlT_tmp_19 0x3F
	mov m.MainControlT_tmp_21 m.MainControlT_tmp_19
	and m.MainControlT_tmp_21 0x5
	jmpeq LABEL_END_62 m.MainControlT_tmp_21 0x0
	mov m.new_timeout_1 0x0
	rearm m.new_timeout_1
	LABEL_END_62 :	rearm
	mov m.local_metadata__conntrack_data_allow_in25 1
	return
}

action inbound_ConntrackIn_conntrackIn_miss_0 args none {
	mov m.MainControlT_tmp_22 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_22 0xA
	mov m.MainControlT_tmp_23 m.MainControlT_tmp_22
	and m.MainControlT_tmp_23 0x3F
	mov m.MainControlT_tmp_24 m.MainControlT_tmp_23
	and m.MainControlT_tmp_24 0x3F
	jmpneq LABEL_END_63 m.MainControlT_tmp_24 0x2
	jmpneq LABEL_END_63 m.local_metadata__direction1 0x1
	mov m.timeout_id_1 0x2
	learn outbound_ConntrackIn_conntrackIn_allow_0 m.timeout_id_1
	LABEL_END_63 :	return
}

action inbound_acl_permit_0 args none {
	return
}

action inbound_acl_permit_1 args none {
	return
}

action inbound_acl_permit_2 args none {
	return
}

action inbound_acl_permit_and_continue_0 args none {
	return
}

action inbound_acl_permit_and_continue_1 args none {
	return
}

action inbound_acl_permit_and_continue_2 args none {
	return
}

action inbound_acl_deny_0 args none {
	mov m.local_metadata__dropped0 1
	return
}

action inbound_acl_deny_1 args none {
	mov m.local_metadata__dropped0 1
	return
}

action inbound_acl_deny_2 args none {
	mov m.local_metadata__dropped0 1
	return
}

action inbound_acl_deny_and_continue_0 args none {
	mov m.local_metadata__dropped0 1
	return
}

action inbound_acl_deny_and_continue_1 args none {
	mov m.local_metadata__dropped0 1
	return
}

action inbound_acl_deny_and_continue_2 args none {
	mov m.local_metadata__dropped0 1
	return
}

action inbound_ConntrackOut_conntrackOut_allow_0 args none {
	mov m.MainControlT_tmp_26 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_26 0xA
	mov m.MainControlT_tmp_27 m.MainControlT_tmp_26
	and m.MainControlT_tmp_27 0x3F
	mov m.MainControlT_tmp_28 m.MainControlT_tmp_27
	and m.MainControlT_tmp_28 0x3F
	mov m.MainControlT_tmp_30 m.MainControlT_tmp_28
	and m.MainControlT_tmp_30 0x5
	jmpeq LABEL_END_65 m.MainControlT_tmp_30 0x0
	mov m.new_timeout_2 0x0
	rearm m.new_timeout_2
	LABEL_END_65 :	rearm
	mov m.local_metadata__conntrack_data_allow_out26 1
	return
}

action inbound_ConntrackOut_conntrackOut_miss_0 args none {
	mov m.MainControlT_tmp_31 h.tcp.data_offset_res_ecn_flags
	shr m.MainControlT_tmp_31 0xA
	mov m.MainControlT_tmp_32 m.MainControlT_tmp_31
	and m.MainControlT_tmp_32 0x3F
	mov m.MainControlT_tmp_33 m.MainControlT_tmp_32
	and m.MainControlT_tmp_33 0x3F
	jmpneq LABEL_END_66 m.MainControlT_tmp_33 0x2
	jmpneq LABEL_END_66 m.local_metadata__direction1 0x2
	mov m.timeout_id_2 0x2
	learn outbound_ConntrackOut_conntrackOut_allow_0 m.timeout_id_2
	LABEL_END_66 :	return
}

action deny args none {
	mov m.local_metadata__dropped0 1
	return
}

action deny_0 args none {
	mov m.local_metadata__dropped0 1
	return
}

action deny_2 args none {
	mov m.local_metadata__dropped0 1
	return
}

action deny_3 args none {
	mov m.local_metadata__dropped0 1
	return
}

action deny_4 args none {
	mov m.local_metadata__dropped0 1
	return
}

action accept_1 args none {
	return
}

action set_outbound_direction args none {
	mov m.local_metadata__direction1 0x1
	return
}

action set_inbound_direction args none {
	mov m.local_metadata__direction1 0x2
	return
}

action set_appliance args instanceof set_appliance_arg_t {
	mov m.local_metadata__encap_data_underlay_dmac7 t.neighbor_mac
	mov m.local_metadata__encap_data_underlay_smac6 t.mac
	return
}

action set_eni_attrs args instanceof set_eni_attrs_arg_t {
	mov m.local_metadata__eni_data_cps13 t.cps
	mov m.local_metadata__eni_data_pps14 t.pps
	mov m.local_metadata__eni_data_flows15 t.flows
	mov m.local_metadata__eni_data_admin_state16 t.admin_state
	mov m.local_metadata__encap_data_underlay_dip5 t.vm_underlay_dip
	mov m.local_metadata__encap_data_vni2 t.vm_vni
	mov m.local_metadata__vnet_id10 t.vnet_id
	jmpneq LABEL_FALSE_64 m.local_metadata__is_overlay_ip_v619 0x1
	jmpneq LABEL_FALSE_65 m.local_metadata__direction1 0x1
	mov m.local_metadata__stage1_dash_acl_group_id29 t.outbound_v6_stage1_dash_acl_14
	mov m.local_metadata__stage2_dash_acl_group_id30 t.outbound_v6_stage2_dash_acl_15
	mov m.local_metadata__stage3_dash_acl_group_id31 t.outbound_v6_stage3_dash_acl_16
	mov m.local_metadata__stage4_dash_acl_group_id32 t.outbound_v6_stage4_dash_acl_17
	mov m.local_metadata__stage5_dash_acl_group_id33 t.outbound_v6_stage5_dash_acl_18
	jmp LABEL_END_68
	LABEL_FALSE_65 :	mov m.local_metadata__stage1_dash_acl_group_id29 t.inbound_v6_stage1_dash_acl_g19
	mov m.local_metadata__stage2_dash_acl_group_id30 t.inbound_v6_stage2_dash_acl_g20
	mov m.local_metadata__stage3_dash_acl_group_id31 t.inbound_v6_stage3_dash_acl_g21
	mov m.local_metadata__stage4_dash_acl_group_id32 t.inbound_v6_stage4_dash_acl_g22
	mov m.local_metadata__stage5_dash_acl_group_id33 t.inbound_v6_stage5_dash_acl_g23
	jmp LABEL_END_68
	LABEL_FALSE_64 :	jmpneq LABEL_FALSE_66 m.local_metadata__direction1 0x1
	mov m.local_metadata__stage1_dash_acl_group_id29 t.outbound_v4_stage1_dash_acl_24
	mov m.local_metadata__stage2_dash_acl_group_id30 t.outbound_v4_stage2_dash_acl_25
	mov m.local_metadata__stage3_dash_acl_group_id31 t.outbound_v4_stage3_dash_acl_26
	mov m.local_metadata__stage4_dash_acl_group_id32 t.outbound_v4_stage4_dash_acl_27
	mov m.local_metadata__stage5_dash_acl_group_id33 t.outbound_v4_stage5_dash_acl_28
	jmp LABEL_END_68
	LABEL_FALSE_66 :	mov m.local_metadata__stage1_dash_acl_group_id29 t.inbound_v4_stage1_dash_acl_g29
	mov m.local_metadata__stage2_dash_acl_group_id30 t.inbound_v4_stage2_dash_acl_g30
	mov m.local_metadata__stage3_dash_acl_group_id31 t.inbound_v4_stage3_dash_acl_g31
	mov m.local_metadata__stage4_dash_acl_group_id32 t.inbound_v4_stage4_dash_acl_g32
	mov m.local_metadata__stage5_dash_acl_group_id33 t.inbound_v4_stage5_dash_acl_g33
	LABEL_END_68 :	return
}

action permit args none {
	return
}

action vxlan_decap_pa_validate args instanceof vxlan_decap_pa_validate_arg_t {
	mov m.local_metadata__vnet_id10 t.src_vnet_id
	return
}

action set_eni args instanceof set_eni_arg_t {
	mov m.local_metadata__eni_id12 t.eni_id
	return
}

action set_acl_group_attrs args instanceof set_acl_group_attrs_arg_t {
	jmpneq LABEL_FALSE_67 t.ip_addr_family 0x0
	jmpneq LABEL_END_71 m.local_metadata__is_overlay_ip_v619 0x1
	mov m.local_metadata__dropped0 1
	jmp LABEL_END_71
	jmp LABEL_END_71
	LABEL_FALSE_67 :	jmpneq LABEL_END_71 m.local_metadata__is_overlay_ip_v619 0x0
	mov m.local_metadata__dropped0 1
	LABEL_END_71 :	return
}

table outbound_acl_stage1_dash_acl_rule_dash_acl {
	key {
		m.local_metadata__stage1_dash_acl_group_id29 exact
		m.local_metadata__dst_ip_addr22 wildcard
		m.local_metadata__src_ip_addr23 wildcard
		m.local_metadata__ip_protocol21 wildcard
		m.local_metadata__src_l4_port27 wildcard
		m.local_metadata__dst_l4_port28 wildcard
	}
	actions {
		outbound_acl_permit_0
		outbound_acl_permit_and_continue_0
		outbound_acl_deny_0
		outbound_acl_deny_and_continue_0
	}
	default_action outbound_acl_deny_0 args none 
	size 0x10000
}


table outbound_acl_stage2_dash_acl_rule_dash_acl {
	key {
		m.local_metadata__stage2_dash_acl_group_id30 exact
		m.local_metadata__dst_ip_addr22 wildcard
		m.local_metadata__src_ip_addr23 wildcard
		m.local_metadata__ip_protocol21 wildcard
		m.local_metadata__src_l4_port27 wildcard
		m.local_metadata__dst_l4_port28 wildcard
	}
	actions {
		outbound_acl_permit_1
		outbound_acl_permit_and_continue_1
		outbound_acl_deny_1
		outbound_acl_deny_and_continue_1
	}
	default_action outbound_acl_deny_1 args none 
	size 0x10000
}


table outbound_acl_stage3_dash_acl_rule_dash_acl {
	key {
		m.local_metadata__stage3_dash_acl_group_id31 exact
		m.local_metadata__dst_ip_addr22 wildcard
		m.local_metadata__src_ip_addr23 wildcard
		m.local_metadata__ip_protocol21 wildcard
		m.local_metadata__src_l4_port27 wildcard
		m.local_metadata__dst_l4_port28 wildcard
	}
	actions {
		outbound_acl_permit_2
		outbound_acl_permit_and_continue_2
		outbound_acl_deny_2
		outbound_acl_deny_and_continue_2
	}
	default_action outbound_acl_deny_2 args none 
	size 0x10000
}


table outbound_outbound_routing_dash_outbound_routing {
	key {
		m.local_metadata__eni_id12 exact
		m.local_metadata__is_overlay_ip_v619 exact
		m.local_metadata__dst_ip_addr22 lpm
	}
	actions {
		outbound_route_vnet_0
		outbound_route_vnet_direct_0
		outbound_route_direct_0
		outbound_drop_0
	}
	default_action outbound_drop_0 args none const
	size 0x10000
}


table outbound_outbound_ca_to_pa_dash_outbound_ca_to_pa {
	key {
		m.dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_to9 exact
		m.dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_t10 exact
		m.dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_t11 exact
	}
	actions {
		outbound_set_tunnel_mapping_0
		outbound_drop_1
	}
	default_action outbound_drop_1 args none const
	size 0x10000
}


table outbound_vnet_dash_vnet {
	key {
		m.local_metadata__vnet_id10 exact
	}
	actions {
		outbound_set_vnet_attrs_0
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


table inbound_acl_stage1_dash_acl_rule_dash_acl {
	key {
		m.local_metadata__stage1_dash_acl_group_id29 exact
		m.local_metadata__dst_ip_addr22 wildcard
		m.local_metadata__src_ip_addr23 wildcard
		m.local_metadata__ip_protocol21 wildcard
		m.local_metadata__src_l4_port27 wildcard
		m.local_metadata__dst_l4_port28 wildcard
	}
	actions {
		inbound_acl_permit_0
		inbound_acl_permit_and_continue_0
		inbound_acl_deny_0
		inbound_acl_deny_and_continue_0
	}
	default_action inbound_acl_deny_0 args none 
	size 0x10000
}


table inbound_acl_stage2_dash_acl_rule_dash_acl {
	key {
		m.local_metadata__stage2_dash_acl_group_id30 exact
		m.local_metadata__dst_ip_addr22 wildcard
		m.local_metadata__src_ip_addr23 wildcard
		m.local_metadata__ip_protocol21 wildcard
		m.local_metadata__src_l4_port27 wildcard
		m.local_metadata__dst_l4_port28 wildcard
	}
	actions {
		inbound_acl_permit_1
		inbound_acl_permit_and_continue_1
		inbound_acl_deny_1
		inbound_acl_deny_and_continue_1
	}
	default_action inbound_acl_deny_1 args none 
	size 0x10000
}


table inbound_acl_stage3_dash_acl_rule_dash_acl {
	key {
		m.local_metadata__stage3_dash_acl_group_id31 exact
		m.local_metadata__dst_ip_addr22 wildcard
		m.local_metadata__src_ip_addr23 wildcard
		m.local_metadata__ip_protocol21 wildcard
		m.local_metadata__src_l4_port27 wildcard
		m.local_metadata__dst_l4_port28 wildcard
	}
	actions {
		inbound_acl_permit_2
		inbound_acl_permit_and_continue_2
		inbound_acl_deny_2
		inbound_acl_deny_and_continue_2
	}
	default_action inbound_acl_deny_2 args none 
	size 0x10000
}


table vip {
	key {
		h.ipv4.dst_addr exact
	}
	actions {
		accept_1
		deny
	}
	default_action deny args none const
	size 0x10000
}


table direction_lookup {
	key {
		h.vxlan.vni exact
	}
	actions {
		set_outbound_direction
		set_inbound_direction
	}
	default_action set_inbound_direction args none const
	size 0x10000
}


table appliance {
	key {
		m.local_metadata__appliance_id18 wildcard
	}
	actions {
		set_appliance
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


table eni {
	key {
		m.local_metadata__eni_id12 exact
	}
	actions {
		set_eni_attrs
		deny_0
	}
	default_action deny_0 args none const
	size 0x10000
}


table eni_meter {
	key {
		m.dash_ingress_eni_meter_local_metadata__eni_id12 exact
		m.dash_ingress_eni_meter_local_metadata__direction1 exact
		m.dash_ingress_eni_meter_local_metadata__dropped0 exact
	}
	actions {
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


table pa_validation {
	key {
		m.dash_ingress_pa_validation_local_metadata__vnet_id10 exact
		m.dash_ingress_pa_validation_ipv4_src_addr exact
	}
	actions {
		permit
		deny_2
	}
	default_action deny_2 args none const
	size 0x10000
}


table inbound_routing {
	key {
		m.local_metadata__eni_id12 exact
		m.dash_ingress_inbound_routing_vxlan_vni exact
		m.dash_ingress_inbound_routing_ipv4_src_addr wildcard
	}
	actions {
		vxlan_decap_1
		vxlan_decap_pa_validate
		deny_3
	}
	default_action deny_3 args none const
	size 0x10000
}


table eni_ether_address_map {
	key {
		m.MainControlT_tmp_45 exact
	}
	actions {
		set_eni
		deny_4
	}
	default_action deny_4 args none const
	size 0x10000
}


table acl_group {
	key {
		m.local_metadata__stage1_dash_acl_group_id29 exact
	}
	actions {
		set_acl_group_attrs
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


learner outbound_ConntrackOut_conntrackOut {
	key {
		m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval
		m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval_0
		m.dash_ingress_outbound_ConntrackOut_conntrackOut_ipv4_protoc6
		m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval_1
		m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval_2
		m.dash_ingress_outbound_ConntrackOut_conntrackOut_local_metad7
	}
	actions {
		outbound_ConntrackOut_conntrackOut_allow_0
		outbound_ConntrackOut_conntrackOut_miss_0
	}
	default_action outbound_ConntrackOut_conntrackOut_miss_0 args none 
	size 0x10000
	timeout {
		10
		30
		60
		120
		300
		43200
		120
		120

		}
}

learner outbound_ConntrackIn_conntrackIn {
	key {
		m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval
		m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval_0
		m.dash_ingress_outbound_ConntrackIn_conntrackIn_ipv4_protocol
		m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval_1
		m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval_2
		m.dash_ingress_outbound_ConntrackIn_conntrackIn_local_metadat8
	}
	actions {
		outbound_ConntrackIn_conntrackIn_allow_0
		outbound_ConntrackIn_conntrackIn_miss_0
	}
	default_action outbound_ConntrackIn_conntrackIn_miss_0 args none 
	size 0x10000
	timeout {
		10
		30
		60
		120
		300
		43200
		120
		120

		}
}

learner inbound_ConntrackIn_conntrackIn {
	key {
		m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval
		m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval_0
		m.dash_ingress_inbound_ConntrackIn_conntrackIn_ipv4_protocol
		m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval_1
		m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval_2
		m.dash_ingress_inbound_ConntrackIn_conntrackIn_local_metadat12
	}
	actions {
		inbound_ConntrackIn_conntrackIn_allow_0
		inbound_ConntrackIn_conntrackIn_miss_0
	}
	default_action inbound_ConntrackIn_conntrackIn_miss_0 args none 
	size 0x10000
	timeout {
		10
		30
		60
		120
		300
		43200
		120
		120

		}
}

learner inbound_ConntrackOut_conntrackOut {
	key {
		m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval
		m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval_0
		m.dash_ingress_inbound_ConntrackOut_conntrackOut_ipv4_protocol
		m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval_1
		m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval_2
		m.dash_ingress_inbound_ConntrackOut_conntrackOut_local_metad13
	}
	actions {
		inbound_ConntrackOut_conntrackOut_allow_0
		inbound_ConntrackOut_conntrackOut_miss_0
	}
	default_action inbound_ConntrackOut_conntrackOut_miss_0 args none 
	size 0x10000
	timeout {
		10
		30
		60
		120
		300
		43200
		120
		120

		}
}

apply {
	rx m.pna_main_input_metadata_input_port
	extract h.ethernet
	jmpeq DASH_PARSER_PARSE_IPV4 h.ethernet.ether_type 0x800
	jmpeq DASH_PARSER_PARSE_IPV6 h.ethernet.ether_type 0x86DD
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_IPV6 :	extract h.ipv6
	jmpeq DASH_PARSER_PARSE_UDP h.ipv6.next_header 0x11
	jmpeq DASH_PARSER_PARSE_TCP h.ipv6.next_header 0x6
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_IPV4 :	extract h.ipv4
	mov m.MainParserT_parser_tmp_6 h.ipv4.version_ihl
	and m.MainParserT_parser_tmp_6 0xF
	mov m.MainParserT_parser_tmp_7 m.MainParserT_parser_tmp_6
	and m.MainParserT_parser_tmp_7 0xF
	jmpeq LABEL_TRUE m.MainParserT_parser_tmp_7 0x4
	mov m.MainParserT_parser_tmp_25 0x0
	jmp LABEL_END
	LABEL_TRUE :	mov m.MainParserT_parser_tmp_25 0x1
	LABEL_END :	jmpneq LABEL_END_0 m.MainParserT_parser_tmp_25 0
	mov m.pna_pre_input_metadata_parser_error 0x7
	jmp DASH_PARSER_ACCEPT
	LABEL_END_0 :	mov m.MainParserT_parser_tmp_9 h.ipv4.version_ihl
	shr m.MainParserT_parser_tmp_9 0x4
	mov m.MainParserT_parser_tmp_10 m.MainParserT_parser_tmp_9
	and m.MainParserT_parser_tmp_10 0xF
	mov m.MainParserT_parser_tmp_11 m.MainParserT_parser_tmp_10
	and m.MainParserT_parser_tmp_11 0xF
	jmplt LABEL_FALSE_0 m.MainParserT_parser_tmp_11 0x5
	mov m.MainParserT_parser_tmp_26 0x1
	jmp LABEL_END_1
	LABEL_FALSE_0 :	mov m.MainParserT_parser_tmp_26 0x0
	LABEL_END_1 :	jmpneq LABEL_END_2 m.MainParserT_parser_tmp_26 0
	mov m.pna_pre_input_metadata_parser_error 0x9
	jmp DASH_PARSER_ACCEPT
	LABEL_END_2 :	mov m.MainParserT_parser_tmp_13 h.ipv4.version_ihl
	shr m.MainParserT_parser_tmp_13 0x4
	mov m.MainParserT_parser_tmp_14 m.MainParserT_parser_tmp_13
	and m.MainParserT_parser_tmp_14 0xF
	mov m.MainParserT_parser_tmp_15 m.MainParserT_parser_tmp_14
	and m.MainParserT_parser_tmp_15 0xF
	jmpeq DASH_PARSER_DISPATCH_ON_PROTOCOL m.MainParserT_parser_tmp_15 0x5
	mov m.MainParserT_parser_tmp_16 h.ipv4.version_ihl
	shr m.MainParserT_parser_tmp_16 0x4
	mov m.MainParserT_parser_tmp_17 m.MainParserT_parser_tmp_16
	and m.MainParserT_parser_tmp_17 0xF
	mov m.MainParserT_parser_tmp_18 m.MainParserT_parser_tmp_17
	and m.MainParserT_parser_tmp_18 0xF
	mov m.MainParserT_parser_tmp_21 m.MainParserT_parser_tmp_18
	add m.MainParserT_parser_tmp_21 0xFFFB
	mov m.MainParserT_parser_tmp_22 m.MainParserT_parser_tmp_21
	shl m.MainParserT_parser_tmp_22 0x5
	mov m.MainParserT_parser_tmp_28_extract_tmp m.MainParserT_parser_tmp_22
	shr m.MainParserT_parser_tmp_28_extract_tmp 0x3
	extract h.ipv4options m.MainParserT_parser_tmp_28_extract_tmp
	DASH_PARSER_DISPATCH_ON_PROTOCOL :	jmpeq DASH_PARSER_PARSE_UDP h.ipv4.protocol 0x11
	jmpeq DASH_PARSER_PARSE_TCP h.ipv4.protocol 0x6
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_UDP :	extract h.udp
	jmpeq DASH_PARSER_PARSE_VXLAN h.udp.dst_port 0x12B5
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_VXLAN :	extract h.vxlan
	extract h.inner_ethernet
	jmpeq DASH_PARSER_PARSE_INNER_IPV4 h.inner_ethernet.ether_type 0x800
	jmpeq DASH_PARSER_PARSE_INNER_IPV6 h.inner_ethernet.ether_type 0x86DD
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_INNER_IPV6 :	extract h.inner_ipv6
	jmpeq DASH_PARSER_PARSE_INNER_UDP h.inner_ipv6.next_header 0x11
	jmpeq DASH_PARSER_PARSE_INNER_TCP h.inner_ipv6.next_header 0x6
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_INNER_IPV4 :	extract h.inner_ipv4
	mov m.MainParserT_parser_tmp h.inner_ipv4.version_ihl
	and m.MainParserT_parser_tmp 0xF
	mov m.MainParserT_parser_tmp_0 m.MainParserT_parser_tmp
	and m.MainParserT_parser_tmp_0 0xF
	jmpeq LABEL_TRUE_1 m.MainParserT_parser_tmp_0 0x4
	mov m.MainParserT_parser_tmp_23 0x0
	jmp LABEL_END_3
	LABEL_TRUE_1 :	mov m.MainParserT_parser_tmp_23 0x1
	LABEL_END_3 :	jmpneq LABEL_END_4 m.MainParserT_parser_tmp_23 0
	mov m.pna_pre_input_metadata_parser_error 0x7
	jmp DASH_PARSER_ACCEPT
	LABEL_END_4 :	mov m.MainParserT_parser_tmp_2 h.inner_ipv4.version_ihl
	shr m.MainParserT_parser_tmp_2 0x4
	mov m.MainParserT_parser_tmp_3 m.MainParserT_parser_tmp_2
	and m.MainParserT_parser_tmp_3 0xF
	mov m.MainParserT_parser_tmp_4 m.MainParserT_parser_tmp_3
	and m.MainParserT_parser_tmp_4 0xF
	jmpeq LABEL_TRUE_2 m.MainParserT_parser_tmp_4 0x5
	mov m.MainParserT_parser_tmp_24 0x0
	jmp LABEL_END_5
	LABEL_TRUE_2 :	mov m.MainParserT_parser_tmp_24 0x1
	LABEL_END_5 :	jmpneq LABEL_END_6 m.MainParserT_parser_tmp_24 0
	mov m.pna_pre_input_metadata_parser_error 0x8
	jmp DASH_PARSER_ACCEPT
	LABEL_END_6 :	jmpeq DASH_PARSER_PARSE_INNER_UDP h.inner_ipv4.protocol 0x11
	jmpeq DASH_PARSER_PARSE_INNER_TCP h.inner_ipv4.protocol 0x6
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_INNER_UDP :	extract h.inner_udp
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_INNER_TCP :	extract h.inner_tcp
	jmp DASH_PARSER_ACCEPT
	DASH_PARSER_PARSE_TCP :	extract h.tcp
	DASH_PARSER_ACCEPT :	table vip
	jmpnh LABEL_END_7
	mov m.local_metadata__encap_data_underlay_sip4 h.ipv4.dst_addr
	LABEL_END_7 :	table direction_lookup
	table appliance
	jmpneq LABEL_FALSE_4 m.local_metadata__direction1 0x1
	invalidate h.MainControlT_hdr_1_inner_ethe2
	invalidate h.MainControlT_hdr_1_inner_ipv4
	invalidate h.MainControlT_hdr_1_inner_ipv6
	invalidate h.MainControlT_hdr_1_vxlan
	invalidate h.MainControlT_hdr_1_udp
	invalidate h.MainControlT_hdr_1_inner_tcp
	invalidate h.MainControlT_hdr_1_inner_udp
	jmp LABEL_END_8
	LABEL_FALSE_4 :	jmpneq LABEL_END_8 m.local_metadata__direction1 0x2
	mov m.dash_ingress_inbound_routing_vxlan_vni h.vxlan.vni
	mov m.dash_ingress_inbound_routing_ipv4_src_addr h.ipv4.src_addr
	table inbound_routing
	jmpa LABEL_SWITCH vxlan_decap_pa_validate
	jmp LABEL_END_8
	LABEL_SWITCH :	mov m.dash_ingress_pa_validation_local_metadata__vnet_id10 m.local_metadata__vnet_id10
	mov m.dash_ingress_pa_validation_ipv4_src_addr h.ipv4.src_addr
	table pa_validation
	invalidate h.MainControlT_hdr_7_inner_ethe3
	invalidate h.MainControlT_hdr_7_inner_ipv4
	invalidate h.MainControlT_hdr_7_inner_ipv6
	invalidate h.MainControlT_hdr_7_vxlan
	invalidate h.MainControlT_hdr_7_udp
	invalidate h.MainControlT_hdr_7_inner_tcp
	invalidate h.MainControlT_hdr_7_inner_udp
	LABEL_END_8 :	mov m.local_metadata__is_overlay_ip_v619 0x0
	mov m.local_metadata__ip_protocol21 0x0
	mov h.dpdk_pseudo_header.pseudo 0x0
	mov m.local_metadata__dst_ip_addr22 h.dpdk_pseudo_header.pseudo
	mov h.dpdk_pseudo_header.pseudo_0 0x0
	mov m.local_metadata__src_ip_addr23 h.dpdk_pseudo_header.pseudo_0
	jmpnv LABEL_FALSE_6 h.ipv6
	mov m.local_metadata__ip_protocol21 h.ipv6.next_header
	mov m.local_metadata__src_ip_addr23 h.ipv6.src_addr
	mov m.local_metadata__dst_ip_addr22 h.ipv6.dst_addr
	mov m.local_metadata__is_overlay_ip_v619 0x1
	jmp LABEL_END_10
	LABEL_FALSE_6 :	jmpnv LABEL_END_10 h.ipv4
	mov m.local_metadata__ip_protocol21 h.ipv4.protocol
	mov m.local_metadata__src_ip_addr23 h.ipv4.src_addr
	mov m.local_metadata__dst_ip_addr22 h.ipv4.dst_addr
	LABEL_END_10 :	jmpnv LABEL_FALSE_8 h.tcp
	mov m.local_metadata__src_l4_port27 h.tcp.src_port
	mov m.local_metadata__dst_l4_port28 h.tcp.dst_port
	jmp LABEL_END_12
	LABEL_FALSE_8 :	jmpnv LABEL_END_12 h.udp
	mov m.local_metadata__src_l4_port27 h.udp.src_port
	mov m.local_metadata__dst_l4_port28 h.udp.dst_port
	LABEL_END_12 :	jmpneq LABEL_FALSE_10 m.local_metadata__direction1 0x1
	mov m.MainControlT_tmp_45 h.ethernet.src_addr
	jmp LABEL_END_14
	LABEL_FALSE_10 :	mov m.MainControlT_tmp_45 h.ethernet.dst_addr
	LABEL_END_14 :	mov m.local_metadata__eni_addr9 m.MainControlT_tmp_45
	table eni_ether_address_map
	table eni
	jmpneq LABEL_END_15 m.local_metadata__eni_data_admin_state16 0x0
	mov m.local_metadata__dropped0 1
	LABEL_END_15 :	table acl_group
	jmpneq LABEL_FALSE_12 m.local_metadata__direction1 0x1
	jmpneq LABEL_FALSE_13 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval h.ipv4.src_addr
	jmp LABEL_END_17
	LABEL_FALSE_13 :	mov m.MainControlT_retval h.ipv4.dst_addr
	LABEL_END_17 :	jmpneq LABEL_FALSE_14 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_0 h.ipv4.dst_addr
	jmp LABEL_END_18
	LABEL_FALSE_14 :	mov m.MainControlT_retval_0 h.ipv4.src_addr
	LABEL_END_18 :	jmpneq LABEL_FALSE_15 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_1 h.tcp.src_port
	jmp LABEL_END_19
	LABEL_FALSE_15 :	mov m.MainControlT_retval_1 h.tcp.dst_port
	LABEL_END_19 :	jmpneq LABEL_FALSE_16 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_2 h.tcp.dst_port
	jmp LABEL_END_20
	LABEL_FALSE_16 :	mov m.MainControlT_retval_2 h.tcp.src_port
	LABEL_END_20 :	mov m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval m.MainControlT_retval
	mov m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval_0 m.MainControlT_retval_0
	mov m.dash_ingress_outbound_ConntrackOut_conntrackOut_ipv4_protoc6 h.ipv4.protocol
	mov m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval_1 m.MainControlT_retval_1
	mov m.dash_ingress_outbound_ConntrackOut_conntrackOut_retval_2 m.MainControlT_retval_2
	mov m.dash_ingress_outbound_ConntrackOut_conntrackOut_local_metad7 m.local_metadata__eni_id12
	table outbound_ConntrackOut_conntrackOut
	jmpneq LABEL_FALSE_17 m.local_metadata__conntrack_data_allow_out26 0x1
	jmp LABEL_END_21
	LABEL_FALSE_17 :	mov m.MainControlT_outbound_acl_hasReturned 0
	jmpeq LABEL_END_22 m.local_metadata__stage1_dash_acl_group_id29 0x0
	table outbound_acl_stage1_dash_acl_rule_dash_acl
	jmpa LABEL_SWITCH_0 outbound_acl_permit_0
	jmpa LABEL_SWITCH_1 outbound_acl_deny_0
	jmp LABEL_END_22
	LABEL_SWITCH_0 :	mov m.MainControlT_outbound_acl_hasReturned 1
	jmp LABEL_END_22
	LABEL_SWITCH_1 :	mov m.MainControlT_outbound_acl_hasReturned 1
	LABEL_END_22 :	jmpneq LABEL_FALSE_19 m.MainControlT_outbound_acl_hasReturned 0x1
	jmp LABEL_END_23
	LABEL_FALSE_19 :	jmpeq LABEL_END_23 m.local_metadata__stage2_dash_acl_group_id30 0x0
	table outbound_acl_stage2_dash_acl_rule_dash_acl
	jmpa LABEL_SWITCH_2 outbound_acl_permit_1
	jmpa LABEL_SWITCH_3 outbound_acl_deny_1
	jmp LABEL_END_23
	LABEL_SWITCH_2 :	mov m.MainControlT_outbound_acl_hasReturned 1
	jmp LABEL_END_23
	LABEL_SWITCH_3 :	mov m.MainControlT_outbound_acl_hasReturned 1
	LABEL_END_23 :	jmpneq LABEL_FALSE_21 m.MainControlT_outbound_acl_hasReturned 0x1
	jmp LABEL_END_21
	LABEL_FALSE_21 :	jmpeq LABEL_END_21 m.local_metadata__stage3_dash_acl_group_id31 0x0
	table outbound_acl_stage3_dash_acl_rule_dash_acl
	LABEL_END_21 :	jmpneq LABEL_FALSE_23 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_3 h.ipv4.src_addr
	jmp LABEL_END_27
	LABEL_FALSE_23 :	mov m.MainControlT_retval_3 h.ipv4.dst_addr
	LABEL_END_27 :	jmpneq LABEL_FALSE_24 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_4 h.ipv4.dst_addr
	jmp LABEL_END_28
	LABEL_FALSE_24 :	mov m.MainControlT_retval_4 h.ipv4.src_addr
	LABEL_END_28 :	jmpneq LABEL_FALSE_25 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_5 h.tcp.src_port
	jmp LABEL_END_29
	LABEL_FALSE_25 :	mov m.MainControlT_retval_5 h.tcp.dst_port
	LABEL_END_29 :	jmpneq LABEL_FALSE_26 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_6 h.tcp.dst_port
	jmp LABEL_END_30
	LABEL_FALSE_26 :	mov m.MainControlT_retval_6 h.tcp.src_port
	LABEL_END_30 :	mov m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval m.MainControlT_retval_3
	mov m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval_0 m.MainControlT_retval_4
	mov m.dash_ingress_outbound_ConntrackIn_conntrackIn_ipv4_protocol h.ipv4.protocol
	mov m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval_1 m.MainControlT_retval_5
	mov m.dash_ingress_outbound_ConntrackIn_conntrackIn_retval_2 m.MainControlT_retval_6
	mov m.dash_ingress_outbound_ConntrackIn_conntrackIn_local_metadat8 m.local_metadata__eni_id12
	table outbound_ConntrackIn_conntrackIn
	table outbound_outbound_routing_dash_outbound_routing
	jmpa LABEL_SWITCH_7 outbound_route_vnet_direct_0
	jmpa LABEL_SWITCH_7 outbound_route_vnet_0
	jmp LABEL_END_16
	LABEL_SWITCH_7 :	mov m.dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_to9 m.local_metadata__dst_vnet_id11
	mov m.dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_t10 m.local_metadata__is_overlay_ip_v619
	mov m.dash_ingress_outbound_outbound_ca_to_pa_dash_outbound_ca_t11 m.local_metadata__dst_ip_addr22
	table outbound_outbound_ca_to_pa_dash_outbound_ca_to_pa
	table outbound_vnet_dash_vnet
	mov h.MainControlT_hdr_8_inner_ethe4.dst_addr m.local_metadata__encap_data_overlay_dmac8
	invalidate h.MainControlT_hdr_8_ethernet
	invalidate h.MainControlT_hdr_8_ipv4
	invalidate h.MainControlT_hdr_8_ipv6
	invalidate h.MainControlT_hdr_8_tcp
	invalidate h.MainControlT_hdr_8_udp
	validate h.MainControlT_hdr_8_ethernet
	mov h.MainControlT_hdr_8_ethernet.src_addr m.local_metadata__encap_data_underlay_smac6
	mov h.MainControlT_hdr_8_ethernet.ether_type 0x800
	validate h.MainControlT_hdr_8_ipv4
	mov m.MainControlT_tmp_35 h.MainControlT_hdr_8_ipv4.version_ihl
	and m.MainControlT_tmp_35 0xF0
	mov h.MainControlT_hdr_8_ipv4.version_ihl m.MainControlT_tmp_35
	or h.MainControlT_hdr_8_ipv4.version_ihl 0x4
	mov m.MainControlT_tmp_36 h.MainControlT_hdr_8_ipv4.version_ihl
	and m.MainControlT_tmp_36 0xF
	mov h.MainControlT_hdr_8_ipv4.version_ihl m.MainControlT_tmp_36
	or h.MainControlT_hdr_8_ipv4.version_ihl 0x50
	mov h.MainControlT_hdr_8_ipv4.diffserv 0x0
	mov m.MainControlT_inner_ip_len 0x0
	jmpnv LABEL_END_31 h.MainControlT_hdr_8_inner_ipv4
	mov m.MainControlT_inner_ip_len h.MainControlT_hdr_8_inner_ipv4.total_len
	LABEL_END_31 :	jmpnv LABEL_END_32 h.MainControlT_hdr_8_inner_ipv6
	mov m.MainControlT_tmp_37 m.MainControlT_inner_ip_len
	add m.MainControlT_tmp_37 0x28
	mov m.MainControlT_inner_ip_len m.MainControlT_tmp_37
	add m.MainControlT_inner_ip_len h.MainControlT_hdr_8_inner_ipv6.payload_length
	LABEL_END_32 :	mov h.MainControlT_hdr_8_ipv4.total_len 0x32
	add h.MainControlT_hdr_8_ipv4.total_len m.MainControlT_inner_ip_len
	mov h.MainControlT_hdr_8_ipv4.identification 0x1
	mov m.MainControlT_tmp_38 h.MainControlT_hdr_8_ipv4.flags_frag_offset
	and m.MainControlT_tmp_38 0xFFF8
	mov h.MainControlT_hdr_8_ipv4.flags_frag_offset m.MainControlT_tmp_38
	or h.MainControlT_hdr_8_ipv4.flags_frag_offset 0x0
	mov m.MainControlT_tmp_39 h.MainControlT_hdr_8_ipv4.flags_frag_offset
	and m.MainControlT_tmp_39 0x7
	mov h.MainControlT_hdr_8_ipv4.flags_frag_offset m.MainControlT_tmp_39
	or h.MainControlT_hdr_8_ipv4.flags_frag_offset 0x0
	mov h.MainControlT_hdr_8_ipv4.ttl 0x40
	mov h.MainControlT_hdr_8_ipv4.protocol 0x11
	mov h.MainControlT_hdr_8_ipv4.dst_addr m.local_metadata__encap_data_underlay_dip5
	mov h.MainControlT_hdr_8_ipv4.src_addr m.local_metadata__encap_data_underlay_sip4
	mov h.MainControlT_hdr_8_ipv4.hdr_checksum 0x0
	validate h.MainControlT_hdr_8_udp
	mov h.MainControlT_hdr_8_udp.src_port 0x0
	mov h.MainControlT_hdr_8_udp.dst_port 0x12B5
	mov h.MainControlT_hdr_8_udp.length 0x1E
	add h.MainControlT_hdr_8_udp.length m.MainControlT_inner_ip_len
	mov h.MainControlT_hdr_8_udp.checksum 0x0
	validate h.MainControlT_hdr_8_vxlan
	mov h.MainControlT_hdr_8_vxlan.reserved 0x0
	mov h.MainControlT_hdr_8_vxlan.reserved_2 0x0
	mov h.MainControlT_hdr_8_vxlan.flags 0x0
	mov h.MainControlT_hdr_8_vxlan.vni m.local_metadata__encap_data_vni2
	jmp LABEL_END_16
	jmp LABEL_END_16
	LABEL_FALSE_12 :	jmpneq LABEL_END_16 m.local_metadata__direction1 0x2
	jmpneq LABEL_FALSE_30 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_7 h.ipv4.src_addr
	jmp LABEL_END_34
	LABEL_FALSE_30 :	mov m.MainControlT_retval_7 h.ipv4.dst_addr
	LABEL_END_34 :	jmpneq LABEL_FALSE_31 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_8 h.ipv4.dst_addr
	jmp LABEL_END_35
	LABEL_FALSE_31 :	mov m.MainControlT_retval_8 h.ipv4.src_addr
	LABEL_END_35 :	jmpneq LABEL_FALSE_32 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_9 h.tcp.src_port
	jmp LABEL_END_36
	LABEL_FALSE_32 :	mov m.MainControlT_retval_9 h.tcp.dst_port
	LABEL_END_36 :	jmpneq LABEL_FALSE_33 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_10 h.tcp.dst_port
	jmp LABEL_END_37
	LABEL_FALSE_33 :	mov m.MainControlT_retval_10 h.tcp.src_port
	LABEL_END_37 :	mov m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval m.MainControlT_retval_7
	mov m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval_0 m.MainControlT_retval_8
	mov m.dash_ingress_inbound_ConntrackIn_conntrackIn_ipv4_protocol h.ipv4.protocol
	mov m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval_1 m.MainControlT_retval_9
	mov m.dash_ingress_inbound_ConntrackIn_conntrackIn_retval_2 m.MainControlT_retval_10
	mov m.dash_ingress_inbound_ConntrackIn_conntrackIn_local_metadat12 m.local_metadata__eni_id12
	table inbound_ConntrackIn_conntrackIn
	jmpneq LABEL_FALSE_34 m.local_metadata__conntrack_data_allow_in25 0x1
	jmp LABEL_END_38
	LABEL_FALSE_34 :	mov m.MainControlT_inbound_acl_hasReturned 0
	jmpeq LABEL_END_39 m.local_metadata__stage1_dash_acl_group_id29 0x0
	table inbound_acl_stage1_dash_acl_rule_dash_acl
	jmpa LABEL_SWITCH_8 inbound_acl_permit_0
	jmpa LABEL_SWITCH_9 inbound_acl_deny_0
	jmp LABEL_END_39
	LABEL_SWITCH_8 :	mov m.MainControlT_inbound_acl_hasReturned 1
	jmp LABEL_END_39
	LABEL_SWITCH_9 :	mov m.MainControlT_inbound_acl_hasReturned 1
	LABEL_END_39 :	jmpneq LABEL_FALSE_36 m.MainControlT_inbound_acl_hasReturned 0x1
	jmp LABEL_END_40
	LABEL_FALSE_36 :	jmpeq LABEL_END_40 m.local_metadata__stage2_dash_acl_group_id30 0x0
	table inbound_acl_stage2_dash_acl_rule_dash_acl
	jmpa LABEL_SWITCH_10 inbound_acl_permit_1
	jmpa LABEL_SWITCH_11 inbound_acl_deny_1
	jmp LABEL_END_40
	LABEL_SWITCH_10 :	mov m.MainControlT_inbound_acl_hasReturned 1
	jmp LABEL_END_40
	LABEL_SWITCH_11 :	mov m.MainControlT_inbound_acl_hasReturned 1
	LABEL_END_40 :	jmpneq LABEL_FALSE_38 m.MainControlT_inbound_acl_hasReturned 0x1
	jmp LABEL_END_38
	LABEL_FALSE_38 :	jmpeq LABEL_END_38 m.local_metadata__stage3_dash_acl_group_id31 0x0
	table inbound_acl_stage3_dash_acl_rule_dash_acl
	LABEL_END_38 :	jmpneq LABEL_FALSE_40 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_11 h.ipv4.src_addr
	jmp LABEL_END_44
	LABEL_FALSE_40 :	mov m.MainControlT_retval_11 h.ipv4.dst_addr
	LABEL_END_44 :	jmpneq LABEL_FALSE_41 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_12 h.ipv4.dst_addr
	jmp LABEL_END_45
	LABEL_FALSE_41 :	mov m.MainControlT_retval_12 h.ipv4.src_addr
	LABEL_END_45 :	jmpneq LABEL_FALSE_42 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_13 h.tcp.src_port
	jmp LABEL_END_46
	LABEL_FALSE_42 :	mov m.MainControlT_retval_13 h.tcp.dst_port
	LABEL_END_46 :	jmpneq LABEL_FALSE_43 m.local_metadata__direction1 0x1
	mov m.MainControlT_retval_14 h.tcp.dst_port
	jmp LABEL_END_47
	LABEL_FALSE_43 :	mov m.MainControlT_retval_14 h.tcp.src_port
	LABEL_END_47 :	mov m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval m.MainControlT_retval_11
	mov m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval_0 m.MainControlT_retval_12
	mov m.dash_ingress_inbound_ConntrackOut_conntrackOut_ipv4_protocol h.ipv4.protocol
	mov m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval_1 m.MainControlT_retval_13
	mov m.dash_ingress_inbound_ConntrackOut_conntrackOut_retval_2 m.MainControlT_retval_14
	mov m.dash_ingress_inbound_ConntrackOut_conntrackOut_local_metad13 m.local_metadata__eni_id12
	table inbound_ConntrackOut_conntrackOut
	mov h.MainControlT_hdr_9_inner_ethe5.dst_addr m.MainControlT_inbound_tmp
	invalidate h.MainControlT_hdr_9_ethernet
	invalidate h.MainControlT_hdr_9_ipv4
	invalidate h.MainControlT_hdr_9_ipv6
	invalidate h.MainControlT_hdr_9_tcp
	invalidate h.MainControlT_hdr_9_udp
	validate h.MainControlT_hdr_9_ethernet
	mov h.MainControlT_hdr_9_ethernet.dst_addr m.local_metadata__encap_data_underlay_dmac7
	mov h.MainControlT_hdr_9_ethernet.src_addr m.local_metadata__encap_data_underlay_smac6
	mov h.MainControlT_hdr_9_ethernet.ether_type 0x800
	validate h.MainControlT_hdr_9_ipv4
	mov m.MainControlT_tmp_40 h.MainControlT_hdr_9_ipv4.version_ihl
	and m.MainControlT_tmp_40 0xF0
	mov h.MainControlT_hdr_9_ipv4.version_ihl m.MainControlT_tmp_40
	or h.MainControlT_hdr_9_ipv4.version_ihl 0x4
	mov m.MainControlT_tmp_41 h.MainControlT_hdr_9_ipv4.version_ihl
	and m.MainControlT_tmp_41 0xF
	mov h.MainControlT_hdr_9_ipv4.version_ihl m.MainControlT_tmp_41
	or h.MainControlT_hdr_9_ipv4.version_ihl 0x50
	mov h.MainControlT_hdr_9_ipv4.diffserv 0x0
	mov m.MainControlT_inner_ip_len_0 0x0
	jmpnv LABEL_END_48 h.MainControlT_hdr_9_inner_ipv4
	mov m.MainControlT_inner_ip_len_0 h.MainControlT_hdr_9_inner_ipv4.total_len
	LABEL_END_48 :	jmpnv LABEL_END_49 h.MainControlT_hdr_9_inner_ipv6
	mov m.MainControlT_tmp_42 m.MainControlT_inner_ip_len_0
	add m.MainControlT_tmp_42 0x28
	mov m.MainControlT_inner_ip_len_0 m.MainControlT_tmp_42
	add m.MainControlT_inner_ip_len_0 h.MainControlT_hdr_9_inner_ipv6.payload_length
	LABEL_END_49 :	mov h.MainControlT_hdr_9_ipv4.total_len 0x32
	add h.MainControlT_hdr_9_ipv4.total_len m.MainControlT_inner_ip_len_0
	mov h.MainControlT_hdr_9_ipv4.identification 0x1
	mov m.MainControlT_tmp_43 h.MainControlT_hdr_9_ipv4.flags_frag_offset
	and m.MainControlT_tmp_43 0xFFF8
	mov h.MainControlT_hdr_9_ipv4.flags_frag_offset m.MainControlT_tmp_43
	or h.MainControlT_hdr_9_ipv4.flags_frag_offset 0x0
	mov m.MainControlT_tmp_44 h.MainControlT_hdr_9_ipv4.flags_frag_offset
	and m.MainControlT_tmp_44 0x7
	mov h.MainControlT_hdr_9_ipv4.flags_frag_offset m.MainControlT_tmp_44
	or h.MainControlT_hdr_9_ipv4.flags_frag_offset 0x0
	mov h.MainControlT_hdr_9_ipv4.ttl 0x40
	mov h.MainControlT_hdr_9_ipv4.protocol 0x11
	mov h.MainControlT_hdr_9_ipv4.dst_addr m.local_metadata__encap_data_underlay_dip5
	mov h.MainControlT_hdr_9_ipv4.src_addr m.local_metadata__encap_data_underlay_sip4
	mov h.MainControlT_hdr_9_ipv4.hdr_checksum 0x0
	validate h.MainControlT_hdr_9_udp
	mov h.MainControlT_hdr_9_udp.src_port 0x0
	mov h.MainControlT_hdr_9_udp.dst_port 0x12B5
	mov h.MainControlT_hdr_9_udp.length 0x1E
	add h.MainControlT_hdr_9_udp.length m.MainControlT_inner_ip_len_0
	mov h.MainControlT_hdr_9_udp.checksum 0x0
	validate h.MainControlT_hdr_9_vxlan
	mov h.MainControlT_hdr_9_vxlan.reserved 0x0
	mov h.MainControlT_hdr_9_vxlan.reserved_2 0x0
	mov h.MainControlT_hdr_9_vxlan.flags 0x0
	mov h.MainControlT_hdr_9_vxlan.vni m.local_metadata__encap_data_vni2
	LABEL_END_16 :	mov m.dash_ingress_eni_meter_local_metadata__eni_id12 m.local_metadata__eni_id12
	mov m.dash_ingress_eni_meter_local_metadata__direction1 m.local_metadata__direction1
	mov m.dash_ingress_eni_meter_local_metadata__dropped0 m.local_metadata__dropped0
	table eni_meter
	jmpneq LABEL_END_50 m.local_metadata__dropped0 0x1
	drop
	LABEL_END_50 :	emit h.ethernet
	emit h.ipv4
	emit h.ipv4options
	emit h.ipv6
	emit h.udp
	emit h.tcp
	emit h.vxlan
	emit h.inner_ethernet
	emit h.inner_ipv4
	emit h.inner_ipv6
	emit h.inner_tcp
	emit h.inner_udp
	tx m.pna_main_output_metadata_output_port
}


