Program: v1model-more-externs.p4

Note: ipv4_da_lpm_stats count() update operations seem like maybe they
should be inside of action definitions drop_with_count and set_l2ptr.
Table "ingress.ipv4_da_lpm" does have the property "with_counters"
with value true instead of false as all other tables in this program
do.  Maybe that is what v1model arch should do for tables with
counters table property, is to update the counter for every action of
the table, whether it has a count() primitive call or not?  If so,
that seems at least slightly confusing that count() operation is a
no-op for direct counters.

Compile source and run simple_switch:
```
p4c --target bmv2 --arch v1model v1model-more-externs.p4
sudo simple_switch --log-console -i 0@veth2 -i 1@veth4 -i 2@veth6 -i 3@veth8 -i 4@veth10 -i 5@veth12 -i 6@veth14 -i 7@veth16 v1model-more-externs.json
```

simple_switch_CLI setup commands:
```
tbd
table_set_default t_ingress_1 _resubmit1
table_set_default t_ingress_2 _resubmit2
```

Test sending a packet:

```
sudo scapy

resub_pkt=Ether() / IP() / TCP()
sendp(resub_pkt, iface="veth2")
```
