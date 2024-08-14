Generates AST node typing and node constructor functions from a `lpeglabel` grammar.  
Intended for and only tested for SelenScript, however `print_ptree.lua`, `lpeg_ptree.lua` and `lpeg_grammar_info.lua` should work for other grammars.  

Ensure `lpeglabel` is built with debug functions from [Avril112113/lpeglabel](https://github.com/Avril112113/lpeglabel). (this is provided by SelenScript at `/libs/lpeglabel.dll`)  
Ensure
Run `luajit ./tools/grammar_typing_gen/print_ptree.lua > ./tools/grammar_typing_gen/grammar.ptree.txt`  
Run `luajit ./tools/grammar_typing_gen/gen.lua`  
