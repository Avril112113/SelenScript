---@meta
-- Typing information for LuaNotify https://github.com/Avril112113/luanotify

---@class LuaNotify.Watcher
---@field watch fun(self, path:string, recursive:boolean?):boolean,string?
---@field unwatch fun(self, path:string):boolean,string?
---@field poll fun(self):LuaNotify.Event?
---@field whitelist_glob fun(self, glob:string)
---@field blacklist_glob fun(self, glob:string)

---@class LuaNotify.Event
---@field type "unknown"|"access"|"create"|"modify"|"remove"
---@field kind nil | "read"|"open"|"close" | "file"|"folder" | "data"|"metadata"|"name"
---@field mode nil | "execute"|"read"|"write" | "size"|"content" | "access_time"|"write_time"|"permissions"|"ownership"|"extended" | "to"|"from"|"both"
---@field paths string[]
---@field attrs table # See https://docs.rs/notify/latest/notify/event/struct.EventAttributes.html

---@class LuaNotify
---@field new fun():LuaNotify.Watcher

---@type LuaNotify
local _
return _
