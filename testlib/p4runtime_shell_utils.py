import logging
from collections import Counter

from p4.config.v1 import p4info_pb2
from google.rpc import code_pb2
import google.protobuf.text_format
import p4runtime_sh.p4runtime as p4rt
import p4runtime_sh.shell as sh


def as_list_of_dicts(exc):
    lst = []
    for idx, p4_error in exc.errors:
        code_name = code_pb2._CODE.values_by_number[
            p4_error.canonical_code].name
        lst.append({'index': idx,
                    'code': p4_error.code,
                    'canonical_code': p4_error.canonical_code,
                    'code_name': code_name,
                    'details': p4_error.details,
                    'message': p4_error.message,
                    'space': p4_error.space})
    return lst

def mac_to_int(addr):
    """Take an argument 'addr' containing an Ethernet MAC address written
    as a string in hexadecimal notation, with each byte separated by a
    colon, e.g. '00:de:ad:be:ef:ff', and convert it to an integer."""
    bytes_ = [int(b, 16) for b in addr.split(':')]
    assert len(bytes_) == 6
    # Note: The bytes() call below will throw exception if any
    # elements of bytes_ is outside of the range [0, 255]], so no need
    # to add a separate check for that here.
    return int.from_bytes(bytes(bytes_), byteorder='big')

def ipv4_to_int(addr):
    """Take an argument 'addr' containing an IPv4 address written as a
    string in dotted decimal notation, e.g. '10.1.2.3', and convert it
    to an integer."""
    bytes_ = [int(b, 10) for b in addr.split('.')]
    assert len(bytes_) == 4
    # Note: The bytes() call below will throw exception if any
    # elements of bytes_ is outside of the range [0, 255]], so no need
    # to add a separate check for that here.
    return int.from_bytes(bytes(bytes_), byteorder='big')

def ipv6_to_int(addr):
    """Take an argument 'addr' containing an IPv6 address written in
    standard syntax, e.g. '2001:0db8::3210', and convert it to an
    integer."""
    bytes_ = socket.inet_pton(socket.AF_INET6, '2001:0db8::3210')
    # Note: The bytes() call below will throw exception if any
    # elements of bytes_ is outside of the range [0, 255]], so no need
    # to add a separate check for that here.
    return int.from_bytes(bytes_, byteorder='big')


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

        if not issubclass(exc_type, p4rt.P4RuntimeWriteException):
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

def assertP4RuntimeError(self, code=None, msg_regexp=None):
    if msg_regexp is not None:
        msg_regexp = re.compile(msg_regexp)
    context = _AssertP4RuntimeErrorContext(self, code, msg_regexp)
    return context

def read_p4info_txt_file(p4info_txt_fname):
    p4info_data = p4info_pb2.P4Info()
    with open(p4info_txt_fname, "rb") as fin:
        google.protobuf.text_format.Merge(fin.read(), p4info_data)
    return p4info_data

def serializable_enum_dict(p4info_data, name):
    type_info = p4info_data.type_info
    #logging.debug("serializable_enum_dict: data=%s"
    #              "" % (type_info.serializable_enums[name]))
    name_to_int = {}
    int_to_name = {}
    for member in type_info.serializable_enums[name].members:
        name = member.name
        int_val = int.from_bytes(member.value, byteorder='big')
        name_to_int[name] = int_val
        int_to_name[int_val] = name
    logging.debug("serializable_enum_dict: name='%s' name_to_int=%s int_to_name=%s"
                  "" % (name, name_to_int, int_to_name))
    return name_to_int, int_to_name

def read_table_normal_entries(table_name_str):
    tes = []
    def do_save_te(te):
        tes.append(te)
    sh.TableEntry(table_name_str).read(lambda te: do_save_te(te))
    return tes

def read_table_default_entry(table_name_str):
    te = sh.TableEntry(table_name_str)
    te.is_default = True
    for x in te.read():
        default_entry = x
    return default_entry

def read_all_table_entries(table_name_str):
    return read_table_normal_entries(table_name_str), \
        read_table_default_entry(table_name_str)

def dump_table(table_name_str):
    entries, default_entry = read_all_table_entries(table_name_str)
    logging.info("Table %s contains %d entries" % (table_name_str, len(entries)))
    for e in entries:
        logging.info(str(e))
    logging.info("Table %s default entry:" % (table_name_str))
    logging.info(default_entry)


# In order to make writing tests easier, we accept any suffix that uniquely
# identifies the object among p4info objects of the same type.
def make_p4info_obj_map(p4info_data):
    p4info_obj_map = {}
    suffix_count = Counter()
    for obj_type in ["tables", "action_profiles", "actions", "counters",
                     "direct_counters", "controller_packet_metadata"]:
        for obj in getattr(p4info_data, obj_type):
            pre = obj.preamble
            suffix = None
            for s in reversed(pre.name.split(".")):
                suffix = s if suffix is None else s + "." + suffix
                key = (obj_type, suffix)
                p4info_obj_map[key] = obj
                suffix_count[key] += 1
    for key, c in list(suffix_count.items()):
        if c > 1:
            del p4info_obj_map[key]
    return p4info_obj_map

def get_obj(p4info_obj_map, obj_type, name):
    key = (obj_type, name)
    return p4info_obj_map.get(key, None)

def get_obj_id(p4info_obj_map, obj_type, name):
    obj = get_obj(p4info_objmap, obj_type, name)
    if obj is None:
        return None
    return obj.preamble.id

def controller_packet_metadata_dict_key_id(p4info_obj_map, name):
    cpm_info = get_obj(p4info_obj_map, "controller_packet_metadata", name)
    assert cpm_info != None
    ret = {}
    for md in cpm_info.metadata:
        id = md.id
        ret[md.id] = {'id': md.id, 'name': md.name, 'bitwidth': md.bitwidth}
    return ret

def decode_packet_in_metadata(pktin_info, packet):
    pktin_field_to_val = {}
    for md in packet.metadata:
        md_id_int = md.metadata_id
        md_val_int = int.from_bytes(md.value, byteorder='big')
        assert md_id_int in pktin_info
        md_field_info = pktin_info[md_id_int]
        pktin_field_to_val[md_field_info['name']] = md_val_int
    ret = {'metadata': pktin_field_to_val,
           'payload': packet.payload}
    logging.debug("decode_packet_in_metadata: ret=%s" % (ret))
    return ret

def verify_packet_in(exp_pktinfo, received_pktinfo):
    if received_pktinfo != exp_pktinfo:
        logging.error("PacketIn packet received:")
        logging.error("%s" % (received_pktinfo))
        logging.error("PacketIn packet expected:")
        logging.error("%s" % (exp_pktinfo))
        assert received_pktinfo == exp_pktinfo
