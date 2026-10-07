def functions(src)
  out = {}
  name = start = nil
  src.each_line.with_index(1) do |line, i|
    if start.nil? && line !~ /\A(?:if|for|while|switch|return|else)\b/ &&
       (m = line.match(/\A(?:static\s+)?(?:inline\s+)?[\w\s*]+?\b(\w+)\s*\([^;]*\)\s*\{\s*\z/))
      name = m[1]
      start = i
    elsif start && line.start_with?("}")
      out[name] = [out[name].to_i, i - start + 1].max
      start = nil
    end
  end
  out
end
a, b = ARGV
`git diff --name-only #{a} #{b} -- 'src/*.c'`.split("\n").each do |f|
  fa = functions(`git show #{a}:#{f}`.b); fb = functions(`git show #{b}:#{f}`.b)
  fb.each do |fn, n|
    was = fa[fn]
    next if was == n
    flag = (fn == "emit_call_body" && was && n > was) || (was && was > 1000 && n > was) || (was.nil? && n > 1000) ? "REFUSED BY THE RULE" : "ok"
    puts "#{f}: #{fn} #{was.inspect} -> #{n} lines  #{flag}"
  end
end
