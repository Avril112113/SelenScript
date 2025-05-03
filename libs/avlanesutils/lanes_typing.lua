---@meta lanes

---@alias Lanes.Key string|number|boolean

---@class Lanes.cancel_error : lightuserdata
---@class Lanes.batched : lightuserdata

---@class Lanes
local lanes = {}

---@type string
lanes.ABOUT = nil

---@type Lanes.cancel_error
lanes.cancel_error = nil

---@class Lanes.ConfigureOpts
---@field nb_keepers nil|integer
---@field with_timers nil|false|true
---@field verbose_errors nil|false|true
---@field protect_allocator nil|false|true
---@field allocator nil|"protected"|function
---@field internal_allocator nil|"libc"|"allocator"
---@field demote_full_userdata nil|false|true
---@field track_lanes nil|false|any
---@field on_state_create nil|function
---@field shutdown_timeout nil|number

---@param opt_tbl Lanes.ConfigureOpts?
function lanes.configure(opt_tbl)
	return lanes
end

---@alias Lanes.GenLibsStr "*"|""|"base"|"bit"|"bit32"|"coroutine"|"debug"|"ffi"|"io"|"jit"|"math"|"os"|"package"|"string"|"table"|"utf8"
---@class Lanes.GenOpts
---@field globals nil|table
---@field required nil|table
---@field gc_cb nil|function
---@field priority nil|integer
---@field public package nil|table

---@param opt Lanes.GenLibsStr|Lanes.GenOpts
---@param lane_func function
---@return fun(...):Lanes.Thread
---@overload fun(opts:Lanes.GenLibsStr|Lanes.GenOpts, ...:Lanes.GenLibsStr|Lanes.GenOpts, lane_func:function): (fun(...):Lanes.Thread)
function lanes.gen(opt, lane_func) end

---@param o any
function lanes.nameof(o) end

---@param modname string
function lanes.require(modname) end

---@param modname string
---@param module table|function
function lanes.register(modname, module) end

---@param prio number  # -3 - +3
function lanes.set_thread_priority(prio) end

---@param affinity number
function lanes.set_thread_affinity(affinity) end

---@return {name:string, status:string}[]|nil
function lanes.threads() end

-- function set_error_reporting("basic"|"extended") end  -- Not sure where this is located...

---@param finalizer_func fun(err, stk)
function set_finalizer(finalizer_func) end

---@class Lanes.Thread
---@field [1] any  # Blocking
---@field status "pending"|"running"|"waiting"|"done"|"error"|"cancelled"|"killed"
---@field join fun(self, timeout_secs:integer?): (nil,string,table)|...
---@field cancel fun(self, how:"soft", timeout:integer?, wake_bool:boolean?): boolean, string?
---@field cancel fun(self, how:"soft", wake_bool:boolean?): boolean, string?
---@field cancel fun(self, how:"hard", timeout:integer?, force:boolean?, forcekill_timeout:integer?): boolean, string?
---@field cancel fun(self, how:"hard", force:boolean?, forcekill_timeout:integer?): boolean, string?
---@field cancel fun(self, mode:"count"|"line"|"call"|"ret"?, hookcount:integer?, timeout:integer?, force:boolean?, forcekill_timeout:integer?): boolean, string?

---@param opt_name string?  # type not exactly known
---@param opt_group string?  # type not exactly known
---@return Lanes.Linda
function lanes.linda(opt_name, opt_group) end

---@param linda Lanes.Linda
---@param key Lanes.Key
---@param n_uint integer?
---@return (fun(M_uint:integer, try:"try"?):boolean|Lanes.cancel_error)|Lanes.cancel_error
function lanes.genlock(linda, key, n_uint) end

---@param linda Lanes.Linda
---@param key Lanes.Key
---@param initial_num number?
---@return (fun(diff_num:number):integer|Lanes.cancel_error)|Lanes.cancel_error
function lanes.genatomic(linda, key, initial_num) end

---@class Lanes.Linda
---@field batched Lanes.batched
---@field send fun(self, timeout_secs:integer?, h_null:any?, key:Lanes.Key, ...:any): true|Lanes.cancel_error
---@field send fun(self, timeout_secs:integer?, key:Lanes.Key, ...): true|Lanes.cancel_error
---@field send fun(self, key:Lanes.Key, ...): true|Lanes.cancel_error
---@field receive fun(self, timeout_secs:integer?, key:Lanes.Key, ...:any?): (key:Lanes.Key|Lanes.cancel_error, value:any)
---@field receive fun(self, timeout_secs:integer?, batched:Lanes.batched, key:Lanes.Key, n_uint_min:integer, n_uint_max:integer?): (key:Lanes.Key|Lanes.cancel_error, ...:any)
---@field limit fun(self, key:Lanes.Key, n_uint:integer): true|Lanes.cancel_error
---@field set fun(self, key:Lanes.Key, val:any, ...): boolean|Lanes.cancel_error
---@field get fun(self, key:Lanes.Key, count:integer?): (...:any)|Lanes.cancel_error
---@field count fun(self, key:Lanes.Key): integer?
---@field count fun(self, key:Lanes.Key, ...:Lanes.Key): table<Lanes.Key,integer>
---@field count fun(self): table<Lanes.Key,integer>
---@field dump fun(self): table
---@field cancel fun(self, signal:"read"|"write"|"both"|"none")

---@return Lanes.Timer[]
function lanes.timers() end

---@class Lanes.Timer
---@field linda Lanes.Linda
---@field slot any?
---@field when any?
---@field period any?

---@param seconds number|false?
function lanes.sleep(seconds) end


return lanes
