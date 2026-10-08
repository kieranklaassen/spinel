# An exception class with attributes and no initialize, raised with a String
# the program appends to. With --share-strings the raise itself builds the
# exception, holding that String: at the class's own size and with the
# class's scan, its attributes nil until set.
class Tagged < StandardError; attr_accessor :tag, :at; end

kept = []
60.times do |i|
  s = +"m"
  s << i.to_s
  begin
    raise Tagged, s
  rescue Tagged => e
    kept << e
    e.tag = "tag-#{i}" if e.tag.nil?
    e.at = [i, "a#{i}"] if e.at.nil?
  end
end
bad = 0
kept.each_with_index do |e, i|
  bad += 1 unless e.tag == "tag-#{i}" && e.at == [i, "a#{i}"] && e.message == "m#{i}" && e.class == Tagged
end
p bad

# caught by an arm that names no class of the program
seen = []
begin
  s = +"n"
  s << "1"
  raise Tagged, s
rescue StandardError => e
  seen << e
end
seen.each { |v| p v.tag, v.at, v.message if v.respond_to?(:tag) }
