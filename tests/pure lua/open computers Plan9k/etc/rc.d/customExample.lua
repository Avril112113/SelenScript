--[[

x = File name without extention

'enable' lets it run on startup
rc x enable
eg 'rc customExample enable'

'disable' stops it from running at startup
rc x disable
eg 'rc customExample disable'

'restart' runs stop and after that is done it runs start
rc x restart
eg 'rc customExample restart'

any other function that is not local can be run the same way example is potato
rc x potato
eg 'rc customExample potato'

]]--

function start(argStr)
	print("customExample service start with args:", argStr)
end

function stop(argStr)
	print("customExample service stop with args:", argStr)
end

function potato(argStr)
	print("customExample service potato with args:", argStr)
end
