# An exception class with attributes and no initialize, leaving a begin that
# has an ensure through its rescue clauses: raised in a clause, or passing
# them unmatched. The ensure holds the exception as its object until it has
# run, and builds it as the class it is.
class Tagged < StandardError; attr_accessor :tag, :at; end
class ParseError < StandardError; attr_accessor :line, :ctx; end

kept = []
30.times do |i|
  begin
    begin
      raise "first"
    rescue => x
      raise Tagged, "m#{i}"
    ensure
      kept.size
    end
  rescue Tagged => e
    e.tag = "tag-#{i}"
    e.at = [i, "a#{i}"]
    kept << e
  end
end
bad = 0
kept.each_with_index do |e, i|
  bad += 1 unless e.tag == "tag-#{i}" && e.at == [i, "a#{i}"] && e.message == "m#{i}" && e.class == Tagged
end
p bad
p kept[3].cause.message

held = []
30.times do |i|
  begin
    begin
      raise ParseError, "p#{i}"
    rescue ArgumentError
      p :no
    ensure
      held.size
    end
  rescue ParseError => e
    e.line = i + 1
    e.ctx = [i, "c#{i}"]
    held << e
  end
end
junk = []
2000.times { |i| junk << "x#{i}" }
p junk.size
bad = 0
held.each_with_index do |e, i|
  bad += 1 unless e.line == i + 1 && e.ctx == [i, "c#{i}"] && e.message == "p#{i}"
end
p bad

# raised under a rescue, so with a cause, and leaving through an ensure that
# has no rescue clause: a begin's, a method's, a Mutex's, select!'s own
def through(i, c)
  raise Tagged, "t#{i}", cause: c
ensure
  i + 1
end
lock = Mutex.new
late = []
40.times do |i|
  c = ArgumentError.new("c#{i}")
  begin
    case i % 4
    when 0
      begin
        raise c
      rescue ArgumentError
        begin
          raise Tagged, "t#{i}"
        ensure
          late.size
        end
      end
    when 1 then through(i, c)
    when 2 then lock.synchronize { raise Tagged, "t#{i}", cause: c }
    else
      begin
        raise c
      rescue ArgumentError
        [1, 2, 3].select! { |v| raise Tagged, "t#{i}" if v == 2; true }
      end
    end
  rescue Tagged => e
    e.tag = "tag-#{i}"
    e.at = [i, "a#{i}"]
    late << e
  end
end
2000.times { |i| junk << "y#{i}" }
bad = 0
late.each_with_index do |e, i|
  bad += 1 unless e.tag == "tag-#{i}" && e.at == [i, "a#{i}"] && e.message == "t#{i}" && e.cause.message == "c#{i}"
end
p bad, late.size

# no cause waiting: the ensure makes the object and holds it for the raise
# after its body
plain = []
30.times do |i|
  begin
    begin
      raise Tagged, "n#{i}"
    ensure
      plain.size
    end
  rescue Tagged => e
    e.tag = "tag-#{i}"
    e.at = [i, "a#{i}"]
    plain << e
  end
end
2000.times { |i| junk << "z#{i}" }
bad = 0
plain.each_with_index do |e, i|
  bad += 1 unless e.tag == "tag-#{i}" && e.at == [i, "a#{i}"] && e.message == "n#{i}" && e.class == Tagged
end
p bad, plain.size

# raised in the else clause, which has a frame of its own under the ensure:
# under a rescue, so with a cause, and with none
other = []
40.times do |i|
  begin
    if i.odd?
      begin
        raise ArgumentError, "c#{i}"
      rescue ArgumentError
        begin
          i + 1
        rescue TypeError
          p :no
        else
          raise Tagged, "l#{i}"
        ensure
          other.size
        end
      end
    else
      begin
        i + 1
      rescue TypeError
        p :no
      else
        raise Tagged, "l#{i}"
      ensure
        other.size
      end
    end
  rescue Tagged => e
    e.tag = "tag-#{i}"
    e.at = [i, "a#{i}"]
    other << e
  end
end
2000.times { |i| junk << "l#{i}" }
bad = 0
other.each_with_index do |e, i|
  bad += 1 unless e.tag == "tag-#{i}" && e.at == [i, "a#{i}"] && e.message == "l#{i}" && e.class == Tagged
  bad += 1 if i.odd? && e.cause.message != "c#{i}"
end
p bad, other.size

# and the ensure's own body raises: the object is the cause of what the
# body raised
class Wide < StandardError; attr_accessor :a, :b, :c, :d, :e, :f; end
wide = []
300.times do |i|
  begin
    begin
      begin
        raise Wide, "w#{i}"
      ensure
        raise ArgumentError, "e#{i}"
      end
    rescue ArgumentError => x
      raise x.cause
    end
  rescue Wide => w
    w.a = "a#{i}"; w.b = [i, "b#{i}"]; w.c = "c#{i}"; w.d = [i]; w.e = "e#{i}"; w.f = i + 1
    wide << w
  end
end
bad = 0
wide.each_with_index do |w, i|
  bad += 1 unless w.a == "a#{i}" && w.b == [i, "b#{i}"] && w.c == "c#{i}" && w.d == [i] && w.e == "e#{i}" &&
                  w.f == i + 1 && w.message == "w#{i}" && w.class == Wide
end
p bad, wide.size

# a method's ensure, and stores enough to leave an object of the base size
class Dozen < StandardError
  attr_accessor :a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l
end
def dozen
  raise Dozen, "dozen"
ensure
  $kept = [ArgumentError.new("kept 0"), ArgumentError.new("kept 1")]
end
begin
  dozen
rescue Dozen => x
  x.a = -1; x.b = -2; x.c = -3; x.d = -4; x.e = -5; x.f = -6
  x.g = -7; x.h = -8; x.i = -9; x.j = -10; x.k = -11; x.l = -12
  p x.a + x.l, x.message
end
p $kept.map { |o| [o.class, o.message] }

# through an inner begin's ensure to the clause of an outer begin that binds
# it, the outer begin with an ensure of its own
begin
  begin
    raise Dozen, "inner"
  ensure
    $kept = [ArgumentError.new("kept 2"), ArgumentError.new("kept 3")]
  end
rescue Dozen => y
  y.a = 1; y.b = 2; y.c = 3; y.d = 4; y.e = 5; y.f = 6
  y.g = 7; y.h = 8; y.i = 9; y.j = 10; y.k = 11; y.l = 12
  p y.a + y.l, y.message
ensure
  p $kept.map { |o| [o.class, o.message] }
end
