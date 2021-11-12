require "compiler/crystal/syntax"
require "../util"


Dir.cd(File.dirname(__FILE__))


def save_variable(name)
  %{
    File.write(File.join(#{tmp_dir("samples").inspect}, #{name}.hash.to_s(16) + ".txt"), #{name})
  }
end

class Visitor < Crystal::ToSVisitor
  def visit(node : Crystal::Def)
    case node.name
    when "expect_to_s"
      node.body = parse %{
        [original, expected].uniq!.each do |str|
          #{save_variable("str")}
        end
      }
    when "it_parses", "it_lexes"
      node.body = parse(save_variable("string"))
    when "assert_end_location"
      node.body = parse(save_variable("source"))
    end
    super
  end
end

if !File.directory?("samples")
  [
    "#{crystal_repo}/spec/compiler/lexer/lexer_spec.cr",
    "#{crystal_repo}/spec/compiler/parser/parser_spec.cr",
    "#{crystal_repo}/spec/compiler/parser/to_s_spec.cr",
  ].each do |filename|
    src = File.read(filename)
    ast = parse(src).as(Crystal::Expressions)

    ast.expressions << parse(%{
      def assert_syntax_error(str, message = nil, line = nil, column = nil)
        #{parse(save_variable("str"))}
      end
    })

    program = IO::Memory.new
    Visitor.new(program).accept(ast)

    run_process("crystal", "eval", input: program.rewind, chdir: File.dirname(filename))
  end
end

radamsa = start_process("radamsa", "--output", ":#{RADAMSA_PORT}", "--count", "inf", "--recursive", "samples")
at_exit do
  radamsa.signal :kill
end
run_process("crystal", "build", "fuzz_parser/tester.cr", "-o", "fuzz_parser/tester", chdir: "..")
if radamsa.terminated?
  exit(1)
end

loop do
  run_process("./tester", check: false, error: :close)
end
