#!/bin/bash

'''
Usage:
    ifnofile <filepath> --script <script>
    ifnofile <filepath> --pycmd <codestr>

'''

import os, sys
import docopt


def main(args):

    path_string = args['<filepath>']
    if path_string[0] == '/':
        file_location = path_string

    else:
        file_location = os.path.join(os.getcwd(), path_string)
    
    if not os.path.exists(file_location):
        if args['--pycmd']:
            exec(args['<codestr>'])



if __name__ == '__main__':
    args = docopt.docopt(__doc__)
    main(args)