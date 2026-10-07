module Tagged; end
class MyErr < StandardError
  include Tagged
end
xs = [1, "s"]
begin
  raise MyErr, "x"
rescue => e
  xs << e
end
xs.each do |x|
  p x.is_a?(Tagged)
  case x
  when Tagged then puts "tagged"
  else puts "plain"
  end
end
