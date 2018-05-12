#!/usr/bin/env python3

import cgi
import json
import subprocess
#from subprocess import Popen, PIPE

import traceback
import sys
sys.stderr = sys.stdout

print("Content-type: text/html")
print()

form = cgi.FieldStorage()
if not form or "pen" not in form:
    print("error: no data received")
else:
    validated = json.loads(form["pen"].value)
    pen = str(validated).replace("'", "\"")


    #psql_env = dict(PGPASSWORD='piiwieyeequopoh0axaeciph6ea7ephogaijoochieteejainaimooG6oWiayie1')
    ## Create the subprocess.
    #proc = Popen("psql -h '/home/doersino/tmp' -", shell=True, env=psql_env, stdout=PIPE, stderr=PIPE)
    ## Try reading it's data.
    #data = proc.stdout.read()
    ## Check for errors.
    #err = proc.stderr.read()
    #if err: raise Exception(err)

    try:
        #psql = "psql"
        psql = "/package/host/localhost/postgresql-9.3/bin/psql"
        print("error: fix me")
        #print(subprocess.check_output(["ls", "-l", "/package/host/localhost/postgresql-9.3/bin/"], stderr=PIPE).decode("utf-8"))
        #print(subprocess.check_output([psql, "--version"], stderr=PIPE).decode("utf-8"))
        #print(subprocess.check_output([psql, "-h", "/home/doersino/tmp", "--variable=pen='test'", "-f", "test.sql"], stderr=PIPE).decode("utf-8"))
        #print(subprocess.check_output([psql, "-h", "/home/doersino/tmp", "--variable=pen='[ " + '{ "x": 69, "y": 153 }' + " ]'", "-f", "test.sql"], stderr=PIPE).decode("utf-8"))
        #print(subprocess.check_output([psql, "-h", "/home/doersino/tmp", "--variable=pen='[ " + pen + " ]'", "-f", "test.sql"], stderr=PIPE).decode("utf-8"))
    except subprocess.CalledProcessError as e:
        print(e.output)
        raise
