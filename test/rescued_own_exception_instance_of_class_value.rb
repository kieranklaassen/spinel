# instance_of? with the class in a variable, asked of a boxed raised
# exception of a class of the program's own: it carries its class by name.
class MyErr < StandardError; end
class Deeper < MyErr; end

kept = []
begin; raise MyErr, "a"; rescue StandardError => e; kept << e; end
begin; raise Deeper, "b"; rescue StandardError => e; kept << e; end
begin; raise ArgumentError, "c"; rescue StandardError => e; kept << e; end
kept << MyErr.new("never raised") << 3 << nil

k = MyErr
p kept.map { |x| x.instance_of?(k) }
k = Deeper
p kept.map { |x| x.instance_of?(k) }
k = StandardError
p kept.map { |x| x.instance_of?(k) }
k = Integer
p kept.map { |x| x.instance_of?(k) }

def exact?(x, k) = x.instance_of?(k)
p kept.map { |x| exact?(x, Deeper) }
[MyErr, Deeper, NilClass].each { |c| p kept.count { |x| x.instance_of?(c) } }
