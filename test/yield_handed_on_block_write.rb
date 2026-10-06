# A local a block writes keeps the write when the method it is given to
# hands it on to one that rescues around the yield
def guarded
  begin
    yield
  rescue
    :rescued
  end
end

# the yield is in a block the method hands on
def twice_guarded
  guarded { yield }
end

def run_through
  n = 0
  rate = 1.5
  mark = :old
  ok = false
  r = twice_guarded { n = 7; rate = 2.5; mark = :new; ok = true; raise "no" }
  [r, n, rate, mark, ok]
end
p run_through

# the block is passed on by name
def passed_on(&blk)
  guarded(&blk)
end

def run_passed
  n = 0
  passed_on { n = 8; raise "no" }
  n
end
p run_passed

# three more methods between the block and the rescue
def third
  twice_guarded { yield }
end

def fourth
  third { yield }
end

def fifth
  fourth { yield }
end

def run_far(k)
  fifth { k += 6; raise "no" }
  k
end
p run_far(0)

# at the top level
top = 3
twice_guarded { top = 5; raise "no" }
p top

# an ensure and a rescue modifier are the method's setjmp too
def ensured
  yield
ensure
  $seen = true
end

def through_ensure
  ensured { yield }
end

def run_ensured
  n = 1
  begin
    through_ensure { n = 2; raise "no" }
  rescue
    n += 10
  end
  n
end
p run_ensured

def quiet
  (yield) rescue nil
end

def through_quiet
  quiet { yield }
end

def run_quiet
  n = 1
  through_quiet { n = 2; raise "no" }
  n
end
p run_quiet

# a method that reaches itself
def countdown(k)
  begin
    yield k
  rescue
    nil
  end
  countdown(k - 1) { |x| yield x } if k > 0
end

def run_countdown
  sum = 0
  countdown(3) { |x| sum += x; raise "no" if x == 2 }
  sum
end
p run_countdown
