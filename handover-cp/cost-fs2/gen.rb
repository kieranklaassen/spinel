# gen.rb : cost programs for an Integer Array of eight searched for a boxed needle.
# One program a method x needle kind x shape; the needle is read from a mixed Array every turn
# (two needles of one kind, so the kind does not change and gcc cannot unswitch the loop on a constant).
N = 300_000
NEEDLES = {
  "int"    => ["5, 3", ""],                   # there
  "miss"   => ["11, 12", ""],                 # an Integer that is not there
  "str"    => ["\"x\", \"y\"", ""],
  "sym"    => [":a, :b", ""],
  "frac"   => ["2.5, 3.5", ""],               # a Float with a fraction: not there
  "whole"  => ["5.0, 3.0", ""],               # cured: there
  "nan"    => ["Float::NAN, Float::NAN", ""],
  "bigf"   => ["1.0e19, 2.0e19", ""],
  "rat52"  => ["Rational(5, 2), Rational(7, 2)", ""],
  "rat51"  => ["Rational(5, 1), Rational(3, 1)", ""],   # cured: there
  "ary"    => ["[8], [9]", ""],
  "hash"   => ["{ a: 1 }, { b: 2 }", ""],
  "obj"    => ["Pt.new, Pt.new", "class Pt\nend\n"],
  "bignum" => ["2**70, 2**71", ""],
  "true"   => ["true, false", ""],
}
METHODS = { "inc" => "include?", "idx" => "index", "ridx" => "rindex" }
METHODS.each do |mk, m|
  NEEDLES.each do |nk, (vals, defs)|
    next if mk == "ridx" && !%w[int str frac obj].include?(nk)
    { "c" => "c += 1 if xs.#{m}(n)", "k" => "r = xs.#{m}(n); c += 1 if r" }.each do |sk, body|
      File.write("#{sk}#{mk}_#{nk}.rb", <<~RB)
        #{defs}xs = [1, 2, 3, 4, 5, 6, 7, 8]
        row = [#{vals}, :pad]
        i = 0
        c = 0
        while i < #{N}
          n = row[i & 1]
          #{body}
          i += 1
        end
        p c
      RB
    end
  end
end
# an Array that can hold nil, searched for nil and for an Integer
{ "c" => "c += 1 if xs.METH(n)", "k" => "r = xs.METH(n); c += 1 if r" }.each do |sk, body|
  { "inc" => "include?", "idx" => "index" }.each do |mk, m|
    { "nil" => "nil, nil", "nint" => "5, 3" }.each do |nk, vals|
      File.write("#{sk}#{mk}_#{nk}.rb", <<~RB)
        xs = [1, 2, 3, 4, 5, 6, 7, 8].map { |e| e == 7 ? nil : e }
        row = [#{vals}, :pad]
        i = 0
        c = 0
        while i < #{N}
          n = row[i & 1]
          #{body.sub("METH", m)}
          i += 1
        end
        p c
      RB
    end
  end
end
