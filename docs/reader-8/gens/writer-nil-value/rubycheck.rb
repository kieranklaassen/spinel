require "open3"
errs = Hash.new { |h, k| h[k] = [] }
files = ARGV.flat_map { |d| Dir["#{d}/*.rb"] }.sort
q = Queue.new; files.each { |f| q << f }; mu = Mutex.new
2.times.map { Thread.new { while (f = (q.pop(true) rescue nil))
  o, e, st = Open3.capture3("ruby", "--enable-frozen-string-literal", f)
  next if st.success?
  k = e[/\(([A-Z]\w+)\)/, 1] || e.lines.first.to_s[0, 60]
  k = "SYNTAX" if e =~ /syntax error|SyntaxError/
  mu.synchronize { errs[k] << f.sub("/home/claude/r8/p220/", "") }
end } }.each(&:join)
errs.each { |k, v| puts "#{k}: #{v.size}  #{v.first(6).join(' ')}" }
puts "files #{files.size}"
