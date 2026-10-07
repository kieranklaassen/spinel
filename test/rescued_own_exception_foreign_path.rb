# A path that is no class of the program and ends in the name of one: what
# `raise IO::TimeoutError` raises is not the program's own TimeoutError, and
# the class test of a boxed exception is left as it was.
class TimeoutError < StandardError; end
class ConverterNotFoundError < StandardError; end

kept = []
begin; raise IO::TimeoutError, "late"; rescue Exception => e; kept << e; end
begin; raise Encoding::ConverterNotFoundError, "none"; rescue Exception => e; kept << e; end
kept << 3
p kept.map { |x| x.instance_of?(TimeoutError) }
p kept.map { |x| x.is_a?(ConverterNotFoundError) }
kept.each do |x|
  case x
  when TimeoutError, ConverterNotFoundError then puts "own"
  when Exception then puts "other: #{x.message}"
  else puts "value"
  end
end
