-- WARNING: this is a generated file by transpile_provided.lua
return {
	createClass = {
		lua="if __sls_createClass==(nil) then\nBaseClass={__sls_clsName=\"BaseClass\",__sls_inherits={}}\nBaseClass.__class=BaseClass\nfunction BaseClass:__index(index)local value\nlocal cls=rawget(self,\"__class\")\nvalue=rawget(cls,index)\nif value==(nil) then\nfor _,v in ipairs(rawget(cls,\"__sls_inherits\")) do\nif v~=self then\nvalue=v[index]\nif value~=(nil) then\nreturn value\nend\nend\nend\nend\nreturn value\nend\nfunction BaseClass:__call(...)if self:is_class() then\nlocal obj=setmetatable({__class=self},self)\nreturn obj\nelse error(\"attempt to call an object value (\"..tostring(self)..\")\")end\nend\nfunction BaseClass:__tostring()if self:is_class() then\nreturn \"<Class \"..self.__sls_clsName..\" at \"..__sls_getTblAddr(self)..\">\"\nelse return \"<Object of \"..tostring(self.__class)..\" at \"..__sls_getTblAddr(self)..\">\"\nend\nend\nfunction BaseClass:is_class()return rawget(self,\"__sls_clsName\")~=(nil)\nend\nfunction __sls_createClass(clsName)local cls={__sls_clsName=clsName,__sls_inherits={[1]=BaseClass}}\ncls.__class=cls\ncls.__index=BaseClass.__index\nreturn setmetatable(cls,cls)\nend\nend\n",
		deps={"getTblAddr",}
	},
	getTblAddr = {
		lua="if __sls_getTblAddr==(nil) or __sls_addressCache==(nil) then\n__sls_addressCache=setmetatable({},{__mode=\"k\"})\nfunction __sls_getTblAddr(tbl)local mt=getmetatable(tbl)\nif __sls_addressCache[tbl]~=(nil) then\nreturn __sls_addressCache[tbl]\nend\nlocal __tostring=rawget(mt,\"__tostring\")\nrawset(mt,\"__tostring\",(nil))local address=tostring(tbl):gsub(\"^%w+: \",\"\")\nrawset(mt,\"__tostring\",__tostring)__sls_addressCache[tbl]=address\nreturn address\nend\nend\n",
		deps={}
	},
}