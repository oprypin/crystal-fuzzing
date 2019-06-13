require "sqlite3"
require "../util"


D = DB.open "sqlite3://errors.sqlite3"
at_exit do
  D.close
end

D.exec(%{
  CREATE TABLE IF NOT EXISTS errors (
    original_src TEXT PRIMARY KEY,
    parsed_src TEXT,
    reparsed_src TEXT,
    exception TEXT
  )
})

def save(original_src, **kwargs)
  if kwargs.empty?
    D.exec(%{
      INSERT OR IGNORE INTO errors (original_src) VALUES (?)
    }, original_src)
  else
    D.exec(%{
      UPDATE errors SET #{kwargs.keys.map { |k| "#{k} = ?" } .join(", ")} WHERE original_src = ?
    }, *kwargs.values, original_src)
  end
end

def delete(original_src)
  D.exec(%{
    DELETE FROM errors WHERE original_src = ?
  }, original_src)
end

loop do
  src = get_input
  print "."
  save(src)

  begin
    parsed = parse(src).to_s
  rescue Crystal::SyntaxException | InvalidByteSequenceError
    delete(src)
    next
  rescue e
    save(src, exception: "#{e.class}: #{e}")
    next
  end
  save(src, parsed_src: parsed)
  begin
    reparsed = parse(parsed).to_s
  rescue e
    save(src, exception: "#{e.class}: #{e}")
    next
  end
  if reparsed != parsed
    save(src, reparsed_src: reparsed)
  else
    delete(src)
  end
end
