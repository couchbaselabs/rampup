#!/usr/bin/env python

import re
import sys
import json
import time

import couchdb

MAP_DEF = """
(doc) ->
  doc.details.forEach((deet) ->
                       lbl = deet.label
                       m = lbl.match(/^(start|done)/)
                       if m
                          lbl = m[0]
                       if deet.elapsed
                          emit([doc.build, doc.vbuckets], [lbl, deet.elapsed])
                      )
"""

SUPERFLUOUS = re.compile("\.\.\.|view|membase")

exprs = [
    ('timestamp', re.compile(r'(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})')),
    ('label', re.compile(r'#\s+(.*)')),
    ('top', re.compile(r'.*\s+(\d+)m\s+(\d+)m.*\s+\w\s+(\d+.\d+).*(\d+:\d+\.\d+)\s+([A-z.]+)')),
    ('requests', re.compile(r'requests\s(\d+)')),
    ('reqs_per_sec', re.compile(r'req/sec\s(\d+\.\d+)')),
    ('time', re.compile(r'time (\d+\.\d+)')),
    ('time', re.compile(r'.*\s+(\d+:\d+\.\d+)\s*elapsed\s'))
]

def is_multi(field):
    return field == 'top'

def maybe_number(ob):
    try:
        if ':' in ob:
            parts = ob.split(':')
            assert len(parts) == 2
            return int(parts[0]) * 60 + float(parts[1])
        elif '.' in ob:
            return float(ob)
        else:
            return int(ob)
    except:
        return ob

def process_file(run, vbuckets, filename):

    current = {}
    parts = []
    prevtime = None

    for line in open(filename):
        name = None
        for name, r in exprs:
            match = r.search(line)
            if match:
                field = name
                break

        if match:
            if field == 'label':
                val = SUPERFLUOUS.sub('', match.groups()[0]).strip()
                if current:
                    parts.append(current)
                current = {'label': val}
            elif field == 'timestamp':
                current['timeparts'] = [maybe_number(x) for x in match.groups()]
                t = int(time.mktime(tuple(current['timeparts']) + (-1, -1, -1)))
                current['unixtime'] = t
                if prevtime:
                    # current['elapsed'] = t - prevtime
                    parts[-1]['elapsed'] = t - prevtime
                prevtime = t
            else:
                val = [maybe_number(x) for x in match.groups()]
                if len(val) == 1:
                    val = val[0]
                if is_multi(field):
                    if field not in current:
                        current[field] = []
                        current[field].append(val)
                else:
                    current[field] = maybe_number(val)

    parts.append(current)

    db = couchdb.Server('http://localhost:5984/')['viewperf']
    db.update([{'build': run, 'run': run, 'vbuckets': vbuckets, 'details': parts}])

if __name__ == '__main__':

    run = sys.argv[1]

    for f in sys.argv[2:]:
        vbs = int(f.split('-')[-1])
        process_file(run, vbs, f)

    # json.dump(parts, sys.stdout, indent=True)
