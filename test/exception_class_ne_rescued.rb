# != between a value typed as the program's exception class and a rescued
# exception: the == of the two, turned round.
class MyErr < StandardError; end
k = MyErr.new("n")
o = MyErr.new("other")
begin
  raise k
rescue => e
  p k != e, o != e, !(k == e), !(o == e)
  puts "differs" if o != e
end
begin
  raise MyErr, "a"
rescue MyErr => f
  p f != f
  x = f
  p x != f, f != x
end
