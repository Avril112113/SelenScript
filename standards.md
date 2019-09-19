# Coding Standards for Lua and SelenScript  
NOTE: this is work in progress, suggestions are very much welcome  


# Comments
All comments must have a space after the `--`  
```Lua
-- Like this
--Not this
```  

If a comments is on a line with other code then it should be short and have 2 space's before `--`  
```Lua
local t  -- This is good
local a -- this
local c-- or this is bad
-- This is also fine, its on its own line
 -- but not this, no thanks
```


# Naming
Constants should be all capital's  
```Lua
SOME_CONST = "im some constant, i should never change"
OtherConst = "this is bad"
BADCONST = "this is also bad, 2 words with no defining seperation -_-"
```

Local variables should be snake_case  
```Lua
local nice_var
local badVar
local AlsoBad
local NOW_IM_JUST_A_CONST = "name said it all"
```

Global variable should be snake_case but also capitals
```Lua
Global_Thingy = "yes im global, nice to meet ya"
BadGlobal = "dont do me, im bad"
still_wrong = "am i a local?"
No_thx = "im ok, but not quite there"
```

Function names should be snake_case  
```Lua
function slither_like_a_snake() end
function NotThis() end
function Not_This() end
function but_this() end
```

`ipairs` and `pairs`
Pairs should use `k, v` for `pairs` and `i, v` for `ipairs`, but its always a good idea to name `v` in any case  
```Lua
-- Bad (NOTE `ipairs` and `pairs`)
for k, v in ipairs(t) do end
for i, v in pairs(t) do end
-- Alright (NOTE `ipairs` and `pairs`)
for i, v in ipairs(t) do end
for k, v in pairs(t) do end
-- Good (NOTE `ipairs` and `pairs`)
for i, user in ipairs(users) do end
for book_id, book in pairs(books) do end
```

Class' and Interface's should be CamelCase
```selenscript
interface Interfaced end
class ClassyClass implements Interfaced end
```

Just avoid `goto` when possible.

It is generally a good idea to split class' to there own file.  
Same can be said for sizable interface's.  

Unused variables ect should be prefixed with an underscore (`_`) to explisitly say it is not used.  
