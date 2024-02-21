/*
Copyright 2024 Andy Fingerhut (andy.fingerhut@gmail.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*

A tiny little program that uses libpcap to act as a 2-port Ethernet
hub between two Linux interfaces.  It was written in hopes of using it
to "glue together" a veth to a TAP interface.

If there are standard Linux tools for doing this, I was unaware of
them at the time of writing this program.

*/

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/time.h>
#include <pcap/pcap.h>


#define MAX_QDEPTH  100
#define MAX_SNAPLEN_BYTES 16384

struct qelem_t {
    struct pcap_pkthdr pkt_info;
    u_char pkt_data[MAX_SNAPLEN_BYTES];
};

#define MAX_INTFS 2

int debug_level = 1;
int num_intfs;
char *intf_name[MAX_INTFS+1];
int qdepth[MAX_INTFS+1];
int qhead[MAX_INTFS+1];
int qtail[MAX_INTFS+1];
struct qelem_t qelem[MAX_INTFS+1][MAX_QDEPTH];


int setup_interface(const char *in_intfname,
                    pcap_t **out_p,
                    int *out_fd)
{
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *p;
    int ret;
    int timeout_msec;
    int snaplen;
    int link_hdr_type;
    int fd;

    p = pcap_create(in_intfname, errbuf);
    if (p == NULL) {
        fprintf(stderr, "pcap_create on '%s' failed with error: %s\n",
                in_intfname, errbuf);
        return -1;
    }
    
    ret = pcap_set_promisc(p, 1);
    if (ret != 0) {
        fprintf(stderr, "pcap_set_promisc on '%s' failed with return %d\n",
                in_intfname, ret);
        return PCAP_ERROR_NOT_ACTIVATED;
    }
    if (debug_level >= 1) {
        fprintf(stderr, "Successfully put '%s' in promiscuous mode\n",
                in_intfname);
    }

    timeout_msec = 100;
    ret = pcap_set_timeout(p, timeout_msec);
    if (ret != 0) {
        fprintf(stderr, "pcap_set_timeout on '%s' failed with return %d\n",
                in_intfname, ret);
        return PCAP_ERROR_NOT_ACTIVATED;
    }
    if (debug_level >= 1) {
        fprintf(stderr, "Successfully set timeout on '%s' to %d millisec\n",
                in_intfname, timeout_msec);
    }

    ret = pcap_activate(p);
    if (ret < 0) {
        fprintf(stderr, "pcap_activate on '%s' experienced error: %s\n",
                in_intfname, pcap_geterr(p));
        pcap_close(p);
        return ret;
    } else if (ret > 0) {
        fprintf(stderr, "warning from pcap_activate on '%s': %s\n",
                in_intfname, pcap_geterr(p));
    }

    snaplen = pcap_snapshot(p);
    if (snaplen == PCAP_ERROR_NOT_ACTIVATED) {
        fprintf(stderr, "pcap_snapshot on '%s' failed\n",
                in_intfname);
        return PCAP_ERROR_NOT_ACTIVATED;
    }
    if (debug_level >= 1) {
        printf("interface '%s' snaplen is %d\n", in_intfname, snaplen);
    }

    link_hdr_type = pcap_datalink(p);
    if (link_hdr_type == PCAP_ERROR_NOT_ACTIVATED) {
        fprintf(stderr, "pcap_datalink on '%s' failed\n",
                in_intfname);
        return PCAP_ERROR_NOT_ACTIVATED;
    }
    if (debug_level >= 1) {
        fprintf(stderr, "interface '%s' link-layer header type is %d\n",
                in_intfname, link_hdr_type);
    }

    if (out_fd != NULL) {
        fd = pcap_get_selectable_fd(p);
        if (fd < 0) {
            fprintf(stderr, "pcap_get_selectable_fd on '%s' failed\n",
                    in_intfname);
            return fd;
        }
        if (debug_level >= 1) {
            fprintf(stderr, "interface '%s' selectable fd=%d\n", in_intfname, fd);
        }
        *out_fd = fd;
    }
    *out_p = p;
    return 0;
}

void validate_qid(int qid) {
    if ((qid < 1) || (qid > 2)) {
        fprintf(stderr, "Internal error: qid=%d is not in range [1,2]\n",
                qid);
        exit(1);
    }
}

void init_queue(int qid) {
    validate_qid(qid);
    qdepth[qid] = 0;
    qhead[qid] = 0;
    qtail[qid] = 0;
}

int queue_len(int qid) {
    validate_qid(qid);
    return qdepth[qid];
}

void enqueue(int qid,
             const struct pcap_pkthdr *in_pkt_info,
             const u_char *in_pkt_data)
{
    int t;
    int bytes_to_copy;

    validate_qid(qid);
    if (qdepth[qid] == MAX_QDEPTH) {
        fprintf(stderr, "Internal error: enqueue called on qid=%d when its depth was already MAX_QDEPTH=%d\n",
                qid, MAX_QDEPTH);
        exit(1);
    }
    t = qtail[qid];
    memcpy(&(qelem[qid][t].pkt_info), in_pkt_info, sizeof(struct pcap_pkthdr));
    bytes_to_copy = in_pkt_info->caplen;
    if (bytes_to_copy > MAX_SNAPLEN_BYTES) {
        fprintf(stderr, "Captured packet with %u bytes, larger than maximum expected %u\n",
                bytes_to_copy, MAX_SNAPLEN_BYTES);
        exit(1);
    }
    memcpy(&(qelem[qid][t].pkt_data), in_pkt_data, bytes_to_copy);

    ++qtail[qid];
    if (qtail[qid] == MAX_QDEPTH) {
        qtail[qid] = 0;
    }
    ++qdepth[qid];
    if (debug_level >= 3) {
        fprintf(stderr, "Successfully enqueued packet to qid=%d new qdepth %d\n",
                qid, qdepth[qid]);
    }
}

void dequeue(int qid,
             struct pcap_pkthdr **out_pkt_info,
             u_char **out_pkt_data)
{
    int h;

    validate_qid(qid);
    if (qdepth[qid] == 0) {
        fprintf(stderr,
                "Internal error: dequeue called on qid=%d when its depth was 0\n",
                qid);
        exit(1);
    }
    h = qhead[qid];
    *out_pkt_info = &(qelem[qid][h].pkt_info);
    *out_pkt_data = &(qelem[qid][h].pkt_data[0]);

    ++qhead[qid];
    if (qhead[qid] == MAX_QDEPTH) {
        qhead[qid] = 0;
    }
    --qdepth[qid];
}

void print_usage(FILE *f, char *progname) {
    fprintf(f, "usage:\n");
    fprintf(f, "    %s [-h] hub <intf1> <intf2>\n", progname);
    fprintf(f, "    %s [-h] cap <intf1>\n", progname);
}

/* Calculate t2 - t1 and return the result in *out_diff.  Assumes that
 * t2 is later than t1. */
void timeval_diff(const struct timeval *in_t1,
                  const struct timeval *in_t2,
                  struct timeval *out_diff)
{
    out_diff->tv_sec = in_t2->tv_sec - in_t1->tv_sec;
    out_diff->tv_usec = 0;
    if (in_t2->tv_usec < in_t1->tv_usec) {
        out_diff->tv_sec -= 1;
        out_diff->tv_usec += 1000000;
    }
    out_diff->tv_usec += in_t2->tv_usec;
    out_diff->tv_usec -= in_t1->tv_usec;
}

void debug_pkt(FILE *f,
               const char *msg,
               const struct pcap_pkthdr *pkt_info,
               const u_char *pkt_data)
{
    int ret;
    bpf_u_int32 i;
    bpf_u_int32 printlen;
    bpf_u_int32 max_printlen = 48;
    struct timeval now;
    struct timeval diff;

    ret = gettimeofday(&now, NULL);
    if (ret != 0) {
        fprintf(stderr, "gettimofday() returned status %d: %s\n",
                ret, strerror(errno));
        exit(1);
    }
    timeval_diff(&(pkt_info->ts), &now, &diff);
    fprintf(f, "%s", msg);
    fprintf(f, " captime %10lu.%06lu (%2lu.%06lu sec ago)",
            pkt_info->ts.tv_sec, pkt_info->ts.tv_usec,
            diff.tv_sec, diff.tv_usec);
    fprintf(f, " len %4u", pkt_info->caplen);
    printlen = pkt_info->caplen;
    if (printlen > max_printlen) {
        printlen = max_printlen;
    }
    for (i = 0; i < printlen; i++) {
        if ((i % 4) == 0) {
            fprintf(f, " ");
        }
        fprintf(f, "%02x", pkt_data[i]);
    }
    fprintf(f, "\n");
}

void hub_callback_func(u_char *user_data,
                       const struct pcap_pkthdr *pkt_info,
                       const u_char *pkt_data)
{
    int read_from;
    int qid_for_enq;
    char msg[512];

    read_from = *((int *) user_data);
    validate_qid(read_from);
    if (debug_level >= 1) {
        snprintf(msg, sizeof(msg), "read from %12s", intf_name[read_from]);
        debug_pkt(stderr, msg, pkt_info, pkt_data);
    }
    for (qid_for_enq = 1; qid_for_enq <= num_intfs; qid_for_enq++) {
        if (qid_for_enq == read_from) {
            continue;
        }
        if (debug_level >= 3) {
            fprintf(stderr, "just before enqueue(qid=%d)\n", qid_for_enq);
        }
        enqueue(qid_for_enq, pkt_info, pkt_data);
    }
}

void send_packet(int id, pcap_t *p,
                 const struct pcap_pkthdr *in_pkt_info,
                 const u_char *in_pkt_data)
{
    int ret;
    char msg[512];
    bpf_u_int32 pktlen;

    pktlen = in_pkt_info->caplen;
    ret = pcap_inject(p, in_pkt_data, pktlen);
    if (debug_level >= 1) {
        snprintf(msg, sizeof(msg), "sent to   %12s", intf_name[id]);
        debug_pkt(stderr, msg, in_pkt_info, in_pkt_data);
    }
    if (ret == pktlen) {
        return;
    }
    if (ret == PCAP_ERROR) {
        fprintf(stderr, "pcap_inject failed with status %d: %s\n",
                ret, pcap_geterr(p));
        exit(1);
    } else if (ret < pktlen) {
        fprintf(stderr, "pcap_inject wrote only %d out of expected %d bytes\n",
                ret, pktlen);
    } else {
        fprintf(stderr, "pcap_inject returned unexpected value %d for attempted write of packet with %d bytes\n",
                ret, pktlen);
        exit(1);
    }
}

void run_as_hub()
{
    int ret;
    pcap_t *pcap1;
    pcap_t *pcap2;
    int fd1;
    int fd2;
    int nfds;
    fd_set readfds;
    fd_set writefds;
    fd_set exceptfds;
    struct timeval timeout;
    int packets_written;
    int fd1_ready;
    int fd2_ready;
    int read_from_preference;
    int read_from;
    pcap_t *p;
    int max_packets_to_read = 1;
    struct pcap_pkthdr *tmp_pkt_info;
    u_char *tmp_pkt_data;

    ret = setup_interface(intf_name[1], &pcap1, &fd1);
    if (ret != 0) {
        exit(1);
    }
    ret = setup_interface(intf_name[2], &pcap2, &fd2);
    if (ret != 0) {
        exit(1);
    }
    num_intfs = 2;
    if ((fd1 >= FD_SETSIZE) || (fd2 >= FD_SETSIZE)) {
        fprintf(stderr,
                "At least one of fd1=%d or fd2=%d is greater than FD_SETSIZE=%d\n",
                fd1, fd2, FD_SETSIZE);
        exit(1);
    }
    nfds = fd1 + 1;
    if (fd2 > fd1) {
        nfds = fd2 + 1;
    }
    read_from_preference = 1;
    init_queue(1);
    init_queue(2);
    while (1) {
        FD_ZERO(&readfds);
        if (debug_level >= 3) {
            fprintf(stderr, "enabling for select:");
        }
        if (queue_len(2) < MAX_QDEPTH) {
            FD_SET(fd1, &readfds);
            if (debug_level >= 3) {
                fprintf(stderr, " rd1");
            }
        }
        if (queue_len(1) < MAX_QDEPTH) {
            FD_SET(fd2, &readfds);
            if (debug_level >= 3) {
                fprintf(stderr, " rd2");
            }
        }
        FD_ZERO(&writefds);
        if (queue_len(1) > 0) {
            FD_SET(fd1, &writefds);
            if (debug_level >= 3) {
                fprintf(stderr, " wr1");
            }
        }
        if (queue_len(2) > 0) {
            FD_SET(fd2, &writefds);
            if (debug_level >= 3) {
                fprintf(stderr, " wr2");
            }
        }
        if (debug_level >= 3) {
            fprintf(stderr, "\n");
            fflush(stderr);
        }
        timeout.tv_sec = 1;
        timeout.tv_usec = 0;
        ret = select(nfds, &readfds, &writefds, NULL, &timeout);
        if (ret < 0) {
            fprintf(stderr, "select returned error status %d: %s\n",
                    ret, strerror(ret));
            exit(1);
        }
        if (ret == 0) {
            if (debug_level >= 2) {
                fprintf(stderr, "select returned 0.  Trying again\n");
            }
            continue;
        }
        // ret > 0, so at least one descriptor is ready for reading or
        // writing.

        // Check for descriptors ready for writing first, in an
        // attempt to avoid queues building up too much.
        packets_written = 0;
        if ((queue_len(1) > 0) && FD_ISSET(fd1, &writefds)) {
            dequeue(1, &tmp_pkt_info, &tmp_pkt_data);
            send_packet(1, pcap1, tmp_pkt_info, tmp_pkt_data);
            ++packets_written;
        }
        if ((queue_len(2) > 0) && FD_ISSET(fd2, &writefds)) {
            dequeue(2, &tmp_pkt_info, &tmp_pkt_data);
            send_packet(2, pcap2, tmp_pkt_info, tmp_pkt_data);
            ++packets_written;
        }
        if (packets_written > 0) {
            continue;
        }
        // Take turns preferring which of fd1 or fd2 to read packets
        // from, in an attempt to provide a bit of fairness when they
        // both often have packets ready to read.
        read_from = 0;
        fd1_ready = FD_ISSET(fd1, &readfds);
        fd2_ready = FD_ISSET(fd2, &readfds);
        if (fd1_ready && fd2_ready) {
            read_from = read_from_preference;
            ++read_from_preference;
            if (read_from_preference > num_intfs) {
                read_from_preference = 1;
            }
        } else if (fd1_ready) {
            read_from = 1;
        } else if (fd2_ready) {
            read_from = 2;
        }
        if (read_from == 0) {
            fprintf(stderr, "select returned %d, but no bits were set in readfds or writefds\n",
                    ret);
            exit(1);
        }

        if (read_from == 1) {
            p = pcap1;
        } else {
            p = pcap2;
        }
        ret = pcap_dispatch(p, max_packets_to_read, hub_callback_func,
                            (u_char *) &read_from);
        if (ret == PCAP_ERROR) {
            fprintf(stderr, "pcap_dispatch returned error %d: %s\n",
                    ret, pcap_geterr(p));
            exit(1);
        } else if (ret == PCAP_ERROR_BREAK) {
            fprintf(stderr, "pcap_dispatch returned unexpected error %d: %s\n",
                    ret, pcap_geterr(p));
            exit(1);
        } else if (ret == 0) {
            fprintf(stderr, "pcap_dispatch returned 0 unexpectedly.  Continuing.\n");
        }
    }
}

void capture_callback_func(u_char *user_data,
                           const struct pcap_pkthdr *pkt_info,
                           const u_char *pkt_data)
{
    int read_from;
    int qid_for_enq;
    char msg[512];

    snprintf(msg, sizeof(msg), "read from %12s", intf_name[1]);
    debug_pkt(stderr, msg, pkt_info, pkt_data);
}

void capture_pkts()
{
    int ret;
    pcap_t *pcap1;

    ret = setup_interface(intf_name[1], &pcap1, NULL);
    if (ret != 0) {
        exit(1);
    }
    num_intfs = 1;
    ret = pcap_loop(pcap1, 0, capture_callback_func, NULL);
    if (ret != 0) {
        fprintf(stderr, "pcap_loop returned non-0 status %d\n", ret);
        exit(1);
    }
}

int main(int argc, char *argv[]) {
    char *progname;
    char errbuf[PCAP_ERRBUF_SIZE];
    int ret;
    char *cmd;

    progname = argv[0];
    if (argc < 2) {
        print_usage(stderr, progname);
        exit(1);
    }
    cmd = argv[1];
    if (strcmp(cmd, "hub") == 0) {
        if (argc < 4) {
            print_usage(stderr, progname);
            exit(1);
        }
        intf_name[1] = argv[2];
        intf_name[2] = argv[3];
        run_as_hub();
    } else if (strcmp(cmd, "cap") == 0) {
        if (argc < 3) {
            print_usage(stderr, progname);
            exit(1);
        }
        intf_name[1] = argv[2];
        capture_pkts();
    } else {
        print_usage(stderr, progname);
        exit(1);
    }
    exit(0);
}
