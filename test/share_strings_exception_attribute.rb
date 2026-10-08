# An exception class with attributes and no initialize, raised with a String
# the program appends to. With --share-strings the raise itself builds the
# exception, holding that String: at the class's own size and with the
# class's scan, so what the rescue stores in it stays.
class Tagged < StandardError; attr_accessor :tag, :at; end

kept = []
60.times do |i|
  s = +"m"
  s << i.to_s
  begin
    raise Tagged, s
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

# caught by an arm that names no class of the program, and stored after
class Noted < StandardError
  attr_reader :note, :at
  def note!(n, a)
    @note = n; @at = a
  end
end
seen = []
40.times do |i|
  begin
    s = +"n"
    s << i.to_s
    raise Noted, s
  rescue StandardError => e
    seen << e
  end
end
seen.each_with_index { |v, i| v.note!("late-#{i}", [i, "z#{i}"]) if v.respond_to?(:note!) }
junk = []
2000.times { |i| junk << "x#{i}" }
bad = 0
seen.each_with_index do |v, i|
  next unless v.respond_to?(:note)
  bad += 1 unless v.note == "late-#{i}" && v.at == [i, "z#{i}"] && v.message == "n#{i}"
end
p bad, junk.size
