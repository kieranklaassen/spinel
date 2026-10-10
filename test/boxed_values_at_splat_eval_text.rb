# class_eval given a text defines what no node shows. A program that names
# it keeps the splat in values_at on a boxed receiver as it was read.

begin
  Integer.send(:class_eval, "def to_a = []")
rescue NoMethodError
end
a = [[10, 20, 30], nil][ARGV.size]
i = ARGV.size + 1
p a.values_at(0, *i)
