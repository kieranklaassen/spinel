# Layer-1 extension fixture (ext-design.md): a plain-Ruby kernel whose
# entries are exported by --ext-entry and driven by a C host (host.c).
module ExtKernel
  def self.triple(n)
    n * 3
  end

  def self.shout(s)
    s.upcase + "!"
  end

  def self.total(arr)
    t = 0
    i = 0
    while i < arr.length
      t += arr[i]
      i += 1
    end
    t
  end

  # Two array parameters: the host converts the second while the first is
  # already built, so the first must stay rooted across that conversion.
  def self.pair_sum(a, b)
    raise ArgumentError, "needs a non-empty first array" if a.empty?
    t = 0
    a.each { |s| t += s.length }
    b.each { |s| t += s.length }
    t
  end

  def self.must_pos(n)
    raise ArgumentError, "needs a positive number" if n <= 0
    n
  end

  # Raises its argument as the message: a C host reads a message as a C
  # string, whatever bytes it holds.
  def self.refuse(s)
    raise ArgumentError, s if s.bytesize > 0
    s
  end

  # The same, raised as an exception object.
  def self.refuse_object(s)
    raise ArgumentError.new(s) if s.bytesize > 0
    s
  end

  # And rescued, then raised again.
  def self.refuse_again(s)
    begin
      raise ArgumentError, s if s.bytesize > 0
    rescue ArgumentError
      raise
    end
    s
  end

  def self.pause_total(arr, delay)
    sleep(delay)
    total(arr)
  end
end

TOPLEVEL_NOTE = "toplevel ran"

if __FILE__ == $0
  p ExtKernel.triple(5)
  p ExtKernel.shout("hey")
  p ExtKernel.total([1, 2, 3])
  p ExtKernel.must_pos(9)
  p ExtKernel.pair_sum(["ab", "c"], ["def"])
  p ExtKernel.pause_total([1, 2, 3], 0.001)
  p ExtKernel.refuse("")
  p ExtKernel.refuse_object("")
  p ExtKernel.refuse_again("")
end
