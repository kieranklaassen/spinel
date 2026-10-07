# An exception passing a rescue that does not match it keeps the frames
# below that rescue when the begin has an ensure too. The ensure runs first,
# and the raise after its body took a new snapshot there, as the
# pass-through of test/backtrace/pass_through_rescue.rb once did.
#
# An ensure body that raised and rescued an exception of its own took the
# one buffer for that one: the frames are saved before the body and put back,
# so the exception passing still shows where it was raised. Four such bodies
# follow the quiet one: a method that raises and rescues, a Fiber whose block
# does, a raise rescued and raised again, and a begin whose own clause does
# not match under a rescue modifier.
#
# Driven by `make backtrace-test` (a --debug build).
class Chain
  def inner(x)
    [1] & x
  end

  def mid(x)
    inner(x)
  end

  def quiet
    Integer("z")
  rescue ArgumentError
    nil
  end

  def outer(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    @seen = true
  end

  def noisy(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    quiet
  end

  def fibered(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    Fiber.new { quiet }.resume
  end

  def reraised(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    begin
      begin
        Integer("z")
      rescue ArgumentError
        raise
      end
    rescue ArgumentError
      nil
    end
  end

  def unmatched(x)
    mid(x)
  rescue ArgumentError
    nil
  ensure
    (begin; Integer("z"); rescue IOError; nil; end) rescue nil
  end

  def top(tag, x)
    case tag
    when "outer" then outer(x)
    when "noisy" then noisy(x)
    when "fibered" then fibered(x)
    when "reraised" then reraised(x)
    else unmatched(x)
    end
  rescue => e
    puts tag + " " + e.class.to_s
    e.backtrace.each { |l| puts "  #{tag} #{l}" }
  end
end

["outer", "noisy", "fibered", "reraised", "unmatched"].each { |tag| Chain.new.top(tag, Object.new) }
