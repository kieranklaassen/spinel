class Doc
  attr_accessor :freeze
  def initialize = @freeze = 3
end
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
