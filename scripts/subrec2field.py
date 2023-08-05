#!/usr/bin/env python

'''
Usage:
    subrec2field.py --parent <parent_file> --child <child_file> --field <field_name> [--limit=<limit>]

'''

import os, sys
import json
import docopt


def count_lines(filename):
    line_count = 0
    with open(filename, 'r') as f:
        for line in f:
            line_count += 1

    return line_count


def read_parent_records(jsonl_filename):

    with open(jsonl_filename, 'r') as f:
        for line in f:
            yield(json.loads(line))


def read_child_records(jsonl_filename):

    with open(jsonl_filename, 'r') as f:
        for line in f:
            yield(json.loads(line))


def main(args):

    if count_lines(args['<parent_file>']) != count_lines(args['<child_file>']):
        raise Exception('Parent and child datasets must be of the same length.')

    new_field_name = args['<field_name>']
    child_generator = read_child_records(args['<child_file>'])

    limit = -1
    if args['--limit']:
        limit = int(args['--limit'])

    record_count = 0
    for record in read_parent_records(args['<parent_file>']):

        if record_count == limit:
            break

        if record.__contains__(new_field_name):
            raise Exception(f'field "{new_field_name}" found in parent record. Will NOT overwrite.')
        
        record[new_field_name] = next(child_generator)

        print(json.dumps(record))
        record_count += 1


if __name__ == '__main__':
    args = docopt.docopt(__doc__)

    main(args)