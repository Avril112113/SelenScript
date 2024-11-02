@echo off
luajit ./tools/grammar_typing_gen/print_ptree.lua > ./tools/grammar_typing_gen/grammar.ptree.txt
luajit ./tools/grammar_typing_gen/gen.lua
