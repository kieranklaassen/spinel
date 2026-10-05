# `split` builds its Array new only while it is String's own: the program's
# answers an Array it keeps.
class String
  def split(x) = $kept
end
$kept = [+"a ", +"b"]
"a ,b".split(",").first.strip!
p $kept
