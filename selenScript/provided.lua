-- WARNING: this is a generated file by transpile_provided.lua
return {
	createClass = {
		lua="if __sls_createClass==(nil) then\nfunction __sls_createClass(clsName)local cls={__sls_clsName=clsName,__sls_inherits={}}\nfunction cls:__index(index)local value\nlocal __index=rawget(cls,\"__sls__index\")\nif __index~=(nil) then\nvalue=__index(self,index)\nend\nvalue=rawget(cls,index)\nif value==(nil) then\nfor _,v in ipairs(rawget(cls,\"__sls_inherits\")) do\nvalue=v[index]\nif value~=(nil) then\nreturn value\nend\nend\nend\nreturn value\nend\nfunction cls:__call(...)local __call=rawget(cls,\"__sls__call\")\nif __call~=(nil) then\nreturn __call(self,...)\nend\nif self~=cls then\nerror(\"attempt to call a object value (\"..(tostring(self)..\")\"),1)end\nlocal obj=setmetatable({},cls)\nreturn obj\nend\nfunction cls:__tostring()local __tostring=rawget(cls,\"__sls__tostring\")\nif __tostring~=(nil) then\nreturn __tostring(self)\nend\nif cls==self then\nreturn \"<Class \"..(self.__sls_clsName..(\" at \"..(__sls_getTblAddr(self)..\">\")))\nelse return \"<Object of \"..(tostring(cls)..(\" at \"..(__sls_getTblAddr(self)..\">\")))\nend\nend\nreturn setmetatable(cls,cls)\nend\nend\n24",
		deps={"getTblAddr",}
	},
	getTblAddr = {
		lua="if __sls_getTblAddr==(nil) or __sls_addressCache==(nil) then\n__sls_addressCache=setmetatable({},{__mode=\"k\"})\nfunction __sls_getTblAddr(tbl)local mt=getmetatable(tbl)\nif __sls_addressCache[tbl]~=(nil) then\nreturn __sls_addressCache[tbl]\nend\nlocal __tostring=mt.__tostring\nmt.__tostring=(nil)\nlocal address=tostring(tbl):gsub(\"^%w+: \",\"\")\nmt.__tostring=__tostring\n__sls_addressCache[tbl]=address\nreturn address\nend\nend\n6",
		deps={}
	},
}