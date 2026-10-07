# declist.rb FILE.rb -> prints which of the reader's decline conditions hold for the first
# blockless `Name = Class.new(...)` statement of the program:
#   L1 hoisted reach: before the assignment, a receiverless call (or send/method/public_send
#      with a literal name) names a method defined after it, or a constant read names a
#      class or module declared after it;
#   L2 reflection: before the assignment, a call named subclasses, constants or each_object,
#      or const_get / const_defined? with an argument that is not a literal;
#   L3 a singleton method on Class (def Class.x, class << Class).
require "prism"
def walk(n, &b)
  return unless n.is_a?(Prism::Node)
  b.(n)
  n.compact_child_nodes.each { |c| walk(c, &b) }
end
def check(src)
  root = Prism.parse(src).value
  asg = nil
  walk(root) do |n|
    next unless asg.nil? && n.is_a?(Prism::ConstantWriteNode)
    v = n.value
    asg = n if v.is_a?(Prism::CallNode) && v.name == :new && v.block.nil? && v.receiver.is_a?(Prism::ConstantReadNode) && v.receiver.name == :Class
  end
  return nil unless asg
  line = asg.location.start_line
  defs_after = []; decl_after = []
  walk(root) do |n|
    next unless n.location.start_line > line
    defs_after << n.name if n.is_a?(Prism::DefNode)
    decl_after << n.constant_path.name if (n.is_a?(Prism::ClassNode) || n.is_a?(Prism::ModuleNode)) && n.constant_path.respond_to?(:name)
  end
  l1 = l2 = l3 = false
  walk(root) do |n|
    if n.is_a?(Prism::DefNode) && n.receiver.is_a?(Prism::ConstantReadNode) && n.receiver.name == :Class then l3 = true end
    if n.is_a?(Prism::SingletonClassNode) && n.expression.is_a?(Prism::ConstantReadNode) && n.expression.name == :Class then l3 = true end
    next unless n.location.start_line < line
    case n
    when Prism::CallNode
      if n.receiver.nil? || n.receiver.is_a?(Prism::SelfNode)
        l1 = true if defs_after.include?(n.name)
        if %i[send __send__ public_send method].include?(n.name) && n.arguments
          a = n.arguments.arguments.first
          nm = a.is_a?(Prism::SymbolNode) ? a.unescaped.to_sym : a.is_a?(Prism::StringNode) ? a.unescaped.to_sym : nil
          l1 = true if nm.nil? || defs_after.include?(nm)
        end
      end
      l2 = true if %i[subclasses constants each_object].include?(n.name)
      if %i[const_get const_defined? const_source_location].include?(n.name)
        a = n.arguments&.arguments&.first
        l2 = true unless a.is_a?(Prism::SymbolNode) || a.is_a?(Prism::StringNode)
      end
    when Prism::ConstantReadNode then l1 = true if decl_after.include?(n.name)
    when Prism::ConstantPathNode then l1 = true if decl_after.include?(n.name)
    end
  end
  [("L1" if l1), ("L2" if l2), ("L3" if l3)].compact
end
if $0 == __FILE__
  ARGV.each { |f| r = check(File.read(f)); puts "#{File.basename(f, '.rb')}\t#{r.nil? ? 'no-assignment' : r.empty? ? '-' : r.join(',')}" }
end
