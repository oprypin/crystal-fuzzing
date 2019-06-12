require "compiler/crystal/syntax"
require "process"
require "socket"

def parse(src)
  Crystal::Parser.new(src).parse
end

Dir.mkdir_p("samples")
def samples_path
  File.real_path("samples")
end

def save_variable(name)
  %{
    File.write(File.join(#{samples_path.inspect}, #{name}.hash.to_s(16) + ".txt"), #{name})
  }
end

class Visitor < Crystal::ToSVisitor
  def visit(node : Crystal::Def)
    if node.name == "expect_to_s"
      node.body = parse %{
        [original, expected].uniq!.each do |s|
          #{parse(save_variable("s"))}
        end
      }
    elsif node.name == "assert_syntax_error"
      node.body = parse(save_variable("s"))
    elsif node.name == "it_parses"
      node.body = parse(save_variable("string"))
    end
    super
  end
end

["crystal/spec/compiler/parser/to_s_spec.cr", "crystal/spec/compiler/parser/parser_spec.cr"].each do |file|
  src = File.read(file)

  vis = Visitor.new
  vis.accept(parse(src))

  program = IO::Memory.new(vis.to_s)


  Process.run("crystal", ["eval"], input: program, output: :inherit, error: :inherit, chdir: File.dirname(file))
end


PORT = 31337

radamsa = Process.new("radamsa", ["--output", ":#{PORT}", "--count", "inf", "--recursive", samples_path], output: :inherit, error: :inherit)
at_exit do
  radamsa.kill
end
sleep 1

loop do
  client = TCPSocket.new("localhost", PORT)
  src = client.gets_to_end
  client.close

  if src.includes?("macro") || src.includes?("LibC") # widespread issue!
    next
  end
  begin
    src.chars
  rescue
    next
  end

  begin
    parsed = parse(src)
    rendered = parsed.to_s
  rescue Crystal::SyntaxException | InvalidByteSequenceError
    next
  rescue ArgumentError # widespread issue!
    next
  rescue e
    puts "Bad exception type during parsing:"
    puts src.dump_unquoted
    puts e
    puts
    next
  end
  begin
    rendered2 = parse(rendered).to_s
  rescue InvalidByteSequenceError  # widespread issue!
    next
  rescue e
    puts "This code was parsed:"
    puts src.dump_unquoted
    puts "And converted into:"
    puts rendered.dump_unquoted
    puts "But that caused an exception:"
    puts e
    puts
    next
  end
  if rendered2 != rendered
    puts "This code was parsed:"
    puts src.dump_unquoted
    puts "And converted into:"
    puts rendered.dump_unquoted
    puts "But repeat stringification produced a diff:"
    puts rendered2.dump_unquoted
    puts
    next
  end
end
