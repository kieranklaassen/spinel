# An exception passing a rescue that does not match it keeps the frames
# below that rescue when the begin has an ensure too. The ensure runs first,
# and the raise after its body took a new snapshot there, as the
# pass-through of test/backtrace/pass_through_rescue.rb once did.
#
# An ensure body that raised and rescued an exception of its own has taken
# a snapshot for that one: the frames are then the begin's own, never the
# inner raise's.
#
# Driven by `make backtrace-test` (a --debug build).
class Chain
  def inner(x)
    [1] & x
  end

  def mid(x)
    inner(x)
  end

  def outer(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    @seen = true
  end

  def quiet
    Integer("z")
  rescue ArgumentError
    nil
  end

  def noisy(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    quiet
  end

  def top(x)
    outer(x)
  rescue => e
    puts e.class
    e.backtrace.each { |l| puts "  #{l}" }
  end

  def top_noisy(x)
    noisy(x)
  rescue => e
    puts e.class
    e.backtrace.each { |l| puts "  noisy #{l}" }
  end
end

Chain.new.top(Object.new)
Chain.new.top_noisy(Object.new)
