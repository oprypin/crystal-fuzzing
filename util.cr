require "compiler/crystal/syntax"
require "openssl"
require "process"


def tmp_dir(name : String)
  if !File.directory?(name)
    File.delete(name) rescue nil
    temp_dir = File.tempname("fuzz", File.basename(name))
    Dir.mkdir(temp_dir)
    File.symlink(temp_dir, name)
  end
  return File.real_path(name)
end

RADAMSA_PORT = 31337

def get_input
  TCPSocket.open("localhost", RADAMSA_PORT, &.gets_to_end)
end

def parse(src : String)
  Crystal::Parser.new(src).parse
end

def run_process(
  *args, output : Process::Redirect = :inherit, error : Process::Redirect = :inherit,
  check = true, **kwargs
)
  kwargs = {output: output, error: error}.merge(kwargs)
  argv = args.to_a
  r = Process.run(argv.shift, argv, **kwargs)
  if check && !r.success?
    raise "Process #{args} exited with status #{r.exit_status}"
  end
  return r
end

def start_process(
  *args, output : Process::Redirect = :inherit, error : Process::Redirect = :inherit, **kwargs
)
  kwargs = {output: output, error: error}.merge(kwargs)
  args = args.to_a
  Process.new(args.shift, args, **kwargs)
end

def crystal_repo
  path = File.join(__DIR__, "crystal")
  if !File.directory?(path)
    tmp_dir(path)
    run_process("git", "clone", "--depth=1", "https://github.com/crystal-lang/crystal", path)
  end
  return path
end
