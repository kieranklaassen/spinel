# An exception class with attributes and no initialize of its own: an
# attribute nothing has set reads nil, and one that is set lives as long as
# the exception does.
class ParseError < StandardError; attr_accessor :line, :ctx, :note; end
class DeepError < ParseError; attr_accessor :more; end

e = ParseError.new("made")
p e.line, e.ctx, e.note, e.note.nil?
p(e.note || "none")
e.note ||= "set"
p e.note
e.line = 5
p e.line, ParseError.new("other").line

d = DeepError.new("deep")
p [d.line, d.note, d.more].compact.size

begin
  raise ParseError, "raised"
rescue ParseError => r
  p r.line, r.ctx, r.message
end
begin
  raise DeepError
rescue DeepError => r
  p r.more, r.message
end

# set where it is rescued, raised again, read after other work
def rows(n) = (0...n).map { |i| [i, "r#{i}"] }
def check(n)
  raise ParseError, "too many" if n > 2
  n
rescue ParseError => x
  x.ctx = rows(n)
  x.line = n
  raise
end
junk = []
begin
  check(3)
rescue ParseError => x
  2000.times { |i| junk << rows(2) if i % 7 == 0; rows(3) }
  p x.ctx, x.line, x.message
end

# kept as a plain value by an arm that names no class of the program
kept = []
begin
  raise ParseError, "kept"
rescue StandardError => s
  kept << s
end
kept << 3
kept.each { |v| p v.ctx if v.respond_to?(:ctx) }

# and written through that value by a method of the class
class Marked < StandardError
  def mark!(a, b, c)
    @a = a; @b = b; @c = c
  end
  def marks = [@a, @b, @c]
end
5.times { |i| begin; raise Marked, "a#{i}"; rescue StandardError => s; kept << s; end }
kept.each { |v| v.mark!("s1" + v.message, "s2" + v.message, "s3" + v.message) if v.respond_to?(:mark!) }
n = 0
20_000.times { |i| n += "x#{i}".size }
p n
kept.each { |v| p v.marks if v.respond_to?(:marks) }
