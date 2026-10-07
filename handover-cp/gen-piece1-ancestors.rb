# an ancestor of Integer (or Integer itself, reopened) defines one of the
# names; the receiver is boxed and holds an Integer, a String, a Float, a
# Bignum, nil or a Symbol. One program a case.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
NAMES = {
  "odd"  => ["def odd? = :theirs",  ->(r) { "#{r}.odd?" }],
  "even" => ["def even? = :theirs", ->(r) { "#{r}.even?" }],
  "oddf"  => ["def odd? = false",    ->(r) { "#{r}.odd?" }],
  "oddt"  => ["def odd? = true",     ->(r) { "#{r}.odd?" }],
  "evenf" => ["def even? = false",   ->(r) { "#{r}.even?" }],
  "event" => ["def even? = true",    ->(r) { "#{r}.even?" }],
  "oddi"  => ["def odd? = to_i.odd?", ->(r) { "#{r}.odd?" }],
  "inv"  => ["def ~ = :theirs",     ->(r) { "~#{r}" }],
  "chr"  => ["def chr(e) = :theirs", ->(r) { "#{r}.chr(Encoding::UTF_8)" }],
}
ANC = {
  "object"  => ->(d) { "class Object\n  #{d}\nend\n" },
  "kernel"  => ->(d) { "module Kernel\n  #{d}\nend\n" },
  "basic"   => ->(d) { "class BasicObject\n  #{d}\nend\n" },
  "numeric" => ->(d) { "class Numeric\n  #{d}\nend\n" },
  "compar"  => ->(d) { "module Comparable\n  #{d}\nend\n" },
  "modobj"  => ->(d) { "module M\n  #{d}\nend\nclass Object\n  include M\nend\n" },
  "modnum"  => ->(d) { "module M\n  #{d}\nend\nclass Numeric\n  include M\nend\n" },
  "integer" => ->(d) { "class Integer\n  #{d}\nend\n" },
  "modint"  => ->(d) { "module M\n  #{d}\nend\nclass Integer\n  include M\nend\n" },
  "prepint" => ->(d) { "module M\n  #{d}\nend\nclass Integer\n  prepend M\nend\n" },
  # not an ancestor of Integer: the controls
  "string"  => ->(d) { "class String\n  #{d}\nend\n" },
  "float"   => ->(d) { "class Float\n  #{d}\nend\n" },
  "own"     => ->(d) { "class K\n  #{d}\nend\nK.new\n" },
  "toplevel" => ->(d) { "#{d}\n" },
  "nilcls"  => ->(d) { "class NilClass\n  #{d}\nend\n" },
  "symbol"  => ->(d) { "class Symbol\n  #{d}\nend\n" },
  # the name comes to an ancestor another way
  "alias"   => ->(d) { "class Object\n  #{d.sub(/def (\S+?)(\(e\))? =/) { "def theirs_m#{$2} =" }}\n  alias #{d[/def (\S+?)(\(e\))? =/, 1]} theirs_m\nend\n" },
  "subnum"  => ->(d) { "class Money < Numeric\n  #{d}\nend\nMoney.new\n" },
  "defmeth" => ->(d) { "class Object\n  #{dm(d)}\nend\n" },
  "defmint" => ->(d) { "class Integer\n  #{dm(d)}\nend\n" },
  # a prepend made after the first call: LATE is put behind the first print
  "lateprep" => ->(d) { "module M\n  #{d}\nend\n" },
  "lateobj"  => ->(d) { "module M\n  #{d}\nend\n" },
}
LATE = { "lateprep" => "class Integer\n  prepend M\nend\n", "lateobj" => "class Object\n  include M\nend\n" }
# `def NAME(args) = BODY` as define_method(:NAME) { |args| BODY }
def dm(d)
  m = d.match(/\Adef (\S+?)(?:\((\w+)\))? = (.*)\z/)
  "define_method(:#{m[1]}) { #{m[2] ? "|#{m[2]}| " : ""}#{m[3]} }"
end
VALS = { "int" => "7", "str" => '"s"', "flt" => "2.5", "big" => "(2**70 + 1)", "nil" => "nil", "sym" => ":a" }
def other(lit) = lit.start_with?('"') ? ":q" : '"q"'
n = 0
ANC.each do |ak, anc|
  NAMES.each do |nk, (defn, call)|
    VALS.each do |vk, lit|
      body = "v = [#{other(lit)}, #{lit}][1]\nx = begin\n  #{call.("v")}\nrescue NoMethodError, ArgumentError, RangeError, TypeError => e\n  e.class\nend\np x\n"
      if LATE[ak]
        again = "y = begin\n  #{call.("v")}\nrescue NoMethodError, ArgumentError, RangeError, TypeError => e\n  e.class\nend\np y\n"
        body = body + LATE[ak] + again
      end
      File.write(File.join(out, "#{ak}__#{nk}__#{vk}.rb"), "# spinel: int64\n" + anc.(defn) + body)
      n += 1
    end
  end
end
puts n
