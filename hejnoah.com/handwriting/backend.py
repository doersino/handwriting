#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Designed to run on Uberspace. Get yourself an account and follow these guides:
# https://wiki.uberspace.de/database:postgresql
# https://gist.github.com/tessi/82981559017f79a06042d2229bfd72a8 (s/9.6/10.4/g)

import cgi
import json
import subprocess
#from subprocess import Popen, PIPE

#import traceback
#import sys
#import os
#sys.stderr = sys.stdout

print("Content-type: text/html")
print()

form = cgi.FieldStorage()
if not form or "pen" not in form:
    print("error: no data received")
else:
    validated = json.loads(form["pen"].value)
    pen = str(validated).replace("'", "\"")

    try:
        print(subprocess.check_output(["bash", "backendhelper.sh", pen], stderr=PIPE).decode("utf-8").strip())
    except subprocess.CalledProcessError as e:
        #print(something went wrong, sorry about that)
        raise
