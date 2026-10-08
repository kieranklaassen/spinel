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
