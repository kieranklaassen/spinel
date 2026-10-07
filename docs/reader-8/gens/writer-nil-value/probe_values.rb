require_relative "dims"
require "open3"
dir = "/home/claude/r8/p220/pv"; Dir.mkdir(dir) unless Dir.exist?(dir)
VALUES.each_key do |v|
  src = build(w: "own", h: "none", v: v, r: "local", c: "stmt")
  f = "#{dir}/#{v}.rb"; File.write(f, src)
  ro, st = Open3.capture2e("ruby", "--enable-frozen-string-literal", f)
  cf = "#{dir}/#{v}.c"
  o, e, s = Open3.capture3("/home/claude/r8/m/bin/spinel", f, "-c", "-o", cf, "--force")
  kind = if !s.success? then "REFUSED " + e.lines.first.to_s.strip[0, 90]
         elsif File.read(cf) =~ /void lv___sv/ then "VOIDTEMP"
         else t = File.read(cf)[/(\S+) lv___sv\d+ = /, 1]; "builds? temp=#{t.inspect}" end
  puts "#{v.ljust(10)} ruby=#{st.success? ? 'ok' : 'ERR ' + ro.lines.first.to_s.strip[0,60]} master: #{kind}"
end
