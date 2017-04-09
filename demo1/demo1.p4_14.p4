header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type fwd_metadata_t {
    fields {
        l2ptr     : 32;
        out_bd    : 24;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;
metadata fwd_metadata_t fwd_metadata;

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum if (ipv4.ihl == 5);
    update ipv4_checksum if (ipv4.ihl == 5);
}

parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

// Why bother creating an action that just does one primitive action?
// That is, why not just use 'drop' as one of the possible actions
// when defining a table?  Because the P4_14 compiler does not allow
// primitve actions to be used directly as actions of tables.  You
// must use 'compound actions', i.e. ones explicitly defined with the
// 'action' keyword like below.

action my_drop() {
    drop();
}

action set_l2ptr(l2ptr) {
    modify_field(fwd_metadata.l2ptr, l2ptr);
}

table ipv4_da_lpm {
    reads {
        ipv4.dstAddr       : lpm;
    }
    actions {
        set_l2ptr;
        my_drop;
    }
}

action set_bd_dmac_intf (bd, dmac, intf) {
    modify_field(fwd_metadata.out_bd, bd);
    modify_field(ethernet.dstAddr, dmac);
    modify_field(standard_metadata.egress_spec, intf);
    add_to_field(ipv4.ttl, -1);
}

table mac_da {
    reads {
        fwd_metadata.l2ptr : exact;
    }
    actions {
        set_bd_dmac_intf;
        my_drop;
    }
}

action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table send_frame {
    reads {
        fwd_metadata.out_bd : exact;
    }
    actions {
        rewrite_mac;
        my_drop;
    }
}

control ingress {
    apply(ipv4_da_lpm);
    apply(mac_da);
}

control egress {
    apply(send_frame);
}
