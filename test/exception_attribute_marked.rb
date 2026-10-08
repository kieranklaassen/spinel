# An attribute stored on an exception of a class with no initialize is
# marked with the exception: 300 kept, each with a String of its own.
class Tagged < StandardError; attr_accessor :tag; end

kept = []
300.times do |i|
  begin
    raise Tagged, "m#{i}"
  rescue Tagged => e
    e.tag = "tag-#{i}"
    kept << e
  end
end
bad = 0
kept.each_with_index { |e, i| bad += 1 unless e.tag == "tag-#{i}" && e.message == "m#{i}" }
p bad

made = (0...300).map { |i| t = Tagged.new("n#{i}"); t.tag = [i, "t#{i}"]; t }
p made.count { |t| t.tag == [made.index(t), "t#{made.index(t)}"] }
