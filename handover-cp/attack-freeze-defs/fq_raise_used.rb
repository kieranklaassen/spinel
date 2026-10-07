class Doc
  def frozen? = raise("no")
end
d = Doc.new
row = [d, 5, "s", nil, :k, 2.5]
row.each do |x|
  begin
    r = x.frozen?
    p r.class
  rescue => e
    p e.class
  end
end
