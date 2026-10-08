# An arm typed to a parent class builds the subclass that was raised by its
# name, at the subclass's own size, where the parent is such a class too
# (attributes and no initialize): what is stored in the attributes the
# subclass adds stays, beside what the arm set through the parent's writer.
class Error < StandardError; attr_accessor :code; end
class ParseError < Error; attr_accessor :line, :ctx; end
class DeepError < ParseError; attr_accessor :a, :b, :c, :d; end

kept = []
30.times do |i|
  begin
    begin
      raise DeepError, "deep#{i}"
    rescue Error => e
      e.code = i
      raise
    end
  rescue DeepError => d
    d.line = i + 1
    d.ctx = [i, "c#{i}"]
    d.a = "a#{i}"
    d.d = [i]
    kept << d
  end
end
junk = []
2000.times { |i| junk << "x#{i}" }
bad = 0
kept.each_with_index do |v, i|
  bad += 1 unless v.class == DeepError && v.message == "deep#{i}" && v.code == i && v.line == i + 1 &&
                  v.ctx == [i, "c#{i}"] && v.a == "a#{i}" && v.d == [i]
end
p bad, junk.size

# the middle class, through the middle arm; and the parent itself
one = []
begin
  begin
    raise DeepError
  rescue ParseError => e
    e.line = 3
    raise
  end
rescue StandardError => e2
  one << e2
end
begin
  begin
    raise Error, "own"
  rescue Error => e
    e.code = 1
    raise
  end
rescue StandardError => e2
  one << e2
end
p one[0].class, one[0].message, one[0].line
p one[1].class, one[1].message, one[1].code
