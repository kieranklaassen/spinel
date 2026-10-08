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
