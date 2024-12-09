# Introduction

There was an effort during 2021 to come up with a proposed P4 include
file that would be for P4 what include files like
/usr/include/netinet/ip.h, ip6.h, tcp.h, udp.h are for Unix/Linux
software development.  That is, they are a reasonable choice to use
for writing programs that access or manipulate these header formats.

Alan Lo (loa.alan@gmail.com) led this effort, and wrote the document
"Portable P4 Headers - PPH.odt" with what he learned.

Aside: There are many comments in that document, made by someone else
reviewing it, but they are not necessary for understanding the
content.

The file stdheaders.p4 in this directory is extracted from that
document, with copyright info added at the beginning.
