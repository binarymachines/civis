#!/usr/bin/env python


import os, sys
import json
import datetime


def now(**macro_args):
    return datetime.datetime.today().isoformat().replace(":", ".")

