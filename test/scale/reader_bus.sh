#!/bin/sh
N=${1:-64}
awk -v N="$N" 'BEGIN {
  for (i = 1; i <= N; i++)
    printf "class Dev%d\n  def initialize(nxt) = @nxt = nxt\n  def peek(i) = @nxt.peek(i)\nend\n", i
  print "class Leaf\n  def initialize = @v = [+\"leaf\", +\"two\"]\n  def peek(i) = cell(i)\n  def cell(i) = @v[i]\nend"
  printf "kinds = [Dev1"
  for (i = 2; i <= N; i++) printf ", Dev%d", i
  print "]\nbus = Leaf.new\nkinds.each { |k| bus = k.new(bus) }"
  for (i = 0; i < N; i++) printf "bus.peek(%d) << \"!\"\n", i % 2
  print "p bus.peek(0).size, bus.peek(1).size"
}'
