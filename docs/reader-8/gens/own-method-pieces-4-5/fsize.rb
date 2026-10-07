# usage: fsize.rb TREE_A TREE_B file...  : length of every function whose length differs, and of the named ones
def functions(src)
  out = {}
  name = start = nil
  src.each_line.with_index(1) do |line, i|
    if start.nil? && line !~ /\A(?:if|for|while|switch|return|else)\b/ &&
       (m = line.match(/\A(?:static\s+)?(?:inline\s+)?[\w\s*]+?\b(\w+)\s*\([^;]*\)\s*\{\s*\z/))
      name = m[1]; start = i
    elsif start && line.start_with?("}")
      out[name] = [out[name].to_i, i - start + 1].max; start = nil
    end
  end
  out
end
a, b, *files = ARGV
want = %w[infer_universal_call emit_call_identity_arms infer_call_inner infer_object_call emit_call_display_ivar_arms emit_object_ivar_call emit_object_call emit_call_body]
files.each do |f|
  fa = functions(File.read(File.join(a, f))); fb = functions(File.read(File.join(b, f)))
  (fa.keys | fb.keys).each do |fn|
    next unless fa[fn] != fb[fn] || want.include?(fn)
    puts "#{f}: #{fn}: #{fa[fn].inspect} -> #{fb[fn].inspect}#{fa[fn] != fb[fn] ? '  CHANGED' : ''}#{fa[fn].to_i > 1000 ? '  (over 1000 on master)' : ''}"
  end
end
