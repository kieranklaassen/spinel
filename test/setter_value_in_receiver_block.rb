# A writer assignment written inside the receiver of another one (in a block
# of the receiver's call) answers its own right-hand side, not what the
# hand-written `def x=` returns.
class Job
  attr_reader :state, :owner
  def initialize = @state = :new
  def state=(s)
    @state = s
    @log = "state #{s}"
  end
  def owner=(o)
    @owner = o
    @log = "owner #{o}"
  end
end
def claim(job)
  tag = yield
  puts "claimed for #{tag}"
  job
end
def claim_blk(job, &blk)
  puts "claimed for #{blk.call}"
  job
end
def pass(job, tag)
  puts "passed #{tag}"
  job
end

a = Job.new
b = Job.new
c = Job.new
claim(a) { b.owner = "kai" }.state = :taken
p a.state, b.owner
claim_blk(a) { b.owner = "lin" }.state = :held
p a.state, b.owner
# as a value, and with a value that is a call
p(claim(a) { b.owner = "mio" }.state = [:done].first)
# two deep
claim(a) { claim(b) { c.owner = "noa" }.state = :inner }.state = :outer
p a.state, b.state, c.owner
# through a lambda and an Array's block in an argument of the receiver's call
pass(a, -> { b.owner = "oki" }.call).state = :l
pass(a, [0].map { b.owner = "pia" }.first).state = :m
p a.state, b.owner
