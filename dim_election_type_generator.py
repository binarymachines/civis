#!/usr/bin/env python

# generate records for election-type dimension table

types = {
    'S': 'special',
    'G': 'general',
    'P': 'primary',
    'SP': 'special primary',
    'SG': 'special general'
}


def line_array_generator(**kwargs):    
    id = 1
    for abbrev, label in types.items():
        yield [id, f"'{abbrev}'", f"'{label}'"]
        id += 1