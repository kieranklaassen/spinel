# gen3.rb OUT -- hand-written specials for commit 2 (multi-file, reflection, the first-class fault, redefined Class.new)
require "fileutils"
out = ARGV[0]
FileUtils.mkdir_p(["#{out}/prog", "#{out}/twin"])
def tw(l) = l.sub(/\A(\s*)([A-Z]\w*) = Class\.new(?:\(((?:::)?[A-Z][A-Za-z]*)\))?\z/) { $3 ? "#{$1}class #{$2} < #{$3}; end" : "#{$1}class #{$2}; end" }
P = {}
def prog(name, src, libs = {}) = P[name] = [src, libs]
LIB = { "errs_lib.rb" => "MyErr = Class.new(StandardError)\n" }
prog "first_class_copy", <<~R
  MyErr = Class.new(StandardError)
  def copy(e) = e.class.new("copy of \#{e.message}")
  begin
    [1, 2].fetch(9)
  rescue IndexError => e
    c = copy(e)
    p c.class
    begin
      raise c
    rescue IndexError => e2
      puts "caught \#{e2.class}"
    rescue StandardError => e2
      puts "wrong arm \#{e2.class}"
    end
  end
R
prog "first_class_new", <<~R
  MyErr = Class.new(StandardError)
  begin
    Integer("zz")
  rescue ArgumentError => e
    k = e.class
    p k.new("z").class
  end
R
prog "first_class_new_not_first", <<~R
  class Thing; end
  MyErr = Class.new(StandardError)
  begin
    Integer("zz")
  rescue ArgumentError => e
    k = e.class
    p k.new("z").class
  end
R
prog "first_class_new_plain", <<~R
  Pt = Class.new
  begin
    Integer("zz")
  rescue ArgumentError => e
    k = e.class
    p k.new("z").class
  end
R
prog "first_class_isa", <<~R
  MyErr = Class.new(StandardError)
  begin
    1 / 0
  rescue => e
    p e.class.new("z").is_a?(ZeroDivisionError), e.class.new("z").message
  end
R
prog "first_class_in_module", <<~R
  module App
    Error = Class.new(StandardError)
  end
  begin
    Integer("zz")
  rescue ArgumentError => e
    p e.class.new("z").class
  end
R
prog "subclasses_before", <<~R
  class BaseErr < StandardError; end
  p BaseErr.subclasses
  MyErr = Class.new(BaseErr)
R
prog "subclasses_before_after", <<~R
  class BaseErr < StandardError; end
  p BaseErr.subclasses.size
  MyErr = Class.new(BaseErr)
  p BaseErr.subclasses.size
R
prog "const_get_dyn_before", <<~R
  x = "My"
  begin
    Object.const_get(x + "Err")
    puts "there"
  rescue NameError
    puts "not yet"
  end
  MyErr = Class.new(StandardError)
R
prog "const_get_dyn_after", <<~R
  MyErr = Class.new(StandardError)
  x = "My"
  p Object.const_get(x + "Err").new("m").message
R
prog "class_new_redefined", <<~R
  def Class.new(*a) = 42
  MyErr = Class.new(StandardError)
  p MyErr
R
prog "class_singleton_new", <<~R
  class << Class
    def new(*a) = 42
  end
  MyErr = Class.new(StandardError)
  p MyErr
R
prog "send_later_def", <<~R
  begin
    send(:early)
    puts "there"
  rescue NameError
    puts "not yet"
  end
  MyErr = Class.new(StandardError)
  def early = MyErr.new("e")
R
prog "method_later_def", <<~R
  begin
    method(:early).call
    puts "there"
  rescue NameError
    puts "not yet"
  end
  MyErr = Class.new(StandardError)
  def early = MyErr.new("e")
R
prog "later_def_smallest", <<~R
  begin
    early
    puts "there"
  rescue NameError
    puts "not yet"
  end
  MyErr = Class.new(StandardError)
  def early = MyErr.new("e")
R
prog "later_class_smallest", <<~R
  begin
    Helper.make
    puts "there"
  rescue NameError => e
    puts e.class
  end
  MyErr = Class.new(StandardError)
  class Helper
    def self.make = MyErr.new("e")
  end
R
prog "later_def_uncaught", <<~R
  puts "start"
  Helper.make
  puts "there"
  MyErr = Class.new(StandardError)
  class Helper
    def self.make = MyErr.new("e")
  end
R
prog "later_def_plain_class", <<~R
  begin
    early
    puts "there"
  rescue NameError
    puts "not yet"
  end
  Pt = Class.new
  def early = Pt.new
R
prog "later_def_user_parent", <<~R
  class Base
    def hi = "hi"
  end
  begin
    puts early.hi
  rescue NameError
    puts "not yet"
  end
  Sub = Class.new(Base)
  def early = Sub.new
R
prog "later_def_in_module", <<~R
  begin
    App.make
    puts "there"
  rescue NameError
    puts "not yet"
  end
  module App
    MyErr = Class.new(StandardError)
    def self.make = MyErr.new("e")
  end
R
prog "require_basic", <<~R, LIB
  require_relative "errs_lib"
  begin
    raise MyErr, "x"
  rescue StandardError => e
    puts "got \#{e.message} \#{e.class}"
  end
R
prog "require_in_method", <<~R, LIB
  def setup
    require_relative "errs_lib"
  end
  begin
    p MyErr.new("x").message
  rescue NameError
    puts "undefined"
  end
  setup
  p MyErr.new("y").message
R
prog "require_named_before", <<~R, LIB
  begin
    MyErr
    puts "there"
  rescue NameError
    puts "not yet"
  end
  require_relative "errs_lib"
  p MyErr.new("x").message
R
prog "require_cond", <<~R, LIB
  require_relative "errs_lib" if ARGV.size > 5
  begin
    p MyErr.new("x").message
  rescue NameError
    puts "undefined"
  end
R
prog "require_lib_reads_first", <<~R, { "reads_lib.rb" => "begin\n  MyErr\n  puts \"there\"\nrescue NameError\n  puts \"not yet\"\nend\n" }
  require_relative "reads_lib"
  MyErr = Class.new(StandardError)
  p MyErr.new("x").message
R
prog "require_lib_def_called_first", <<~R, { "def_lib.rb" => "def early = MyErr.new(\"e\")\n" }
  begin
    early
    puts "there"
  rescue NameError
    puts "not yet"
  end
  MyErr = Class.new(StandardError)
  require_relative "def_lib"
R
prog "require_two_files", <<~R, LIB.merge("errs_lib2.rb" => "$VERBOSE = nil\nMyErr = Class.new(ArgumentError)\n")
  require_relative "errs_lib"
  require_relative "errs_lib2"
  p MyErr.superclass
R
prog "require_parent_in_lib", <<~R, { "base_lib.rb" => "class BaseErr < StandardError\n  def hint = \"h\"\nend\n" }
  require_relative "base_lib"
  MyErr = Class.new(BaseErr)
  begin
    raise MyErr, "x"
  rescue BaseErr => e
    puts "got \#{e.message} \#{e.hint} \#{e.class}"
  end
R
prog "require_lib_uses_main_parent", <<~R, { "sub_lib.rb" => "MyErr = Class.new(BaseErr)\n" }
  class BaseErr < StandardError; end
  require_relative "sub_lib"
  begin
    raise MyErr, "x"
  rescue BaseErr => e
    puts "got \#{e.message} \#{e.class}"
  end
R
prog "hierarchy_usual", <<~R
  module Shop
    Error = Class.new(StandardError)
    NotFound = Class.new(Error)
    Invalid = Class.new(Error)
    class Store
      def initialize = @items = { "a" => 1 }
      def fetch(k)
        raise Invalid, "nil key" if k.nil?
        @items.fetch(k) { raise NotFound, "no \#{k}" }
      end
    end
  end
  s = Shop::Store.new
  [["a"], ["b"], [nil]].each do |(k)|
    begin
      p s.fetch(k)
    rescue Shop::NotFound => e
      puts "not found: \#{e.message}"
    rescue Shop::Error => e
      puts "error: \#{e.message} (\#{e.class})"
    end
  end
R
prog "hierarchy_kept_asked", <<~R
  Error = Class.new(StandardError)
  Fatal = Class.new(Error)
  log = []
  [Error, Fatal, ArgumentError].each do |k|
    begin
      raise k, "m"
    rescue StandardError => e
      log << e
    end
  end
  log << 3
  p log.map { |x| x.is_a?(Error) }, log.map { |x| x.instance_of?(Error) }
  r = log.map do |x|
    case x
    when Fatal then :fatal
    when Error then :error
    when StandardError then :std
    else :none
    end
  end
  p r
R
prog "inherited_hook", <<~R
  class Base
    def self.inherited(k)
      puts "inherited \#{k.name.inspect}"
      super
    end
  end
  Sub = Class.new(Base)
  p Sub.name
R
prog "exit_status_uncaught", <<~R
  MyErr = Class.new(StandardError)
  at_exit { puts "exit \#{$!.class}" }
  raise MyErr, "x"
R
prog "raise_message_default", <<~R
  MyErr = Class.new(StandardError)
  begin
    raise MyErr
  rescue => e
    p e.message, e.class, e.inspect
  end
R
P.each do |name, (src, libs)|
  File.write("#{out}/prog/sp_#{name}.rb", src)
  t = src.lines.map { |l| tw(l.chomp) }.join("\n") + "\n"
  libs.each do |fn, txt|
    File.write("#{out}/prog/#{fn}", txt)
    File.write("#{out}/twin/#{fn}", txt.lines.map { |l| tw(l.chomp) }.join("\n") + "\n")
  end
  lib_changed = libs.any? { |fn, txt| txt.lines.any? { |l| tw(l.chomp) != l.chomp } }
  File.write("#{out}/twin/sp_#{name}.rb", t) if t != src || lib_changed
end
puts P.size
