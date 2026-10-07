# A method that matches a Regexp in a `when` arm, or through any?, all?,
# none? or one?, keeps its caller's $~ as CRuby does: the match is the
# method's own. The caller's registers were overwritten, by a miss with nil.
def kind(v)
  case v
  when /a(b)?/ then :ab
  when /x/ then :x
  else :other
  end
end
def group_of(v)
  case v
  when /a(b)?/ then $1
  else $~
  end
end
def any_b(a) = a.any?(/b/)
def all_b(a) = a.all?(/b/)
def none_b(a) = a.none?(/b/)
def one_b(a) = a.one?(/b/)
def early(v)
  return :none if v.empty?
  case v when /z/ then :z else :no end
end
def in_block(vs) = vs.map { |v| case v when /a/ then 1 else 0 end }
class Rule
  def initialize = @n = 0
  def take(v)
    case v
    when /\d+/ then @n += $~[0].to_i
    end
    @n
  end
end

p $~
p kind("cab"), $~
"q1" =~ /q(\d)/
p kind("cab"), $~ && $~[0], $1
p kind("xy"), $~ && $~[0]
p kind("zz"), $~ && $~[0]
p group_of("ab"), group_of("zz"), $~ && $~[0]
a = ["xb", "q", "b"]
p any_b(a), $~ && $~[0]
p all_b(a), $~ && $~[0]
p none_b(a), $~ && $~[0]
p one_b(a), $~ && $~[0]
p any_b(["z"]), all_b([]), $~ && $~[0]
p early(""), early("z"), early("y"), $~ && $~[0]
p in_block(["a", "b"]), $~ && $~[0]
rule = Rule.new
p rule.take("a12"), rule.take("b"), rule.take("7"), $1

# the top level and a block are the frame they stand in
case "zab" when /a(b)/ then p $1 end
p $~[0]
[1].each { ["k"].any?(/k/) }
p $~ && $~[0]
