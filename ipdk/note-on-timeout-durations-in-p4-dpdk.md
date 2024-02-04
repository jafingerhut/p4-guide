# A note on timeout durations in P4-DPDK

The PNA specification says that targets can have multiple timer
expiration profiles, typically numbered 0 through MAX_PROFILES-1,
where each profile has an independently configurable expiration time,
configurable by the control plane software.

I do not know if these expiration times are configurable via the
control plane software yet in the P4-DPDK implementatioon, but you can
see how many such timer expiration profiles there are, and what their
initial expiration times are, from looking at the `.spec` file
produced by the `p4c-dpdk` compiler.

Below is the portion of the `add_on_miss0.spec` file output by
`p4c-dpdk` for the P4 table `ct_tcp_table`:

```
learner ct_tcp_table {
	key {
		m.MainControlImpl_ct_tcp_table_ipv4_src_addr
		m.MainControlImpl_ct_tcp_table_ipv4_dst_addr
		m.MainControlImpl_ct_tcp_table_ipv4_protocol
		m.MainControlImpl_ct_tcp_table_tcp_src_port
		m.MainControlImpl_ct_tcp_table_tcp_dst_port
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
```

The `key`, `actions`, `default_action`, and `size` properties
correspond very closely with the corresponding definitions of those
table properties in the P4 source code.

The `timeout` part is not from the P4 source code, but is a default
value included for tables with idle timeout durations, I believe
corresponding with those having a supported value of
`pna_idle_timeout` or `idle_timeout_with_auto_delete` table
properties.

There are 8 integer values in a sequence there.  Each is a timeout
interval in units of seconds.  They are given in the order of expire
time profile id values from 0 up through 7.  Thus the initial
expiration time interval for expire time profile 0 is 10 seconds.
Until and unless these values are configurable from the control plane
software, you can use these default values, or hand-edit the `.spec`
file to customize these initial values selected by `p4c-dpdk`.

The program `add_on_miss0.p4` always provides a value of 1 to
`add_entry` extern function calls for the initial expire time profile
id of table entries it adds, and then it never modifies them after
that.  Thus the expire time for all entries created in `ct_tcp_table`
will always be 30 seconds for program `add_on_miss0.p4`.
