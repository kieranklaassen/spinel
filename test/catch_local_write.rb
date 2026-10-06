# A local written in a catch block before the throw keeps the write
def scan(words, stop)
  seen = 0
  last = :none
  ratio = 0.5
  found = false
  catch(:done) do
    words.each do |w|
      seen += 1
      last = w
      ratio = seen / 4.0
      if w == stop
        found = true
        throw :done
      end
    end
  end
  [seen, last, ratio, found]
end
p scan([:a, :b, :c, :d], :c)
p scan([:a, :b], :z)

# the throw comes from a method the block calls
def leave(tag, value) = throw(tag, value)
def deep
  step = 0
  got = catch(:out) do
    step = 1
    leave(:out, 7) if step == 1
    step = 2
    0
  end
  [got, step]
end
p deep

# a catch in a catch, and a write between them
def nested
  a = 1
  b = 1
  catch(:outer) do
    a = 2
    catch(:inner) do
      b = 2
      throw :inner
    end
    a = 3
    b += 10
    throw :outer
  end
  [a, b]
end
p nested

# a parameter, and the catch as a value
def doubled(k)
  r = catch(:t) do
    k *= 2
    throw :t, k + 1 if k > 4
    0
  end
  [r, k]
end
p doubled(4), doubled(1)

# at the top level
count = 0
catch(:top) do
  count += 5
  throw :top
end
p count

# the block of a method that yields inside a catch
def caught
  catch(:out) do
    yield
    :done
  end
end

def spliced
  n = 3
  caught { n = 5; throw :out }
  n
end
p spliced
