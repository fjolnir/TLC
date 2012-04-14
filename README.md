# TLC - The Tiny Lua Cocoa Bridge

TLC is a very compact and minimal Objective-C bridge for LuaJIT.
Written by Fjõlnir Ásgeirsson <fjolnir at asgeirsson dot is>

## Simple Example
```lua
local objc = require("objc")
objc.loadFramework("AppKit")
pool = objc.NSAutoreleasePool:new()
objc.NSSpeechSynthesizer:new():startSpeakingString(objc.NSStr("Hello From Lua!"))
os.execute("sleep "..2)
```

## Mini-Documentation

TLC supports the following:

 * Loading frameworks
 * Accessing Objective-C objects
 * Creating Objective-C classes
 * Calling methods on said objects
 * Creating blocks from Lua functions
 * Converting the basic lua types to objects (Explicitly)
 * Loading BridgeSupport files

TLC Does not *yet* support the following:

 * Calling methods that take a variable number of arguments
 * Defining variadic blocks, methods or callbacks, or ones that take pass-by-value(non-pointer) structs or unions. (A limitation of LuaJIT FFI)

### Loading TLC
```lua
local objc = require("objc")
```
### Loading frameworks
```lua
objc.loadFramework("Foundation")

-- You can also use BridgeSupport
-- It is slower, but you get access to all C types, functions & constants automatically
local bs = require("objc.BridgeSupport")
bs.loadFramework("Foundation")
-- You can then access constants using bs
myView.center = bs.CGPointZero
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
-- Example selector:with:multiple:parameters: => selector_with_multiple_parameters()
--         selectorWithAnonymousParams:::: => selectorWithAnonymousParams()
local anObject = MyObject:selector_with_multiple_parameters(arg1, arg2, arg3, arg4)
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

### Subclassing & Extending of Classes
```lua
-- This creates a class and registers it with the runtime (it is also accessible with objc.MyClass after creation)
-- The dictionary specifies an instance variable of type int(type encoding: i)
-- To learn about type encodings read https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
local MyClass = objc.createClass(objc.NSObject, "MyClass", { ivar="i" })

-- Creates an init method returning an object(@) and taking as arguments an object(@) and a selector(:)
-- All methods must take self and selector as their first two arguments
objc.addMethod(MyClass, objc.SEL("init"), function(self, sel)
	print("Creating an instance of", self:class())
	objc.setIvar(self, "anIvar", 123)
	return objc.callSuper(self, sel)
end, "@@:")

-- Add a getter for 'ivar'
objc.addMethod(MyClass, objc.SEL("ivar"), function(self, sel)
	return objc.getIvar(self, "ivar")
end, "i@:")
-- Add a setter for 'ivar'
objc.addMethod(MyClass, objc.SEL("setIvar:"), function(self, sel, anIvar)
	objc.setIvar(self, "ivar", anIvar)
end, "v@:i")

-- 'instance' is an object pointer usable on the lua side as well as the objective-c side
local instance = MyClass:alloc():init()
instance:setIvar(123)
print(instance:ivar())
```

### Creating Blocks from Lua Functions
```lua
-- To create a block you call createBlock with it's type encoding (Default being void return and no argument)
-- A block returning an integer and taking one object and one double as arguments
local block = objc.createBlock(function(object, double)
	print("I was passed these arguments: ", object, double)
	return 123
end, "i@d")
```

### (Dirty Secret Trick)
```lua
-- If you don't want to type 'objc.' before using a class you can set the global namespace to use it as a fallback
setmetatable(_G, {__index=objc})
-- And then you can simply write the class names without the 'objc.' prefix
obj = CoolClass:doThings()
```

