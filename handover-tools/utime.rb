#!/usr/bin/env ruby
# utime.rb LABEL CMD...: run CMD (output dropped) and print its user and wall seconds
t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
pid = spawn(*ARGV[1..], out: File::NULL, err: File::NULL); Process.wait(pid)
w = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t
u = Process.times.cutime
printf("%s: user %.2f s, wall %.2f s, exit %d\n", ARGV[0], u, w, $?.exitstatus || -1)
