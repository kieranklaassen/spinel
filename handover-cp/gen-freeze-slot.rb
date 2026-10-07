# Family: a class's own freeze or frozen? called on a boxed value, by how the
# value came to be boxed. Who defines the method x how the box is made x what
# else it can hold x which of the two it holds at run time x how the call is
# used. The class's method counts its calls in $n; each program prints the
# call's line (or the class of a NoMethodError) and then $n.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
DEF = {
  "fz_self" => "def freeze\n    $n += 1\n    self\n  end",
  "fz_sym"  => "def freeze\n    $n += 1\n    :mine\n  end",
  "fz_nil"  => "def freeze\n    $n += 1\n    nil\n  end",
  "fz_super" => "def freeze\n    $n += 1\n    super\n  end",
  "fr_true" => "def frozen?\n    $n += 1\n    true\n  end",
  "fr_sym"  => "def frozen?\n    $n += 1\n    :yes\n  end",
}
OTHER = { "nil" => "nil", "int" => "5", "str" => "\"s\"", "ary" => "[1]", "obj" => "Other.new" }
# %s is filled with the condition that picks the object (true) or the other value
BOX = {
  "tern"   => ->(c) { "x = #{c} ? d : v" },
  "ifasgn" => ->(c) { "x = v\nx = d if #{c}" },
  "elem"   => ->(c) { "row = [d, v]\nx = row[#{c} ? 0 : 1]" },
  "hash"   => ->(c) { "h = { a: d, b: v }\nx = h[#{c} ? :a : :b]" },
  "meth"   => ->(c) { "x = pick(#{c}, d, v)" },
  "param"  => ->(c) { "x = nil\nhold(#{c} ? d : v) { |q| x = q }" },
}
USE = {
  "drop"   => "x.freeze\n  puts \"ok\"",
  "used"   => "y = x.freeze\n  p y.class",
  "frozen" => "p x.frozen?",
}
n = 0
DEF.each do |dk, dm|
  OTHER.each do |ok, ov|
    BOX.each do |bk, bx|
      { "isobj" => "ARGV.size < 5", "isother" => "ARGV.size > 5" }.each do |wk, cond|
        USE.each do |uk, use|
          src = "$n = 0\nclass Doc\n  #{dm}\nend\nclass Other\nend\n" \
                "def pick(f, a, b) = f ? a : b\ndef hold(q)\n  yield q\nend\n" \
                "d = Doc.new\nv = #{ov}\n#{bx.(cond)}\n" \
                "begin\n  #{use}\nrescue NoMethodError => e\n  p e.class\nend\np $n\n"
          File.write(File.join(out, "#{dk}__#{ok}__#{bk}__#{wk}__#{uk}.rb"), src); n += 1
        end
      end
    end
  end
end
puts n
