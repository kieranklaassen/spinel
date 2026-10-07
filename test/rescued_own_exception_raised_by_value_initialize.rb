# A class with ivars and an initialize, raised through a variable: the
# runtime builds that exception by its name with no constructor, so its
# class test is left as it was and the reader it guards is not reached.
class Coded < StandardError
  def initialize(code = 3)
    @code = code
    super("code #{code}")
  end
  def code = @code
end
kept = []
[Coded, KeyError].each { |k| begin; raise k, "a"; rescue StandardError => e; kept << e; end }
kept << Coded.new(4) << 3
kept.each { |v| v.code if v.is_a?(Coded) }
puts "done"
