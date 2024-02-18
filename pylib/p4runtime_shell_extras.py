# Copyright 2023 Intel Corporation

import logging

from google.rpc import code_pb2
import p4runtime_sh.p4runtime as p4rt
import p4runtime_sh.shell as sh


def as_list_of_dicts(exc):
    """Take an exception object that has been thrown by a method such
    as p4runtime_sh.shell.TableEntry.insert(), and create a list of
    Python dicts that can be used to access various fields within this
    exception."""
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

def ssl_opts_for_certs_directory(certs_dir):
    """Create and return an object with class
    p4runtime_sh.p4runtime.SSLOptions.  Such an object must be passed
    as the value of the ssl_options optional parameter of the method
    p4runtime_sh.shell.setup when establishing a gRPC connection to a
    P4Runtime API server that is configured to require clients to
    authenticate themselves."""
    root_certificate = certs_dir + '/ca.crt'
    private_key = certs_dir + '/client.key'
    certificate_chain = certs_dir + '/client.crt'
    ssl_opts = p4rt.SSLOptions(False, root_certificate, certificate_chain,
                               private_key)
    return ssl_opts

def entry_count(table_name, print_entries=False):
    """Count the number of entries currently installed in the table
    named by the string tname, by reading them and counting them.  If
    print_entries is True, also print the entries as they were read.
    Return the number of entries found."""
    te = sh.TableEntry(table_name)
    n = 0
    for x in te.read():
        if print_entries:
            print(x)
        n = n + 1
    return n

def init_key_from_read_tableentry(read_te):
    new_te = sh.TableEntry(read_te.name)
    for fld_name in read_te.match._fields:
        fld = read_te.match[fld_name]
        _fld = read_te.match._fields[fld_name]
        if fld is None:
            # This happens when the field is lpm, ternary, optional,
            # or range, and the field value can be any legal value for
            # the type, i.e. it is completely wildcarded.  In this
            # case we should not add anything to new_te for this
            # field.
            continue
        if _fld.match_type == _fld.EXACT:
            val_int = int.from_bytes(fld.exact.value, 'big')
            new_te.match[fld_name] = '%d' % (val_int)
        elif _fld.match_type == _fld.TERNARY:
            logging.debug('fld_name=%s fld=%s' % (fld_name, fld))
            val_int = int.from_bytes(fld.ternary.value, 'big')
            mask_int = int.from_bytes(fld.ternary.mask, 'big')
            # mask_int should always be non-0 if it appears in an
            # entry read by a correct P4Runtime API server, but let us
            # be extra-cautious.
            if mask_int != 0:
                new_te.match[fld_name] = '%d&&&%d' % (val_int, mask_int)
        else:
            # TODO handle match kinds: lpm, optional, range
            logging.error("Unimplemented match_type %d for field %s of the following table entry:"
                          "" % (_fld.match_type, fld_name))
            logging.error(read_te)
    if hasattr(read_te, 'priority'):
        new_te.priority = read_te.priority
    return new_te

def delete_all_entries(tname, print_entries=False):
    """Delete all entries from the table named by the string tname, by
    reading them and deleting each one read.  If print_entries is
    True, also print the entries as they were read.  Return the number
    of entries deleted."""
    te = sh.TableEntry(tname)
    n = 0
    for e in te.read():
        if print_entries:
            print(e)
        d = init_key_from_read_tableentry(e)
        d.delete()
        n += 1
    return n

def read_table_default_entry(table_name_str):
    te = sh.TableEntry(table_name_str)
    te.is_default = True
    n = 0
    for x in te.read():
        default_entry = x
        n += 1
        if n > 1:
            logging.error("read_table_default_entry() found more than one default entry for table '%s'"
                          "" % (table_name_str))
    return default_entry
