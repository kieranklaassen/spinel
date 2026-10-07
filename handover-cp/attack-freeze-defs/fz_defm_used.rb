class Doc
  define_method(:freeze) { :sealed }
end
d = Doc.new
row = [d, 5, "s", nil, :k, 2.5]
row.each do |x|
  begin
    r = x.freeze
    p r.class
  rescue => e
    p e.class
  end
end
