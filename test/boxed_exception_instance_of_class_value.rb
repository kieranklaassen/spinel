# A boxed exception asked instance_of? with the class in a variable or
# written as a path: it carries its class by name and has no class id.
module App
  class Missing < StandardError; end
end
class MyErr < StandardError; end
class Deeper < MyErr; end

kept = []
begin; raise MyErr, "a"; rescue StandardError => e; kept << e; end
begin; raise Deeper, "b"; rescue StandardError => e; kept << e; end
begin; raise App::Missing, "c"; rescue StandardError => e; kept << e; end
begin; raise ArgumentError, "d"; rescue StandardError => e; kept << e; end
begin; [1].fetch(9); rescue IndexError => e; kept << e; end
kept << MyErr.new("never raised") << 3 << nil

k = MyErr
p kept.map { |x| x.instance_of?(k) }
k = ArgumentError
p kept.map { |x| x.instance_of?(k) }
k = StandardError
p kept.map { |x| x.instance_of?(k) }
k = Object
p kept.map { |x| x.instance_of?(k) }
p kept.map { |x| x.instance_of?(App::Missing) }

def exact?(x, k) = x.instance_of?(k)
p kept.map { |x| exact?(x, Deeper) }
[IndexError, Integer, NilClass].each { |c| p kept.count { |x| x.instance_of?(c) } }
