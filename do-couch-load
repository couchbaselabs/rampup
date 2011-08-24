#!/usr/bin/env ruby

host = ARGV[0]

p host

`curl -vX PUT http://#{host}:5984/default`

body = "x".ljust(1000, "x")
doc = "{\"body\":\"#{body}\"}"

i = 0
while i < 1000000
  print "i #{i}\n"
  j = 0
  s = []
  while j < 100
    print "j #{j}\n"
    s << doc
    j = j + 1
  end
  c = "curl -H\"Content-Type: application/json\" -vX POST http://#{host}:5984/default/_bulk_docs -d '{\"docs\":[#{s.join(',')}]}'"
  print "#{c}\n"
  `#{c}`
  i = i + j
end

sleep 2

