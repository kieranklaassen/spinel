#!/usr/bin/env ruby
# usage: rubycheck.rb DIR : runs every program under CRuby twice, the second
# time after 37 object ids were handed out, and lists programs whose stdout
# differs (they print an id) or that fail to parse.
require "open3"
dir = ARGV[0]
files = Dir[File.join(dir, "*.rb")].sort
q = Queue.new; files.each { |f| q << f }
bad = []; syn = []; mu = Mutex.new
2.times.map do
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      o1, e1, s1 = Open3.capture3("ruby", "--enable-frozen-string-literal", f)
      o2, e2, s2 = Open3.capture3("ruby", "--enable-frozen-string-literal", "-e", "37.times { Object.new.object_id }; load ARGV[0]", f)
      mu.synchronize do
        syn << File.basename(f) if e1 =~ /SyntaxError|syntax error/
        bad << File.basename(f) if o1 != o2 || s1.exitstatus != s2.exitstatus
      end
    end
  end
end.each(&:join)
puts "syntax: #{syn.size} #{syn.first(20).join(' ')}"
puts "prints an id: #{bad.size}"
puts bad
