#!/usr/bin/env ruby
# half2.rb LIST_OR_DIR... [--share] : the twin test's second half, by script, for every program given.
# Master's C declares `void lv___svN = EXPR;` and reads lv___svN twice: once as the writer's argument, once as
# the assignment's value. The piece's C is expected to be master's with EXPR in the argument's place and 0 as the
# value, and nothing else changed but temporaries' numbers. Prints programs for which that does not hold.
require "open3"
share = !ARGV.delete("--share").nil?
T = { "m" => "/home/claude/r8/m", "p" => "/home/claude/r8/p220/piece-tree-220" }
files = ARGV.flat_map { |d| File.directory?(d) ? Dir["#{d}/*.rb"] : File.readlines(d, chomp: true) }.sort
def gen(t, f, share, ti)
  cf = "/home/claude/r8/p220/tmp/h2.#{$$}.#{ti}.c"
  cmd = ["#{T[t]}/bin/spinel", f, "-c", "-o", cf, "--force"]; cmd << "--share-strings" if share
  o, e, st = Open3.capture3(*cmd)
  return nil unless st.success? && File.exist?(cf)
  s = File.read(cf).gsub(T[t] + "/", "/T/"); File.delete(cf); s
end
def renum(s)
  seen = Hash.new { |h, k| h[k] = {} }
  s.gsub(/\b((?:lv_)?_+[A-Za-z_]*?)(\d+)(?=[A-Za-z_]*\b)/) { pre = $1; n = $2; m = seen[pre]; m[n] ||= m.size; "#{pre}#{m[n]}" }
end
def norm(s) = s.lines.reject { |l| l =~ /^#line / || l.strip.empty? }.join
ok = 0; bad = []; skipped = 0
q = Queue.new; files.each { |f| q << f }; mu = Mutex.new
2.times.map do |ti|
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      m = gen("m", f, share, ti); p = gen("p", f, share, ti)
      if m.nil? || p.nil? then mu.synchronize { skipped += 1 }; next end
      if m == p then mu.synchronize { skipped += 1 }; next end
      m2 = m.dup
      # innermost first: a void temporary's EXPR may itself read an earlier one
      decls = m2.scan(/void lv_(__sv\d+) = /)
      decls.each do |(name)|
        m2 =~ /void lv_#{name} = (.*?); \n/m or next
        expr = $1
        # master writes `(EXPR)` where the piece writes EXPR: drop one outer pair that encloses the whole text
        if expr.start_with?("(") && !expr.start_with?("({") && expr.end_with?(")")
          d = 0; whole = true
          expr.each_char.with_index { |ch, i| d += 1 if ch == "("; d -= 1 if ch == ")"; (whole = false; break) if d == 0 && i < expr.size - 1 }
          expr = expr[1..-2] if whole
        end
        m2 = m2.sub(/^[ \t]*void lv_#{name} = .*?; \n/m, "")
        m2 = m2.gsub("); lv_#{name}; })", "); 0; })")
        m2 = m2.gsub("lv_#{name}") { expr }
      end
      a = renum(norm(m2)); b = renum(norm(p))
      if a == b then mu.synchronize { ok += 1 }
      else
        al = a.lines; bl = b.lines
        i = (0...[al.size, bl.size].min).find { |k| al[k] != bl[k] } || [al.size, bl.size].min
        mu.synchronize { bad << [f, al[i].to_s.strip[0, 200], bl[i].to_s.strip[0, 200]] }
      end
    end
  end
end.each(&:join)
puts "half 2: #{ok} programs whose C is master's with the void temporary's expression in the argument's place; #{bad.size} others; #{skipped} skipped (C identical or a tree refuses)"
bad.sort.first((ENV["SHOW"] || 15).to_i).each { |f, x, y| puts "  #{f}\n    m: #{x}\n    p: #{y}" }
File.write("/home/claude/r8/p220/half2-bad#{share ? '-share' : ''}.list", bad.map(&:first).sort.join("\n") + "\n")
