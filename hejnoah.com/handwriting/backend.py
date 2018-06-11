#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Designed to run on Uberspace. Get yourself an account and follow these guides:
# https://wiki.uberspace.de/database:postgresql
# https://gist.github.com/tessi/82981559017f79a06042d2229bfd72a8 (s/9.6/10.4/g)

import cgi
import json
import subprocess

import traceback
import sys
sys.stderr = sys.stdout

# via https://stackoverflow.com/a/14860540
def enc_print(string='', encoding='utf8'):
    sys.stdout.buffer.write(string.encode(encoding) + b'\n')

enc_print("Content-type: text/html")
enc_print()

form = cgi.FieldStorage()
if not form or "pen" not in form:
    enc_print("no data received :(")
else:
    validated = json.loads(form["pen"].value)
    pen = str(validated).replace("'", "\"")

    try:
        enc_print(subprocess.check_output(["bash", "backendhelper.sh", pen]).decode("utf-8").strip())
    except subprocess.CalledProcessError as e:
        enc_print('something went wrong, sorry about that :(')
        raise
