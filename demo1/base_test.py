# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Antonin Bas (antonin@barefootnetworks.com)
#
#

from collections import Counter
from functools import wraps, partial
import re
import sys
import threading
import time
import Queue

#import ptf
#from ptf.base_tests import BaseTest
#from ptf import config
#import ptf.testutils as testutils

import grpc

from google.rpc import status_pb2, code_pb2
from p4.v1 import p4runtime_pb2
from p4.config.v1 import p4info_pb2
from p4.tmp import p4config_pb2
import google.protobuf.text_format

# See https://gist.github.com/carymrobbins/8940382
# functools.partialmethod is introduced in Python 3.4
class partialmethod(partial):
    def __get__(self, instance, owner):
        if instance is None:
            return self
        return partial(self.func, instance,
                       *(self.args or ()), **(self.keywords or {}))

# Convert integer (with length) to binary byte string
# Equivalent to Python 3.2 int.to_bytes
# See
# https://stackoverflow.com/questions/16022556/has-python-3-to-bytes-been-back-ported-to-python-2-7
def stringify(n, length):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s

def ipv4_to_binary(addr):
    bytes_ = [int(b, 10) for b in addr.split('.')]
    return "".join(chr(b) for b in bytes_)

def mac_to_binary(addr):
    bytes_ = [int(b, 16) for b in addr.split(':')]
    return "".join(chr(b) for b in bytes_)

# Used to indicate that the gRPC error Status object returned by the server has
# an incorrect format.
class P4RuntimeErrorFormatException(Exception):
    def __init__(self, message):
        super(P4RuntimeErrorFormatException, self).__init__(message)

# Used to iterate over the p4.Error messages in a gRPC error Status object
class P4RuntimeErrorIterator:
    def __init__(self, grpc_error):
        assert(grpc_error.code() == grpc.StatusCode.UNKNOWN)
        self.grpc_error = grpc_error

        error = None
        # The gRPC Python package does not have a convenient way to access the
        # binary details for the error: they are treated as trailing metadata.
        for meta in self.grpc_error.trailing_metadata():
            if meta[0] == "grpc-status-details-bin":
                error = status_pb2.Status()
                error.ParseFromString(meta[1])
                break
        if error is None:
            raise P4RuntimeErrorFormatException("No binary details field")

        if len(error.details) == 0:
            raise P4RuntimeErrorFormatException(
                "Binary details field has empty Any details repeated field")
        self.errors = error.details
        self.idx = 0

    def __iter__(self):
        return self

    def next(self):
        while self.idx < len(self.errors):
            p4_error = p4runtime_pb2.Error()
            one_error_any = self.errors[self.idx]
            if not one_error_any.Unpack(p4_error):
                raise P4RuntimeErrorFormatException(
                    "Cannot convert Any message to p4.Error")
            if p4_error.canonical_code == code_pb2.OK:
                continue
            v = self.idx, p4_error
            self.idx += 1
            return v
        raise StopIteration

# P4Runtime uses a 3-level message in case of an error during the processing of
# a write batch. This means that if we do not wrap the grpc.RpcError inside a
# custom exception, we can end-up with a non-helpful exception message in case
# of failure as only the first level will be printed. In this custom exception
# class, we extract the nested error message (one for each operation included in
# the batch) in order to print error code + user-facing message.  See P4 Runtime
# documentation for more details on error-reporting.
class P4RuntimeWriteException(Exception):
    def __init__(self, grpc_error):
        assert(grpc_error.code() == grpc.StatusCode.UNKNOWN)
        super(P4RuntimeWriteException, self).__init__()
        self.errors = []
        try:
            error_iterator = P4RuntimeErrorIterator(grpc_error)
            for error_tuple in error_iterator:
                self.errors.append(error_tuple)
        except P4RuntimeErrorFormatException:
            raise  # just propagate exception for now

    def __str__(self):
        message = "Error(s) during Write:\n"
        for idx, p4_error in self.errors:
            code_name = code_pb2._CODE.values_by_number[
                p4_error.canonical_code].name
            message += "\t* At index {}: {}, '{}'\n".format(
                idx, code_name, p4_error.message)
        return message

# Strongly inspired from _AssertRaisesContext in Python's unittest module
class _AssertP4RuntimeErrorContext(object):
    """A context manager used to implement the assertP4RuntimeError method."""

    def __init__(self, test_case, error_code=None, msg_regexp=None):
        self.failureException = test_case.failureException
        self.error_code = error_code
        self.msg_regexp = msg_regexp

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, tb):
        if exc_type is None:
            try:
                exc_name = self.expected.__name__
            except AttributeError:
                exc_name = str(self.expected)
            raise self.failureException(
                "{} not raised".format(exc_name))
        if not issubclass(exc_type, P4RuntimeWriteException):
            # let unexpected exceptions pass through
            return False
        self.exception = exc_value  # store for later retrieval

        if self.error_code is None:
            return True

        expected_code_name = code_pb2._CODE.values_by_number[
            self.error_code].name
        # guaranteed to have at least one element
        _, p4_error = exc_value.errors[0]
        code_name = code_pb2._CODE.values_by_number[
            p4_error.canonical_code].name
        if p4_error.canonical_code != self.error_code:
            # not the expected error code
            raise self.failureException(
                "Invalid P4Runtime error code: expected {} but got {}".format(
                    expected_code_name, code_name))

        if self.msg_regexp is None:
            return True

        if not self.msg_regexp.search(p4_error.message):
            raise self.failureException(
                "Invalid P4Runtime error msg: '{}' does not match '{}'".format(
                self.msg_regexp.pattern, p4_error.message))
        return True

# This code is common to all tests. setUp() is invoked at the beginning of the
# test and tearDown is called at the end, no matter whether the test passed /
# failed / errored.
class P4RuntimeTest():
    def setUp(self, grpc_addr, proto_txt_path):
        #BaseTest.setUp(self)
        self.device_id = 0

        # Setting up PTF dataplane
#        self.dataplane = ptf.dataplane_instance
#        self.dataplane.flush()

        self._swports = []
#        for device, port, ifname in config["interfaces"]:
#            self._swports.append(port)

#        grpc_addr = testutils.test_param_get("grpcaddr")
        if grpc_addr is None:
            grpc_addr = 'localhost:50051'

        self.channel = grpc.insecure_channel(grpc_addr)
        self.stub = p4runtime_pb2.P4RuntimeStub(self.channel)

#        proto_txt_path = testutils.test_param_get("p4info")
        print "Importing p4info proto from", proto_txt_path
        self.p4info = p4info_pb2.P4Info()
        with open(proto_txt_path, "rb") as fin:
            google.protobuf.text_format.Merge(fin.read(), self.p4info)

        self.import_p4info_names()

        # used to store write requests sent to the P4Runtime server, useful for
        # autocleanup of tests (see definition of autocleanup decorator below)
        self._reqs = []

        self.set_up_stream()

    # In order to make writing tests easier, we accept any suffix that uniquely
    # identifies the object among p4info objects of the same type.
    def import_p4info_names(self):
        self.p4info_obj_map = {}
        suffix_count = Counter()
        for obj_type in ["tables", "action_profiles", "actions", "counters",
                         "direct_counters"]:
            for obj in getattr(self.p4info, obj_type):
                pre = obj.preamble
                suffix = None
                for s in reversed(pre.name.split(".")):
                    suffix = s if suffix is None else s + "." + suffix
                    key = (obj_type, suffix)
                    self.p4info_obj_map[key] = obj
                    suffix_count[key] += 1
        for key, c in suffix_count.items():
            if c > 1:
                del self.p4info_obj_map[key]

    def set_up_stream(self):
        self.stream_out_q = Queue.Queue()
        self.stream_in_q = Queue.Queue()
        def stream_req_iterator():
            while True:
                p = self.stream_out_q.get()
                if p is None:
                    break
                yield p

        def stream_recv(stream):
            for p in stream:
                self.stream_in_q.put(p)

        self.stream = self.stub.StreamChannel(stream_req_iterator())
        self.stream_recv_thread = threading.Thread(
            target=stream_recv, args=(self.stream,))
        self.stream_recv_thread.start()

        self.handshake()

    def handshake(self):
        req = p4runtime_pb2.StreamMessageRequest()
        arbitration = req.arbitration
        arbitration.device_id = self.device_id
        # TODO(antonin): we currently allow 0 as the election id in P4Runtime;
        # if this changes we will need to use an election id > 0 and update the
        # Write message to include the election id
        # election_id = arbitration.election_id
        # election_id.high = 0
        # election_id.low = 1
        self.stream_out_q.put(req)

        rep = self.get_stream_packet("arbitration", timeout=2)
        if rep is None:
            self.fail("Failed to establish handshake")

    def tearDown(self):
        self.tear_down_stream()
        #BaseTest.tearDown(self)

    def tear_down_stream(self):
        self.stream_out_q.put(None)
        self.stream_recv_thread.join()

    def get_packet_in(self, timeout=1):
        msg = self.get_stream_packet("packet", timeout)
        if msg is None:
            self.fail("Packet in not received")
        else:
            return msg.packet

    def get_stream_packet(self, type_, timeout=1):
        start = time.time()
        try:
            while True:
                remaining = timeout - (time.time() - start)
                if remaining < 0:
                    break
                msg = self.stream_in_q.get(timeout=remaining)
                if not msg.HasField(type_):
                    continue
                return msg
        except:  # timeout expired
            pass
        return None

    def send_packet_out(self, packet):
        packet_out_req = p4runtime_pb2.StreamMessageRequest()
        packet_out_req.packet.CopyFrom(packet)
        self.stream_out_q.put(packet_out_req)

    def swports(self, idx):
        if idx >= len(self._swports):
            self.fail("Index {} is out-of-bound of port map".format(idx))
            return None
        return self._swports[idx]

    def get_obj(self, obj_type, name):
        key = (obj_type, name)
        return self.p4info_obj_map.get(key, None)

    def get_obj_id(self, obj_type, name):
        obj = self.get_obj(obj_type, name)
        if obj is None:
            return None
        return obj.preamble.id

    def get_param_id(self, action_name, name):
        a = self.get_obj("actions", action_name)
        if a is None:
            return None
        for p in a.params:
            if p.name == name:
                return p.id

    def get_mf_id(self, table_name, name):
        t = self.get_obj("tables", table_name)
        if t is None:
            return None
        for mf in t.match_fields:
            if mf.name == name:
                return mf.id

    # These are attempts at convenience functions aimed at making writing
    # P4Runtime PTF tests easier.

    class MF(object):
        def __init__(self, name):
            self.name = name

    class Exact(MF):
        def __init__(self, name, v):
            super(P4RuntimeTest.Exact, self).__init__(name)
            self.v = v

        def add_to(self, mf_id, mk):
            mf = mk.add()
            mf.field_id = mf_id
            mf.exact.value = self.v

    class Lpm(MF):
        def __init__(self, name, v, pLen):
            super(P4RuntimeTest.Lpm, self).__init__(name)
            self.v = v
            self.pLen = pLen

        def add_to(self, mf_id, mk):
            mf = mk.add()
            mf.field_id = mf_id
            mf.lpm.prefix_len = self.pLen
            mf.lpm.value = ''

            # P4Runtime now has strict rules regarding ternary matches: in the
            # case of LPM, trailing bits in the value (after prefix) must be set
            # to 0.
            first_byte_masked = self.pLen / 8
            for i in xrange(first_byte_masked):
                mf.lpm.value += self.v[i]
            if first_byte_masked == len(self.v):
                return
            r = self.pLen % 8
            mf.lpm.value += chr(
                ord(self.v[first_byte_masked]) & (0xff << (8 - r)))
            for i in range(first_byte_masked + 1, len(self.v)):
                mf.lpm.value += '\x00'

    class Ternary(MF):
        def __init__(self, name, v, mask):
            super(P4RuntimeTest.Ternary, self).__init__(name)
            self.v = v
            self.mask = mask

        def add_to(self, mf_id, mk):
            mf = mk.add()
            mf.field_id = mf_id
            assert(len(self.mask) == len(self.v))
            mf.ternary.mask = self.mask
            mf.ternary.value = ''
            # P4Runtime now has strict rules regarding ternary matches: in the
            # case of Ternary, "don't-care" bits in the value must be set to 0
            for i in xrange(len(self.mask)):
                mf.ternary.value += chr(ord(self.v[i]) & ord(self.mask[i]))

    # Sets the match key for a p4::TableEntry object. mk needs to be an iterable
    # object of MF instances
    def set_match_key(self, table_entry, t_name, mk):
        for mf in mk:
            mf_id = self.get_mf_id(t_name, mf.name)
            mf.add_to(mf_id, table_entry.match)

    def set_action(self, action, a_name, params):
        try:
            action.action_id = self.get_action_id(a_name)
        except TypeError:
            print("Failed to get id of action '%s' - perhaps the action name is misspelled?" % (a_name))
            raise
        for p_name, v in params:
            param = action.params.add()
            param.param_id = self.get_param_id(a_name, p_name)
            param.value = v

    # Sets the action & action data for a p4::TableEntry object. params needs to
    # be an iterable object of 2-tuples (<param_name>, <value>).
    def set_action_entry(self, table_entry, a_name, params):
        self.set_action(table_entry.action.action, a_name, params)

    def _write(self, req):
        try:
            return self.stub.Write(req)
        except grpc.RpcError as e:
            if e.code() != grpc.StatusCode.UNKNOWN:
                raise e
            raise P4RuntimeWriteException(e)

    def write_request(self, req, store=True):
        rep = self._write(req)
        if store:
            self._reqs.append(req)
        return rep

    #
    # Convenience functions to build and send P4Runtime write requests
    #

    def _push_update_member(self, req, ap_name, mbr_id, a_name, params,
                            update_type):
        update = req.updates.add()
        update.type = update_type
        ap_member = update.entity.action_profile_member
        ap_member.action_profile_id = self.get_ap_id(ap_name)
        ap_member.member_id = mbr_id
        self.set_action(ap_member.action, a_name, params)

    def push_update_add_member(self, req, ap_name, mbr_id, a_name, params):
        self._push_update_member(req, ap_name, mbr_id, a_name, params,
                                 p4runtime_pb2.Update.INSERT)

    def send_request_add_member(self, ap_name, mbr_id, a_name, params):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_member(req, ap_name, mbr_id, a_name, params)
        return req, self.write_request(req)

    def push_update_modify_member(self, req, ap_name, mbr_id, a_name, params):
        self._push_update_member(req, ap_name, mbr_id, a_name, params,
                                 p4runtime_pb2.Update.MODIFY)

    def send_request_modify_member(self, ap_name, mbr_id, a_name, params):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_modify_member(req, ap_name, mbr_id, a_name, params)
        return req, self.write_request(req, store=False)

    def push_update_add_group(self, req, ap_name, grp_id, grp_size=32,
                              mbr_ids=[]):
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        ap_group = update.entity.action_profile_group
        ap_group.action_profile_id = self.get_ap_id(ap_name)
        ap_group.group_id = grp_id
        ap_group.max_size = grp_size
        for mbr_id in mbr_ids:
            member = ap_group.members.add()
            member.member_id = mbr_id

    def send_request_add_group(self, ap_name, grp_id, grp_size=32, mbr_ids=[]):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_group(req, ap_name, grp_id, grp_size, mbr_ids)
        return req, self.write_request(req)

    def push_update_set_group_membership(self, req, ap_name, grp_id,
                                         mbr_ids=[]):
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.MODIFY
        ap_group = update.entity.action_profile_group
        ap_group.action_profile_id = self.get_ap_id(ap_name)
        ap_group.group_id = grp_id
        for mbr_id in mbr_ids:
            member = ap_group.members.add()
            member.member_id = mbr_id

    def send_request_set_group_membership(self, ap_name, grp_id, mbr_ids=[]):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_set_group_membership(req, ap_name, grp_id, mbr_ids)
        return req, self.write_request(req, store=False)

    #
    # for all add_entry function, use mk == None for default entry
    #
    # TODO(antonin): The current P4Runtime reference implementation on p4lang
    # does not support resetting the default entry (i.e. a DELETE operation on
    # the default entry), which is why we make sure not to include it in the
    # list used for autocleanup, by passing store=False to write_request calls.
    #

    def push_update_add_entry_to_action(self, req, t_name, mk, a_name, params):
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id(t_name)
        if mk is not None:
            self.set_match_key(table_entry, t_name, mk)
        else:
            table_entry.is_default_action = True
            update.type = p4runtime_pb2.Update.MODIFY
        self.set_action_entry(table_entry, a_name, params)

    def send_request_add_entry_to_action(self, t_name, mk, a_name, params):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_action(req, t_name, mk, a_name, params)
        return req, self.write_request(req, store=(mk is not None))

    # Just a shorter name for send_request_add_entry_to_action
    def table_add(self, table_name, key, action_name, action_params):
        return self.send_request_add_entry_to_action(table_name, key,
                                                     action_name, action_params)

    def push_update_add_entry_to_member(self, req, t_name, mk, mbr_id):
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id(t_name)
        if mk is not None:
            self.set_match_key(table_entry, t_name, mk)
        else:
            table_entry.is_default_action = True
        table_entry.action.action_profile_member_id = mbr_id

    def send_request_add_entry_to_member(self, t_name, mk, mbr_id):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_member(req, t_name, mk, mbr_id)
        return req, self.write_request(req, store=(mk is not None))

    def push_update_add_entry_to_group(self, req, t_name, mk, grp_id):
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id(t_name)
        if mk is not None:
            self.set_match_key(table_entry, t_name, mk)
        else:
            table_entry.is_default_action = True
        table_entry.action.action_profile_group_id = grp_id

    def send_request_add_entry_to_group(self, t_name, mk, grp_id):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        self.push_update_add_entry_to_group(req, t_name, mk, grp_id)
        return req, self.write_request(req, store=(mk is not None))

    # iterates over all requests in reverse order; if they are INSERT updates,
    # replay them as DELETE updates; this is a convenient way to clean-up a lot
    # of switch state
    def undo_write_requests(self, reqs):
        updates = []
        for req in reversed(reqs):
            for update in reversed(req.updates):
                if update.type == p4runtime_pb2.Update.INSERT:
                    updates.append(update)
        new_req = p4runtime_pb2.WriteRequest()
        new_req.device_id = self.device_id
        for update in updates:
            update.type = p4runtime_pb2.Update.DELETE
            new_req.updates.add().CopyFrom(update)
        rep = self._write(new_req)

    def assertP4RuntimeError(self, code=None, msg_regexp=None):
        if msg_regexp is not None:
            msg_regexp = re.compile(msg_regexp)
        context = _AssertP4RuntimeErrorContext(self, code, msg_regexp)
        return context

# Add p4info object and object id "getters" for each object type; these are just
# wrappers around P4RuntimeTest.get_obj and P4RuntimeTest.get_obj_id.
# For example: get_table(x) and get_table_id(x) respectively call
# get_obj("tables", x) and get_obj_id("tables", x)
for obj_type, nickname in [("tables", "table"),
                           ("action_profiles", "ap"),
                           ("actions", "action"),
                           ("counters", "counter"),
                           ("direct_counters", "direct_counter")]:
    name = "_".join(["get", nickname])
    setattr(P4RuntimeTest, name, partialmethod(
        P4RuntimeTest.get_obj, obj_type))
    name = "_".join(["get", nickname, "id"])
    setattr(P4RuntimeTest, name, partialmethod(
        P4RuntimeTest.get_obj_id, obj_type))

# this decorator can be used on the runTest method of P4Runtime PTF tests
# when it is used, the undo_write_requests will be called at the end of the test
# (irrespective of whether the test was a failure, a success, or an exception
# was raised). When this is used, all write requests must be performed through
# one of the send_request_* convenience functions, or by calling write_request;
# do not use stub.Write directly!
# most of the time, it is a great idea to use this decorator, as it makes the
# tests less verbose. In some circumstances, it is difficult to use it, in
# particular when the test itself issues DELETE request to remove some
# objects. In this case you will want to do the cleanup yourself (in the
# tearDown function for example); you can still use undo_write_request which
# should make things easier.
# because the PTF test writer needs to choose whether or not to use autocleanup,
# it seems more appropriate to define a decorator for this rather than do it
# unconditionally in the P4RuntimeTest tearDown method.
def autocleanup(f):
    @wraps(f)
    def handle(*args, **kwargs):
        test = args[0]
        assert(isinstance(test, P4RuntimeTest))
        try:
            return f(*args, **kwargs)
        finally:
            test.undo_write_requests(test._reqs)
    return handle


# I copied and modified the function bmv2_json_to_device_config() from
# some similar code in the p4lang/PI repository file
# PI/proto/ptf/bmv2/gen_bmv2_config.py

def bmv2_json_to_device_config(bmv2_json_fname, bmv2_bin_fname):
    with open(bmv2_bin_fname, 'wf') as f_out:
        with open(bmv2_json_fname, 'r') as f_json:
            device_config = p4config_pb2.P4DeviceConfig()
            device_config.device_data = f_json.read()
            f_out.write(device_config.SerializeToString())

# Copied update_config from the p4lang/PI repository in file
# PI/proto/ptf/ptf_runner.py, then modified it slightly:

def update_config(config_path, p4info_path, grpc_addr, device_id):
    '''
    Performs a SetForwardingPipelineConfig on the device with provided
    P4Info and binary device config
    '''
    channel = grpc.insecure_channel(grpc_addr)
    stub = p4runtime_pb2.P4RuntimeStub(channel)
    print("Sending P4 config")
    request = p4runtime_pb2.SetForwardingPipelineConfigRequest()
    request.device_id = device_id
    config = request.config
    with open(p4info_path, 'r') as p4info_f:
        google.protobuf.text_format.Merge(p4info_f.read(), config.p4info)
    with open(config_path, 'rb') as config_f:
        config.p4_device_config = config_f.read()
    request.action = p4runtime_pb2.SetForwardingPipelineConfigRequest.VERIFY_AND_COMMIT
    try:
        response = stub.SetForwardingPipelineConfig(request)
    except Exception as e:
        print("Error during SetForwardingPipelineConfig")
        print(str(e))
        return False
    return True
