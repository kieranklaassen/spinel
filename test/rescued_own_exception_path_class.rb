# Two classes of one last name, one of them written as a path: both are kept
# under that name, so the name a boxed raised exception carries does not say
# which it is, and its class test is left as it was.
class Err < StandardError; end
module B; end
class B::Err < StandardError; end
e = begin; raise B::Err, "a"; rescue => x; x; end
p [e, 3].map { |v| v.is_a?(Err) }
