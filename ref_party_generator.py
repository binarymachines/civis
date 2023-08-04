#!/usr/bin/env python

# generate records for the ref_party table

''''''


p_types = [
    {'abbrev': 'DEM', 'desc': 'Democratic'},
    {'abbrev': 'REP', 'desc': 'Republican'},
    {'abbrev': 'NOPTY', 'desc': 'No Party'},
]

def line_array_generator(**kwargs):    
    id = 1
    for p_type in p_types:
        yield [id, f"\'{p_type['abbrev']}\'", f"\'{p_type['desc']}\'"]
        id += 1 