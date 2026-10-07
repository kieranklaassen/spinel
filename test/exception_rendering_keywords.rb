# full_message and detailed_message given keywords, on every kind of exception
# value. CRuby's full_message names the file and the line, so only what does
# not depend on them is shown.
class MyErr < StandardError; end
class Shown < StandardError
  def message = "shown"
end

e = MyErr.new("typed")
s = e.full_message(highlight: false)
p s.class, s.include?("typed")
p e.detailed_message(highlight: false)

begin
  raise MyErr, "rescued"
rescue MyErr => f
  p f.full_message(highlight: false, order: :top).include?("rescued")
  p f.detailed_message(highlight: false)
end

xs = [MyErr.new("boxed"), 3]
begin; raise IOError, "builtin"; rescue => g; xs << g; end
begin; raise MyErr, "raised"; rescue => g; xs << g; end
xs.each do |x|
  next if x == 3
  d = x.detailed_message(highlight: false)
  p x.full_message(highlight: false).include?(x.message), d.start_with?(x.message), d.end_with?("(#{x.class})")
end
p Shown.new("x").detailed_message(highlight: false)
