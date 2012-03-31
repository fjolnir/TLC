-- TLC - The Tiny Lua Cocoa Bridge
-- Note: Only tested with LuaJit 2 Beta 9 on x86_64 with OS X >=10.6 & iPhone 4 with iOS 5

-- Copyright (c) 2012, Fjölnir Ásgeirsson

-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.

-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-- Usage:
-- Accessing a class: MyClass = objc.MyClass
-- Loading a framework: objc.loadFramework("AppKit")
   -- Foundation is loaded by default.
   -- The table objc.frameworkSearchPaths, contains a list of paths to search (formatted like /System/Library/Frameworks/%s.framework/%s)
-- Creating objects: MyClass:new() or MyClass:alloc():init()
   -- Retaining&Releasing objects is handled by the lua garbage collector so you should never need to call retain/release
-- Calling methods: myInstance:doThis_withThis_andThat(this, this, that)
   -- Colons in selectors are converted to underscores (last one being optional)
-- Creating blocks: objc.createBlock(myFunction, returnType, argTypes)
   -- returnType: An encoded type specifying what the block should return (Consult https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html for reference)
   -- argTypes: An array of encoded types specifying the argument types the block expects
   -- Both return and argument types default to void if none are passed

-- Demo:
-- objc = require("objc")
-- objc.loadFramework("AppKit")
-- pool = objc.NSAutoreleasePool:new()
-- objc.NSSpeechSynthesizer:new():startSpeakingString(objc.NSStr("Hello From Lua!"))
-- os.execute("sleep "..2)

local ffi = require("ffi")

local objc = {
	debug = false,
	relaxedSyntax = true, -- Allows you to omit trailing underscores when calling methods at the expense of some performance.
	frameworkSearchPaths = {
		"/System/Library/Frameworks/%s.framework/%s",
		"/Library/Frameworks/%s.framework/%s",
		"~/Library/Frameworks/%s.framework/%s"
	}
}

local function _log(...)
	if objc.debug == true then
		args = {...}
		for i=1, #args do
			args[i] = tostring(args[i])
		end
		io.stderr:write("[objc] "..table.concat(args, ",   ").."\n")
	end
end

if ffi.abi("64bit") then
	ffi.cdef([[
	typedef double CGFloat;
	typedef long NSInteger;
	typedef unsigned long NSUInteger;
	]])
else
	ffi.cdef([[
	typedef float CGFloat;
	typedef int NSInteger;
	typedef unsigned int NSUInteger;
	]])
end

ffi.cdef([[
typedef struct objc_class *Class;
struct objc_class { Class isa; };
struct objc_object { Class isa; };
typedef struct objc_object *id;

typedef struct objc_selector *SEL;
typedef id (*IMP)(id, SEL, ...);
typedef signed char BOOL;
typedef struct objc_method *Method;
struct objc_method_description { SEL name; char *types; };

id objc_msgSend(id theReceiver, SEL theSelector, ...);

Class objc_getClass(const char *name);
const char *class_getName(Class cls);
Method class_getClassMethod(Class aClass, SEL aSelector);
IMP class_getMethodImplementation(Class cls, SEL name);
Method class_getInstanceMethod(Class aClass, SEL aSelector);
Method class_getClassMethod(Class aClass, SEL aSelector);

Class object_getClass(id object);
const char *object_getClassName(id obj);

SEL method_getName(Method method);
unsigned method_getNumberOfArguments(Method method);
void method_getReturnType(Method method, char *dst, size_t dst_len);
void method_getArgumentType(Method method, unsigned int index, char *dst, size_t dst_len);
IMP method_getImplementation(Method method);

SEL sel_registerName(const char *str);
const char* sel_getName(SEL aSelector);

void free(void *ptr);
void CFRelease(id obj);

// Used to check if a file exists
int access(const char *path, int amode);

// http://clang.llvm.org/docs/Block-ABI-Apple.txt
struct __block_descriptor_1 {
	unsigned long int reserved; // NULL
	unsigned long int size; // sizeof(struct __block_literal_1)
}

struct __block_literal_1 {
	struct __block_literal_1 *isa;
	int flags;
	int reserved;
	void *invoke;
	struct __block_descriptor_1 *descriptor;
}
struct __block_literal_1 *_NSConcreteGlobalBlock;

// NSObject dependencies
typedef struct CGPoint { CGFloat x; CGFloat y; } CGPoint;
typedef struct CGSize { CGFloat width; CGFloat height; } CGSize;
typedef struct CGRect { CGPoint origin; CGSize size; } CGRect;
typedef struct CGAffineTransform { CGFloat a; CGFloat b; CGFloat c; CGFloat d; CGFloat tx; CGFloat ty; } CGAffineTransform;
typedef struct _NSRange { NSUInteger location; NSUInteger length; } NSRange;
typedef struct _NSZone NSZone;

// Opaque dependencies
struct _NSStringBuffer;
struct __CFCharacterSet;
struct __GSFont;
struct __CFString;
struct __CFDictionary;
struct __CFArray;
struct __CFAllocator;
struct _NSModalSession;
struct Object;
]])

local C = ffi.C

function objc.loadFramework(name)
	local canRead = bit.lshift(1,2)
	for i,path in pairs(objc.frameworkSearchPaths) do
		path = path:format(name,name)
		if C.access(path, canRead) == 0 then
			return ffi.load(path, true)
		end
	end
	error("Error! Framework '"..name.."' not found.")
end

if ffi.arch ~= "arm" then
	ffi.load("/usr/lib/libobjc.A.dylib", true)
	objc.loadFramework("CoreFoundation")
	objc.loadFramework("Foundation")
end

objc.CGPoint = ffi.typeof("CGPoint")
objc.CGSize = ffi.typeof("CGSize")
objc.CGRect = ffi.typeof("CGRect")
objc.CGAffineTransform = ffi.typeof("CGAffineTransform")
objc.NSRange = ffi.typeof("NSRange")

setmetatable(objc, {
	__index = function(t, key)
		local ret = C.objc_getClass(key)
		if ret == nil then
			return nil
		end
		return ret
	end
})

function objc.selToStr(sel)
	return ffi.string(ffi.C.sel_getName(sel))
end
ffi.metatype("struct objc_selector", { __tostring = objc.selToStr })

local SEL=function(str)
	return ffi.C.sel_registerName(str)
end
objc.SEL = SEL

-- Stores references to IMP(method) wrappers
local _classMethodCache = {}
local _instanceMethodCache = {}

-- Takes a single ObjC type encoded, and converts it to a C type specifier
local _typeEncodings = {
	["@"] = "id", ["#"] = "Class", ["c"] = "char", ["C"] = "unsigned char",
	["s"] = "short", ["S"] = "unsigned short", ["i"] = "int", ["I"] = "unsigned int",
	["l"] = "long", ["L"] = "unsigned long", ["q"] = "long long", ["Q"] = "unsigned long long",
	["f"] = "float", ["d"] = "double", ["B"] = "BOOL", ["v"] = "void", ["^"] = "void *",
	["*"] = "char *", [":"] = "SEL", ["?"] = "void", ["{"] = "struct", ["("] = "union"
}
objc.typeEncodingToCType = function(aEncoding)
	local i = 1
	local ret = ""
	local isPtr = false

	if aEncoding:sub(i,i) == "^" then
		isPtr = true
		i = i+1
	end
	if aEncoding:sub(i,i) == "r" then
		ret = "const "
		i = i+1
	end
	-- Unused qualifiers
	aEncoding = aEncoding:gsub("^[noNRV]", "")
	
	-- Then type encodings
	local type = _typeEncodings[aEncoding:sub(i,i)]

	if type == nil then
		_log("Error! type encoding '"..aEncoding.."' is not supported")
		return nil
	elseif type == "union" then
		local name = aEncoding:sub(aEncoding:find("[^=^(]+"))
		if name == "?" then
			_log("Error! Anonymous unions not supported: "..aEncoding)
			return nil
		end
		ret = string.format("%s %s %s", ret, type, name)
	elseif type == "struct" then
		local name = aEncoding:sub(aEncoding:find('[^=^{]+'))
		if name == "?" then
			_log("Error! Anonymous structs not supported "..aEncoding)
			return nil
		end
		ret = string.format("%s %s %s", ret, type, name)
	else
		ret = string.format("%s %s", ret, type)
	end
	
	if isPtr == true then
		ret = ret.."*"
	end
	return ret
end

-- Creates a C function signature string for the given types
function objc.impSignatureForTypeEncoding(retType, argTypes)
	retType = retType or "v"
	argTypes = argTypes or {}
	
	retType = objc.typeEncodingToCType(retType)
	if retType == nil then
		return nil
	end
	local signature = retType.." (*)("

	for i,type in pairs(argTypes) do
		type = objc.typeEncodingToCType(type)
		if type == nil then
			return nil
		end
		if i < #argTypes then
			type = type..","
		end
		signature = signature..type
	end

	return signature..")"
end

-- Creates a C function signature string for the IMP of a method
function objc.impSignatureForMethod(method)
	local typePtr = ffi.new("char[512]")

	C.method_getReturnType(method, typePtr, 512)
	local retType = ffi.string(typePtr)

	local argCount = C.method_getNumberOfArguments(method)
	local argTypes = {}
	for j=0, argCount-1 do
		C.method_getArgumentType(method, j, typePtr, 512);
		table.insert(argTypes, ffi.string(typePtr))
	end

	return objc.impSignatureForTypeEncoding(retType, argTypes)
end

-- Returns the IMP of a method correctly typecast
local function _readMethod(method)
	local impTypeStr = objc.impSignatureForMethod(method)
	if impTypeStr == nil then
		return nil
	end
	_log("Reading method:", objc.selToStr(C.method_getName(method)), impTypeStr)

	local imp = C.method_getImplementation(method);
	return ffi.cast(impTypeStr, imp)
end

-- Convenience functions

function objc.objToStr(aObj) -- Automatically called with tostring(object)
	local str = ffi.cast("id", aObj):description():UTF8String()
	return ffi.string(str)
end

-- Converts a lua type to an objc object
function objc.Obj(v)
	if type(v) == "number" then
		return objc.NSNum(v)
	elseif type(v) == "string" then
		return objc.NSStr(v)
	elseif type(v) == "table" then
		if #v == 0 then
			return objc.NSDic(v)
		else
			return objc.NSArr(v)
		end
	elseif type(v) == "cdata" then
		return ffi.cast("id", v)
	end
	return nil
end
function objc.NSStr(aStr)
	return objc.NSString:stringWithUTF8String_(aStr)
end
function objc.NSNum(aNum)
	return NSNumber:numberWithDouble(aNum)
end
function objc.NSArr(aTable)
	local ret = NSMutableArray:array()
	for i,v in ipairs(aTable) do
		ret:addObject(objc.Obj(v))
	end
	return ret
end
function objc.NSDic(aTable)
	local ret = NSMutableDictionary:dictionary()
	for k,v in pairs(aTable) do
		ret:setObject_forKey(objc.Obj(v), objc.Obj(k))
	end
	return ret
end

-- Method calls

local _emptyTable = {} -- Keep an empty table around so we don't have to create a new one every time a method is called
ffi.metatype("struct objc_class", {
	__call = function(self)
		error("[objc] Classes are not callable\n"..debug.traceback())
	end,
	__tostring = objc.objToStr,
	__index = function(unused,selArg)
		return function(self, ...)
			if self == nil then
				error("[objc] Self not passed. You probably used dot instead of colon syntax\n"..debug.traceback())
				return nil
			end

			if objc.relaxedSyntax == true then
				-- Append missing underscores to the selector
				selArg = selArg .. ("_"):rep(#{...} - #selArg:gsub("[^_]", ""))
			end

			-- First try the cache
			local className = ffi.string(C.class_getName(self))
			local cached = (_classMethodCache[className] or _emptyTable)[selArg]
			if cached ~= nil then
				return cached(self, ...)
			end

			-- Else, load the method
			local selStr = selArg:gsub("_", ":")
			
			if objc.debug then _log("Calling +["..className.." "..selStr.."]") end

			local method
			local methodDesc = C.class_getClassMethod(self, SEL(selStr))
			if methodDesc ~= nil then
				method = _readMethod(methodDesc)
			else
				method = C.objc_msgSend
			end

			-- Cache the calling block and execute it
			_classMethodCache[className] = _classMethodCache[className] or {}
			_classMethodCache[className][selArg] = function(receiver, ...)
				local success, ret = pcall(method, ffi.cast("id", receiver), SEL(selStr), ...)
				if success == false then
					error(ret.."\n"..debug.traceback())
				end

				if ffi.istype("struct objc_object*", ret) and ret ~= nil then
					if (selStr:sub(1,5) ~= "alloc" and selStr ~= "new")  then
						ret:retain()
					end
					if selStr:sub(1,5) ~= "alloc" then
						ret = ffi.gc(ret, C.CFRelease)
					end
				end
				return ret
			end
			return _classMethodCache[className][selArg](self, ...)
		end
	end
})


local function _objectCall(self)
	error("[objc] Objects are not callable\n"..debug.traceback())
end

-- Returns a function that takes an object reference and the arguments to pass to the method.
function objc.getInstanceMethodCaller(self,selArg, ...)
	return function(self, ...)
		if self == nil then
			error("[objc] Self not passed. You probably used dot instead of colon syntax")
			return nil
		end

		self = ffi.cast("id", self)
		-- First try the cache
		if objc.relaxedSyntax == true then
			-- Append missing underscores to the selector
			selArg = selArg .. ("_"):rep(#{...} - #selArg:gsub("[^_]", ""))
		end
		local className = ffi.string(C.object_getClassName(self))
		local cached = (_instanceMethodCache[className] or _emptyTable)[selArg]
		if cached ~= nil then
			return cached(self, ...)
		end

		-- Else, load the method
		local selStr = selArg:gsub("_", ":")
		_log("Calling -["..className.." "..selStr.."]")

		local method
		local methodDesc = C.class_getInstanceMethod(C.object_getClass(self), SEL(selStr))
		if methodDesc ~= nil then
			method = _readMethod(methodDesc)
		else
			method = C.objc_msgSend
		end

		-- Cache the calling block and executeit
		_instanceMethodCache[className] = _instanceMethodCache[className] or {}
		_instanceMethodCache[className][selArg] = function(receiver, ...)
			local success, ret = pcall(method, receiver, SEL(selStr), ...)
			if success == false then
				error(ret.."\n"..debug.traceback())
			end

			if ffi.istype("struct objc_object*", ret) and ret ~= nil and not (selStr == "retain" or selStr == "release") then
				-- Retain objects that need to be retained
				if not (selStr:sub(1,4) == "init" or selStr:sub(1,4) == "copy" or selStr:sub(1,11) == "mutableCopy") then
					ret:retain()
				end
				ret = ffi.gc(ret, C.CFRelease)
			end
			return ret
		end
		return _instanceMethodCache[className][selArg](self, ...)
	end
end

ffi.metatype("struct objc_object", {
	__call = _objectCall,
	__tostring = objc.objToStr,
	__index = objc.getInstanceMethodCaller
})

-- Blocks

local _sharedBlockDescriptor = ffi.new("struct __block_descriptor_1")
_sharedBlockDescriptor.reserved = 0;
_sharedBlockDescriptor.size = ffi.sizeof("struct __block_literal_1")

-- Wraps a function to be used with a block
local function _createBlockWrapper(lambda, retType, argTypes)
	-- Build a function definition string to cast to
	retType = retType or "v"
	argTypes = argTypes or {}
	table.insert(argTypes, 1, "^v")

	local funTypeStr = objc.impSignatureForTypeEncoding(retType, argTypes)
	_log("Created block with signature:", funTypeStr)

	ret = function(theBlock, ...)
		return lambda(...)
	end
	return ffi.cast(funTypeStr, ret)
end

-- Creates a block and returns it typecast to 'id'
function objc.createBlock(lambda, retType, argTypes)
	if not lambda then
		return nil
	end
	local block = ffi.new("struct __block_literal_1")
	block.isa = C._NSConcreteGlobalBlock
	block.flags = bit.lshift(1, 29)
	block.reserved = 0
	block.invoke = ffi.cast("void*", _createBlockWrapper(lambda, retType, argTypes))
	block.descriptor = _sharedBlockDescriptor

	return ffi.cast("id", block)
end

return objc

