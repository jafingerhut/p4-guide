import logging

import p4runtime_sh.p4runtime as p4rt
import p4runtime_sh.shell as sh


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

def dump_table(table_name_str):
    tes = []
    def do_save_te(te):
        tes.append(te)
    sh.TableEntry(table_name_str).read(lambda te: do_save_te(te))
    for te in tes:
        logging.info(str(te))
    logging.info("Table %s contains %d entries" % (table_name_str, len(tes)))
