# function lengths before/after, by tools/gate.rb's own rule.  usage: fnsize.rb REPO BEFORE AFTER
repo, a, b = ARGV
def functions(src)
  out = {}
  name = start = nil
  src.b.each_line.with_index(1) do |line, i|
    if start.nil? && line !~ /\A(?:if|for|while|switch|return|else)\b/ &&
       (m = line.match(/\A(?:static\s+)?(?:inline\s+)?[\w\s*]+?\b(\w+)\s*\([^;]*\)\s*\{\s*\z/))
      name = m[1]; start = i
    elsif start && line.start_with?("}")
      out[name] = [out[name].to_i, i - start + 1].max; start = nil
    end
  end
  out
end
files = `git -C #{repo} diff --name-only #{a} #{b} -- src`.split("\n").grep(/\.c\z/)
files.each do |f|
  fa = functions(`git -C #{repo} show #{a}:#{f}`); fb = functions(`git -C #{repo} show #{b}:#{f}`)
  (fa.keys | fb.keys).each do |fn|
    next if fa[fn] == fb[fn]
    puts "#{f}: #{fn}: #{fa[fn] || 'new'} -> #{fb[fn] || 'gone'}"
  end
end
