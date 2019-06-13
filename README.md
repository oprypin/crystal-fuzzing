# [Fuzzing] for [Crystal] programming language


## `crystal fuzz_parser/main.cr`

* Fuzzes Crystal's parser and code stringifier.

* Uses existing parser specs as samples.

* Writes errors into a local SQLite database.
    * Possible sets of fields (others `NULL`):

      | `original_src` | `parsed_src` | `reparsed_src` | `exception` | outcome of Crystal compiler's actions |
      | :-: | :-: | :-: | :-: | -- |
      | ✔ |  |  |  | crashed during initial parsing |
      | ✔ |  |  | ✔ | threw an exception during initial parsing |
      | ✔ | ✔ |  | ✔ | parsed a sample and stringified it but raised when parsing that again |
      | ✔ | ✔ | ✔ | | parsed and stringified a sample, but parsing and stringifying that again produced a different result |
 
    * `sqlitebrowser` recommended for viewing.

* Requires: `crystal`, `radamsa`, `libsqlite3`.


[fuzzing]: https://www.google.com/search?q=fuzzing
[crystal]: https://crystal-lang.org/
