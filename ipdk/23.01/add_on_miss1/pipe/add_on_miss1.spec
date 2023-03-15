
struct ethernet_h {
	bit<48> dst_addr
	bit<48> src_addr
	bit<16> ether_type
}

struct ipv4_h {
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

struct tcp_h {
	bit<16> src_port
	bit<16> dst_port
	bit<32> seq_no
	bit<32> ack_no
	bit<8> data_offset_res
	bit<8> flags
	bit<16> window
	bit<16> checksum
	bit<16> urgent_ptr
}

struct udp_h {
	bit<16> src_port
	bit<16> dst_port
	bit<16> length
	bit<16> checksum
}

struct send_arg_t {
	bit<32> port
}

header ethernet instanceof ethernet_h
header ipv4 instanceof ipv4_h
header tcp instanceof tcp_h
header udp instanceof udp_h

struct metadata_t {
	bit<32> pna_main_input_metadata_direction
	bit<32> pna_main_input_metadata_input_port
	bit<32> pna_main_output_metadata_output_port
	bit<32> MainControlImpl_ct_tcp_table_key
	bit<32> MainControlImpl_ct_tcp_table_key_0
	bit<8> MainControlImpl_ct_tcp_table_ipv4_protocol
	bit<16> MainControlImpl_ct_tcp_table_key_1
	bit<16> MainControlImpl_ct_tcp_table_key_2
	bit<8> MainControlT_do_add_on_miss
	bit<8> MainControlT_update_aging_info
	bit<8> MainControlT_update_expire_time
	bit<8> MainControlT_new_expire_time_profile_id
	bit<32> MainControlT_key
	bit<32> MainControlT_key_0
	bit<16> MainControlT_key_1
	bit<16> MainControlT_key_2
}
metadata instanceof metadata_t

regarray direction size 0x100 initval 0
action NoAction args none {
	return
}

action drop args none {
	drop
	return
}

action tcp_syn_packet args none {
	mov m.MainControlT_do_add_on_miss 1
	mov m.MainControlT_update_aging_info 1
	mov m.MainControlT_update_expire_time 1
	mov m.MainControlT_new_expire_time_profile_id 0x1
	return
}

action tcp_fin_or_rst_packet args none {
	mov m.MainControlT_do_add_on_miss 0
	mov m.MainControlT_update_aging_info 1
	mov m.MainControlT_update_expire_time 1
	mov m.MainControlT_new_expire_time_profile_id 0x0
	return
}

action tcp_other_packets args none {
	mov m.MainControlT_do_add_on_miss 0
	mov m.MainControlT_update_aging_info 1
	mov m.MainControlT_update_expire_time 1
	mov m.MainControlT_new_expire_time_profile_id 0x2
	return
}

action ct_tcp_table_hit args none {
	jmpneq LABEL_END_6 m.MainControlT_update_aging_info 0x1
	jmpneq LABEL_FALSE_3 m.MainControlT_update_expire_time 0x1
	rearm m.MainControlT_new_expire_time_profile_id
	jmp LABEL_END_6
	LABEL_FALSE_3 :	rearm
	LABEL_END_6 :	return
}

action ct_tcp_table_miss args none {
	jmpneq LABEL_FALSE_4 m.MainControlT_do_add_on_miss 0x1
	learn ct_tcp_table_hit m.MainControlT_new_expire_time_profile_id
	jmp LABEL_END_8
	LABEL_FALSE_4 :	drop
	LABEL_END_8 :	return
}

action send args instanceof send_arg_t {
	mov m.pna_main_output_metadata_output_port t.port
	return
}

table set_ct_options {
	key {
		h.tcp.flags wildcard
	}
	actions {
		tcp_syn_packet
		tcp_fin_or_rst_packet
		tcp_other_packets
	}
	default_action tcp_other_packets args none const
	size 0x10000
}


table ipv4_host {
	key {
		h.ipv4.dst_addr exact
	}
	actions {
		send
		drop
		NoAction
	}
	default_action drop args none const
	size 0x10000
}


learner ct_tcp_table {
	key {
		m.MainControlImpl_ct_tcp_table_key
		m.MainControlImpl_ct_tcp_table_key_0
		m.MainControlImpl_ct_tcp_table_ipv4_protocol
		m.MainControlImpl_ct_tcp_table_key_1
		m.MainControlImpl_ct_tcp_table_key_2
	}
	actions {
		ct_tcp_table_hit @tableonly
		ct_tcp_table_miss @defaultonly
	}
	default_action ct_tcp_table_miss args none 
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
	regrd m.pna_main_input_metadata_direction direction m.pna_main_input_metadata_input_port
	extract h.ethernet
	jmpeq MAINPARSERIMPL_PARSE_IPV4 h.ethernet.ether_type 0x800
	jmp MAINPARSERIMPL_ACCEPT
	MAINPARSERIMPL_PARSE_IPV4 :	extract h.ipv4
	jmpeq MAINPARSERIMPL_PARSE_TCP h.ipv4.protocol 0x6
	jmpeq MAINPARSERIMPL_PARSE_UDP h.ipv4.protocol 0x11
	jmp MAINPARSERIMPL_ACCEPT
	MAINPARSERIMPL_PARSE_UDP :	extract h.udp
	jmp MAINPARSERIMPL_ACCEPT
	MAINPARSERIMPL_PARSE_TCP :	extract h.tcp
	MAINPARSERIMPL_ACCEPT :	mov m.MainControlT_do_add_on_miss 0
	mov m.MainControlT_update_expire_time 0
	jmpneq LABEL_END m.pna_main_input_metadata_direction 0x1
	jmpnv LABEL_END h.ipv4
	jmpnv LABEL_END h.tcp
	table set_ct_options
	LABEL_END :	jmpnv LABEL_END_0 h.ipv4
	jmpnv LABEL_END_0 h.tcp
	jmpeq LABEL_TRUE_1 m.pna_main_input_metadata_direction 0x0
	mov m.MainControlT_key h.ipv4.dst_addr
	jmp LABEL_END_1
	LABEL_TRUE_1 :	mov m.MainControlT_key h.ipv4.src_addr
	LABEL_END_1 :	jmpeq LABEL_TRUE_2 m.pna_main_input_metadata_direction 0x0
	mov m.MainControlT_key_0 h.ipv4.src_addr
	jmp LABEL_END_2
	LABEL_TRUE_2 :	mov m.MainControlT_key_0 h.ipv4.dst_addr
	LABEL_END_2 :	jmpeq LABEL_TRUE_3 m.pna_main_input_metadata_direction 0x0
	mov m.MainControlT_key_1 h.tcp.dst_port
	jmp LABEL_END_3
	LABEL_TRUE_3 :	mov m.MainControlT_key_1 h.tcp.src_port
	LABEL_END_3 :	jmpeq LABEL_TRUE_4 m.pna_main_input_metadata_direction 0x0
	mov m.MainControlT_key_2 h.tcp.src_port
	jmp LABEL_END_4
	LABEL_TRUE_4 :	mov m.MainControlT_key_2 h.tcp.dst_port
	LABEL_END_4 :	mov m.MainControlImpl_ct_tcp_table_key m.MainControlT_key
	mov m.MainControlImpl_ct_tcp_table_key_0 m.MainControlT_key_0
	mov m.MainControlImpl_ct_tcp_table_ipv4_protocol h.ipv4.protocol
	mov m.MainControlImpl_ct_tcp_table_key_1 m.MainControlT_key_1
	mov m.MainControlImpl_ct_tcp_table_key_2 m.MainControlT_key_2
	table ct_tcp_table
	LABEL_END_0 :	jmpnv LABEL_END_5 h.ipv4
	table ipv4_host
	LABEL_END_5 :	emit h.ethernet
	emit h.ipv4
	emit h.tcp
	emit h.udp
	tx m.pna_main_output_metadata_output_port
}


