# An exception class with attributes and no initialize of its own: what is
# stored in an attribute lives as long as the exception does, whichever arm
# caught it.
class ParseError < StandardError; attr_accessor :line, :ctx, :note; end
class DeepError < ParseError; attr_accessor :more; end

e = ParseError.new("made")
e.line = 5
e.note = "set"
d = DeepError.new("deep")
d.more = [1, "m"]
d.line = 7
p e.line, e.note, e.message, d.more, d.line, d.message

# set where it is rescued, raised again, read after other work
class Work
  def self.rows(n) = (0...n).map { |i| [i, "r#{i}"] }
  def self.check(n)
    raise ParseError, "too many" if n > 2
    n
  rescue ParseError => x
    x.ctx = rows(n)
    x.line = n
    raise
  end
end
junk = []
begin
  Work.check(3)
rescue ParseError => x
  2000.times { |i| junk << Work.rows(2) if i % 7 == 0; Work.rows(3) }
  p x.ctx, x.line, x.message
end

# kept as a plain value by an arm that names no class of the program, and
# written through that value by a method of the class
class Marked < StandardError
  def mark!(a, b, c)
    @a = a; @b = b; @c = c
  end
  def marks = [@a, @b, @c]
end
kept = []
begin
  raise ParseError, "kept"
rescue StandardError => s
  kept << s
end
kept << 3
5.times { |i| begin; raise Marked, "a#{i}"; rescue StandardError => s; kept << s; end }
kept.each { |v| v.mark!("s1" + v.message, "s2" + v.message, "s3" + v.message) if v.respond_to?(:mark!) }
n = 0
20_000.times { |i| n += "x#{i}".size }
p n
kept.each { |v| p v.marks if v.respond_to?(:marks) }

# a message given as a literal is that frozen literal still, where an arm
# that names no class of the program catches the exception
begin
  raise ParseError, "lit"
rescue StandardError => g
  p g.message.frozen?
  begin
    g.message << "x"
  rescue FrozenError => fe
    p fe.class
  end
  p g.message
end
made = ParseError.new("lit2")
p made.message.frozen?
begin
  raise made
rescue StandardError => g
  p g.message.frozen?
end
[-> { raise ParseError, "lit" }, -> { raise DeepError, "lit" }, -> { raise ParseError, "" },
 -> { raise ParseError, "x#{1}" }, -> { raise ParseError }].each do |f|
  begin
    f.call
  rescue StandardError => g
    p [g.class, g.message, g.message.frozen?]
    begin
      g.message << "!"
    rescue FrozenError => fe
      p fe.class
    end
  end
end
begin
  raise ParseError, "lit"
rescue => g
  p g.message.frozen?
end
begin
  raise DeepError, "lit"
rescue Exception => g
  p g.message.frozen?
end
p kept.first.message, kept.first.message.frozen?
