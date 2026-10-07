class Doc
  def freeze = :sealed
end
d = Doc.new
row = [d, 5, "s", nil, :k, 2.5]
row.each do |x|
  begin
    x.then { |q| q&.freeze }
    puts "ok"
  rescue => e
    p e.class
  end
end
