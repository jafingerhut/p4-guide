#include <core.p4>
#include <v1model.p4>
#include "header_lengths.p4"

// After the following line, minSizeInBytes is now a name available in
// this P4 program, and can be used without any prefix.

from header_lengths import minSizeInBytes;

// The above line could cause a conflict with any top-level name
// defined as minSizeInBytes in the developer's program, just as if
// the line above were a definition of a function named
// minSizeInBytes.


// If the developer's program already had a name minSizeInBytes, and
// they wanted to continue using it, as well as the one in the
// namespace header_lengths, they could do this instead:

// import header_lengths as hdrlen;

// After the line of code above, the developer can use minSizeInBytes
// for their own definition of the name, or hdrlen.minSizeInBytes for
// the one defined in namespace header_lengths.

// The same name minSizeInBytes could be defined in any number of
// namespaces, and qualified in the same way, either with the full
// namespace name header_lengths, or a shorter alias chosen by the
// developer, in such a way that the alias name does not conflict with
// the other names they use.


struct headers_t {
}

struct metadata_t {
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        transition accept;
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    apply { }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply { }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
