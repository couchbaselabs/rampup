print "runtest #{ARGV.join(' ')}\n"

def run(cmd, use_system=false)
  print("#{cmd}\n")
  if use_system
    system(cmd)
  else
    `#{cmd}`
  end
end

run "mkdir -p out"
$out_file = "out/#{$test_name}"
run "rm -f #{$out_file}"

$time_curr = $time_start = Time.now
$time_prev = nil
$mesg_prev = nil
$work_prev = nil
$step_num  = 0

def step(mesg, cmd=nil, elapsed=nil, work=nil)
  $time_curr = Time.now

  if $time_prev
    elapsed = $time_curr - $time_prev unless elapsed

    if $mesg_prev and $work_prev and elapsed > 0
      print "#{$mesg_prev} #{$work_prev}, items/sec: #{$work_prev.to_f / elapsed}\n"
      `echo "#{$mesg_prev} #{$work_prev}, items/sec: #{$work_prev.to_f / elapsed}" >> #{$out_file}`
    end

    print "# #{$step_num}. #{$mesg_prev} done. elapsed: #{elapsed}\n"
    `echo "# #{$step_num}. #{$mesg_prev} done. elapsed: #{elapsed}" >> #{$out_file}`
  end

  $step_num  = $step_num + 1

  print "# #{$step_num}. #{mesg} #{$time_curr.strftime('%Y%m%d-%H%M%S')}\n"
  `echo "# #{$step_num}. #{mesg} #{$time_curr.strftime('%Y%m%d-%H%M%S')}" >> #{$out_file}`

  $time_prev = $time_curr
  $mesg_prev = mesg
  $work_prev = work

  time(cmd) if cmd
end

def time(cmd)
  system("top -U #{$top_user} | egrep #{$top_patt} > /tmp/top.out &")

  run cmd

  `killall top`
  `tail -n 50 /tmp/top.out | head -n 10 >> #{$out_file}`
end

