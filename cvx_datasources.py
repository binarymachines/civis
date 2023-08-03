#!/usr/bin/env python


from array import array
from datetime import datetime



class CivixDatasource(object):

    def __init__(self, service_registry):
        self.services = service_registry

    def lookup_test(self, target_field_name, source_record, field_value_map):
        pass
