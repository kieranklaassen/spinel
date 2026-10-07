class Doc
  def freeze = self
end
class Two
  def freeze = 7
end
Two.new
d = Doc.new
row = [d, 5, "s", nil, :k, 2.5]
row.each do |x|
  begin
    x.freeze
    puts "ok"
  rescue => e
    p e.class
  end
end
