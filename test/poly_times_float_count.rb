# A boxed String or Array times a Float. The count of String#* and Array#*
# is an Integer argument, and CRuby truncates a Float there: "ab" * 2.5 is
# "abab". Through a boxed receiver both raised TypeError, "no implicit
# conversion of Float into String", where the typed String already answered.

def t(s)
  r = yield
  puts "#{s}: #{r.inspect}"
rescue StandardError => e
  puts "#{s}: #{e.class}: #{e.message}"
end

class Shelf
  attr_accessor :v
  def initialize(v) = @v = v
  def twice(n)
    @v *= n
    @v
  end
end

row = ["ab", [1, 2], ["a", "b"], [1.5, nil, "x"], "", []]
cnt = [2.5, 3.999, 0.5, -0.5, -1.5, 0.0, 2]
s = row[0]
a = row[1]

# a String: the Float is truncated toward zero
t("str * 2.5") { s * cnt[0] }
t("str * 3.999") { s * cnt[1] }
t("str * 0.5") { s * cnt[2] }
t("str * -0.5") { s * cnt[3] }
t("str * 0.0") { s * cnt[5] }
t("empty * 2.5") { row[4] * cnt[0] }
t("str * 2") { s * cnt[6] }

# an Array of each kind
t("ints * 2.5") { a * cnt[0] }
t("strs * 2.5") { row[2] * cnt[0] }
t("mixed * 2.5") { row[3] * cnt[0] }
t("none * 2.5") { row[5] * cnt[0] }
t("ints * 0.5") { a * cnt[2] }
t("ints * -0.5") { a * cnt[3] }
t("ints * 2") { a * cnt[6] }

# a Float the compiler knows, and one written out
f = ARGV.size + 2.5
t("str * typed") { s * f }
t("ints * typed") { a * f }
t("str * literal") { s * 2.5 }
t("ints * literal") { a * 1.5 }

# a count that is no Integer at all
t("str * -1.5") { s * cnt[4] }
t("ints * -1.5") { a * cnt[4] }
bad = [Float::NAN, Float::INFINITY, -Float::INFINITY, 1.0e30, :sym]
t("str * NaN") { s * bad[0] }
t("str * Inf") { s * bad[1] }
t("str * -Inf") { s * bad[2] }
t("str * 1e30") { s * bad[3] }
t("ints * NaN") { a * bad[0] }
t("ints * 1e30") { a * bad[3] }

# the other ways to the same operator
t("local *=") { x = s; x *= cnt[0]; x }
sh = Shelf.new(s)
t("attribute *=") { sh.v *= cnt[0]; sh.v }
t("ivar *=") { Shelf.new(a).twice(cnt[0]) }
cell = [s, 7]
t("element *=") { cell[0] *= cnt[0]; cell[0] }
t("send") { s.send(:*, cnt[0]) }
t("public_send") { a.public_send(:*, cnt[0]) }
t("inject") { [s, cnt[0]].inject(:*) }
t("in a block") { cnt.first(2).map { |n| s * n } }

# numbers answer as they did
num = [3, 1.5]
t("int * float") { num[0] * num[1] }
t("float * int") { num[1] * num[0] }
