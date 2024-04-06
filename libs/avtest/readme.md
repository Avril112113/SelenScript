# Avril's Test library
A simple yet powerful unit testing library.  

Some methods require external libraries, however they are optional.  
Ensure to require `avtest.init` or `avtest.ext` to make these available, otherwise they will error with `Not implemented`.  
Some optional dependencies are C libraries, which can cause the VM to crash if for the wrong Lua version or bitage, ensure these aren't trying to be loaded.  

If [lfs](https://github.com/lunarmodules/luafilesystem) is available:  
`TestGroup:loadFolder`  


TODO:  
Support fs from `LOVE2D`  
Support fs from `LOVR`  
