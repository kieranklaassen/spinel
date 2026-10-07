class Doc
  def frozen? = 7
end
d = Doc.new
row = [d, 5, "s", nil, :k, 2.5]
row.each do |x|
  begin
    x.frozen?
    puts "ok"
  rescue => e
    p e.class
  end
end
