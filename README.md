# TLC - The Tiny Lua Cocoa Bridge

TLC is a very compact and minimal Objective-C bridge for LuaJIT.
Written by Fjõlnir Ásgeirsson <fjolnir at asgeirsson dot is>

## Simple Example
```lua
objc = require("objc")
objc.loadFramework("AppKit")
pool = objc.NSAutoreleasePool:new()
objc.NSSpeechSynthesizer:new():startSpeakingString(objc.strToObj("Hello From Lua!"))
os.execute("sleep "..3)
```

## Mini-Documentation

TLC supports the following:
 * Loading frameworks
 * Accessing Objective-C objects
 * Calling methods on said objects
 * Creating blocks from Lua functions
 * Converting the basic lua types to objects (Explicitly)

TLC Does not *yet* support the following:
 * Calling methods that take a variable number of arguments

### Loading TLC
```lua
local objc = require("objc")
```
### Loading frameworks
```lua
objc.loadFramework("AppKit")
```

### Accessing Objective-C objects
```lua
local NSString = objc.NSString
```

### Calling Methods
```lua
local myStr = NSString:stringWithUTF8String("I am an NSString.")

-- Calling selectors with multiple arguments requires replacing the colons with underscores
-- Except the ones at the end, they are optional.
-- Example selector:with:multiple:arguments: => selector_with_multiple_arguments()
--         selectorWithAnonymousArgs:::: => selectorWithAnonymousArgs()
local anObject = MyObject:selector_with_multiple_arguments(arg1, arg2, arg3, arg4)
```
## Creating Blocks from Lua Functions
```lua
-- To create a block you call createBlock with it's type encoding (Default being void return and no argument)
-- To learn about type encodings read https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
-- A block returning an integer and taking one object and one double as arguments
local block = objc.createBlock(function(object, double)
	print("I was passed these arguments: ", object, double)
	return 123
end, "i", {"@", "d"})
```

### Converting the Basic Lua Types to Objects
```lua
-- If you know the type of the variable you want to convert you should use these functions
local string     = NSStr("foobar")
local number     = NSNum(123)
local array      = NSArr({"a","b","c"})
local dictionary = NSDic({ a=1, b=2, c=3 })
-- If not,
-- The Obj() function takes an arbitrary value and determines the correct class to convert it to
local object = Obj(anyVariable)
```

### (Dirty Secret Trick)
```lua
-- If you don't want to type 'objc.' before using a class you can set the global namespace to use it as a fallback
setmetatable(_G, {__index=objc})
-- And then you can simply write the class names without the 'objc.' prefix
obj = CoolClass:doThings()
```
