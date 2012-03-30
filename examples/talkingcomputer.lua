package.path = package.path .. ';../?.lua'
local objc = require("objc")
objc.loadFramework("AppKit")
pool = objc.NSAutoreleasePool:new()
objc.NSSpeechSynthesizer:new():startSpeakingString(objc.NSStr("Hello From Lua!"))
os.execute("sleep "..2)
