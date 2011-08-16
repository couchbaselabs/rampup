#!/usr/bin/env python

import re
import sys
import json
import time

import couchdb

def process_file(db, test, filename, run, build, num_items, num_nodes, num_vbuckets, val_size):

    details = []

    for line in open(filename):
        if line.find('done. elapsed: ') > 0:
            # Example line == "# 6. view-building... done. elapsed: 0.10278"
            #
            parts   = line.split(' ')
            step    = int(parts[1].rstrip('.'))
            label   = parts[2].rstrip('.')
            elapsed = float(parts[-1])

            details.append({ 'step': step, 'label': label, 'elapsed': elapsed })

    db.update([{'test': test, 'filename': filename, 'run': run, 'build': build,
                'items': num_items, 'nodes': num_nodes, 'vbuckets': num_vbuckets, 'val_size': val_size,
                'details': details}])

if __name__ == '__main__':

    if len(sys.argv) < 4:
        print("usage: " + sys.argv[0] + " http://HOST:5984/COUCH_DBNAME TEST_NAME OUT0 [OUT1 ... OUTN]\n")
        print("example: ./storeOutput.py http://127.0.0.1:5984/viewperf 289-physical out-20110815090708/test-20110815090708_couchbase-2.0.0r-289-gc0dbb43/*\n")
        print("Cooks the output files from runtests and uploads to couchdb.\n")
        exit('ERROR: not enough parameters')

    couch = sys.argv[1] # Ex: "http://localhost:5984/viewperf"
    test  = sys.argv[2] # Ex: "289-physical"

    couch_server = '/'.join(couch.split('/')[0:-1]) # Ex: 'http://localhost:5984/'
    couch_dbname = couch.split('/')[-1]             # Ex: 'viewperf'

    db = couchdb.Server(couch_server)[couch_dbname]

    for f in sys.argv[3:]:
        # Example f...
        #   "test-20110815090708_couchbase-2.0.0r-289-gc0dbb43/100000-1-1-1024.out"
        #   "out/test-20110815090708_couchbase-2.0.0r-289-gc0dbb43/100000-1-1-1024.out"
        #   "out-20110815090708/test-20110815090708_couchbase-2.0.0r-289-gc0dbb43/100000-1-1-1024.out"
        #
        run = f.split('/')[-2]     # Ex: "test-20110815090708_couchbase-2.0.0r-289-gc0dbb43"
        build = run.split('_')[-1] # Ex: "couchbase-2.0.0r-289-gc0dbb43"

        n = f.split('/')[-1].split('.')[0] # Ex: 100000-1-1-1024
        n = n.split('-')                   # Ex: [100000, 1, 1, 1024]

        num_items    = int(n[0])
        num_nodes    = int(n[1])
        num_vbuckets = int(n[2])
        val_size     = int(n[3])

        print(run, build, num_items, num_nodes, num_vbuckets, val_size)

        process_file(db, test, f, run, build, num_items, num_nodes, num_vbuckets, val_size)

