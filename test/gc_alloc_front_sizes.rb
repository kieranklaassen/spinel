# A constructor allocates through an inline copy of the allocator's fast path,
# which works the size class out from the size of the object instead of
# reading it from the slab's table. Classes from no fields up to 25, the last
# the inline path takes (256 bytes with the header), and two past it that go
# the ordinary way: every field a constructor did not set reads nil, and every
# object keeps its own values through collections.

class C0
  def initialize(v)
  end

  def blank?
    true
  end

  def sum
    0
  end
end

class C1
  attr_reader :f0
  def initialize(v)
    @f0 = v
  end

  def blank?
    true
  end

  def sum
    @f0
  end
end

class C2
  attr_reader :f0, :f1
  def initialize(v)
    @f0 = v
    @f1 = v + 1
  end

  def blank?
    true
  end

  def sum
    @f0 + @f1
  end
end

class C3
  attr_reader :f0, :f1, :f2
  def initialize(v)
    @f0 = v
    @f2 = v + 1
  end

  def blank?
    @f1.nil?
  end

  def sum
    @f0 + @f2
  end
end

class C8
  attr_reader :f0, :f1, :f2, :f3, :f4, :f5, :f6, :f7
  def initialize(v)
    @f0 = v
    @f7 = v + 1
  end

  def blank?
    @f1.nil? && @f2.nil? && @f3.nil? && @f4.nil? && @f5.nil? && @f6.nil?
  end

  def sum
    @f0 + @f7
  end
end

class C16
  attr_reader :f0, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12, :f13, :f14, :f15
  def initialize(v)
    @f0 = v
    @f15 = v + 1
  end

  def blank?
    @f1.nil? && @f2.nil? && @f3.nil? && @f4.nil? && @f5.nil? && @f6.nil? &&
      @f7.nil? && @f8.nil? && @f9.nil? && @f10.nil? && @f11.nil? && @f12.nil? &&
      @f13.nil? && @f14.nil?
  end

  def sum
    @f0 + @f15
  end
end

class C24
  attr_reader :f0, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :f19, :f20, :f21, :f22, :f23
  def initialize(v)
    @f0 = v
    @f23 = v + 1
  end

  def blank?
    @f1.nil? && @f2.nil? && @f3.nil? && @f4.nil? && @f5.nil? && @f6.nil? &&
      @f7.nil? && @f8.nil? && @f9.nil? && @f10.nil? && @f11.nil? && @f12.nil? &&
      @f13.nil? && @f14.nil? && @f15.nil? && @f16.nil? && @f17.nil? && @f18.nil? &&
      @f19.nil? && @f20.nil? && @f21.nil? && @f22.nil?
  end

  def sum
    @f0 + @f23
  end
end

class C25
  attr_reader :f0, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :f19, :f20, :f21, :f22, :f23, :f24
  def initialize(v)
    @f0 = v
    @f24 = v + 1
  end

  def blank?
    @f1.nil? && @f2.nil? && @f3.nil? && @f4.nil? && @f5.nil? && @f6.nil? &&
      @f7.nil? && @f8.nil? && @f9.nil? && @f10.nil? && @f11.nil? && @f12.nil? &&
      @f13.nil? && @f14.nil? && @f15.nil? && @f16.nil? && @f17.nil? && @f18.nil? &&
      @f19.nil? && @f20.nil? && @f21.nil? && @f22.nil? && @f23.nil?
  end

  def sum
    @f0 + @f24
  end
end

class C26
  attr_reader :f0, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :f19, :f20, :f21, :f22, :f23, :f24, :f25
  def initialize(v)
    @f0 = v
    @f25 = v + 1
  end

  def blank?
    @f1.nil? && @f2.nil? && @f3.nil? && @f4.nil? && @f5.nil? && @f6.nil? &&
      @f7.nil? && @f8.nil? && @f9.nil? && @f10.nil? && @f11.nil? && @f12.nil? &&
      @f13.nil? && @f14.nil? && @f15.nil? && @f16.nil? && @f17.nil? && @f18.nil? &&
      @f19.nil? && @f20.nil? && @f21.nil? && @f22.nil? && @f23.nil? && @f24.nil?
  end

  def sum
    @f0 + @f25
  end
end

class C27
  attr_reader :f0, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :f19, :f20, :f21, :f22, :f23, :f24, :f25, :f26
  def initialize(v)
    @f0 = v
    @f26 = v + 1
  end

  def blank?
    @f1.nil? && @f2.nil? && @f3.nil? && @f4.nil? && @f5.nil? && @f6.nil? &&
      @f7.nil? && @f8.nil? && @f9.nil? && @f10.nil? && @f11.nil? && @f12.nil? &&
      @f13.nil? && @f14.nil? && @f15.nil? && @f16.nil? && @f17.nil? && @f18.nil? &&
      @f19.nil? && @f20.nil? && @f21.nil? && @f22.nil? && @f23.nil? && @f24.nil? &&
      @f25.nil?
  end

  def sum
    @f0 + @f26
  end
end

total = 0
blank = 0
kept = []
40.times do |i|
  o0 = C0.new(i * 1)
  kept << o0
  blank += 1 if o0.blank?
  total += o0.sum
  o1 = C1.new(i * 2)
  kept << o1
  blank += 1 if o1.blank?
  total += o1.sum
  o2 = C2.new(i * 3)
  kept << o2
  blank += 1 if o2.blank?
  total += o2.sum
  o3 = C3.new(i * 4)
  kept << o3
  blank += 1 if o3.blank?
  total += o3.sum
  o8 = C8.new(i * 9)
  kept << o8
  blank += 1 if o8.blank?
  total += o8.sum
  o16 = C16.new(i * 17)
  kept << o16
  blank += 1 if o16.blank?
  total += o16.sum
  o24 = C24.new(i * 25)
  kept << o24
  blank += 1 if o24.blank?
  total += o24.sum
  o25 = C25.new(i * 26)
  kept << o25
  blank += 1 if o25.blank?
  total += o25.sum
  o26 = C26.new(i * 27)
  kept << o26
  blank += 1 if o26.blank?
  total += o26.sum
  o27 = C27.new(i * 28)
  kept << o27
  blank += 1 if o27.blank?
  total += o27.sum
  GC.start if i % 8 == 0
end
puts total
puts blank
puts kept.length

live = []
300.times do |i|
  live << C3.new(i)
  live << C3.new(-i)
  live << C25.new(i * 2)
end
GC.start
puts live.map { |o| o.sum }.sum
puts live.count { |o| o.blank? }
