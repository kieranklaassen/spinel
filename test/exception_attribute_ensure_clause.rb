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
begin
  begin
    raise ParseError, "m"
  rescue ArgumentError
    p :no
  ensure
    held.size
  end
rescue ParseError => e
  p e.line
  e.ctx = [1, "c"]
  held << e
end
junk = []
2000.times { |i| junk << "x#{i}" }
p junk.size
p held[0].ctx
p held[0].message
