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

local ffi = require("ffi")

local objc = {
	debug = false,
	 -- Allows you to omit trailing underscores when calling methods at the expense of some performance.
	relaxedSyntax = true,
	-- Calls objc_msgSend if a method implementation is not found (This throws an exception on failure)
	fallbackOnMsgSend = false,
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

ffi.cdef[[
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
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);

Class objc_getClass(const char *name);
const char *class_getName(Class cls);
Method class_getClassMethod(Class aClass, SEL aSelector);
IMP class_getMethodImplementation(Class cls, SEL name);
Method class_getInstanceMethod(Class aClass, SEL aSelector);
Method class_getClassMethod(Class aClass, SEL aSelector);
BOOL class_respondsToSelector(Class cls, SEL sel);
Class class_getSuperclass(Class cls);
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);

Class object_getClass(id object);
const char *object_getClassName(id obj);

SEL method_getName(Method method);
unsigned method_getNumberOfArguments(Method method);
void method_getReturnType(Method method, char *dst, size_t dst_len);
void method_getArgumentType(Method method, unsigned int index, char *dst, size_t dst_len);
IMP method_getImplementation(Method method);
const char *method_getTypeEncoding(Method method);
void method_exchangeImplementations(Method m1, Method m2);


SEL sel_registerName(const char *str);
const char* sel_getName(SEL aSelector);

void free(void *ptr);
void CFRelease(id obj);

// Used to check if a file exists
int access(const char *path, int amode);
]]

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

setmetatable(objc, {
	__index = function(t, key)
		local ret = C.objc_getClass(key)
		if ret == nil then
			return nil
		end
		t[key] = ret
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
local _classMethodCache = {}; objc.classMethodCache = _classMethodCache
local _instanceMethodCache = {}; objc.instanceMethodCache = _instanceMethodCache

local _classNameCache = setmetatable({}, { __mode = "k" })
-- We cache imp types both for performance, and so we don't fill the ffi type table with duplicates
local _impTypeCache = setmetatable({}, {__index=function(t,impSig)
	t[impSig] = ffi.typeof(impSig)
	return t[impSig]
end})
local _idType = ffi.typeof("struct objc_object*")


-- Parses an ObjC type encoding string
local function _parseEncoding(str)
    local last = 1
    local ret = {}
    local i = 1
    local braceDepth = 0
    local parenDepth = 0
	local inQuotes = false
	local curName, curType
    while i <= #str do
		if     str:sub(i,i) == "{" then braceDepth = braceDepth + 1
		elseif str:sub(i,i) == "}" then braceDepth = braceDepth - 1
		elseif str:sub(i,i) == "(" then braceDepth = parenDepth + 1
		elseif str:sub(i,i) == ")" then parenDepth = parenDepth - 1
		elseif str:sub(i,i) == '"' then inQuotes = not inQuotes; i = i+1 end

		if braceDepth > 0 or parenDepth > 0 then
			curType = curType .. str:sub(i,i)
		elseif inQuotes == true then
			curName = curName .. str:sub(i,i)
		end
        if str:sub(i, i) == '"' and parenDepth == 0 and braceDepth == 0 then
            local str = str:sub(last, i-1)
            if #str > 0 then
                table.insert(ret, str)
            end
            last = i+1
        end
        i = i + 1
    end
    -- Concat the rest of the string
    if last < #str+1 then
        table.insert(ret, str:sub(last))
    end
    return ret
end

-- Parses a struct encoding like {CGPoint="x"d"y"d}
local _definedStructs = setmetatable({}, { __mode = "kv" })
local function _parseStructOrUnionEncoding(encoded, isUnion)
	local pat = "{([^=}]+)[=}]"
	local keyword = "struct"
	if isUnion == true then
		pat = '%(([^=%)]+)[=%)]'
		keyword = "union"
	end

	local unused, nameEnd, name = encoded:find(pat)
	local typeEnc = encoded:sub(nameEnd+1, #encoded-1)
	local fields = _split(typeEnc, '"')
	print("-------", name, #fields, typeEnc)
	
	if name == "?" and #fields <= 1 then
		print("ANON WITH A BEEF!")
		print(name, nameEnd, typeEnc)
		for k,v in pairs(fields) do print(k,v) end
	end
	if #fields <= 1 then return keyword.." "..name end
	
	local typeStr = _definedStructs[name]
	-- If the struct has been defined already, or does not have field name information, just return the name
	if typeStr ~= nil then
		return keyword.." "..name
	end

	if name == "?" then name = "" end -- ? means an anonymous struct/union
	local typeStr = keyword.." "..name.." { "
	
	for i=1,#fields,2 do
		if fields[i] ~= nil and fields[i+1] ~= nil then
			local type = objc.typeEncodingToCType(fields[i+1])
			if type == nil then
				if objc.debug == true then _log("Unsupported type in "..keyword.." "..name..": "..fields[i+1]) end
				return nil
			end
			typeStr = typeStr .. type .." ".. fields[i] ..";"
		end
	end
	typeStr = typeStr .." }"
	print(typeStr)
	if #name > 0 then
		_definedStructs[name] = typeStr
		ffi.cdef(typeStr)
		return keyword.." "..name -- If the struct has a name, then we don't want to redefine it
	else
		print("Anon-> ", typeStr)
		return typeStr
	end
end

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
		local unionType = _parseStructOrUnionEncoding(aEncoding:sub(i), true)
		if unionType == nil then
			_log("Error! type encoding '"..aEncoding.."' is not supported")
			return nil
		end
		ret = ret .. unionType


		--local name = aEncoding:sub(aEncoding:find("[^=^(]+"))
		--if name == "?" then
			--_log("Error! Anonymous unions not supported: "..aEncoding)
			--return nil
		--end
		--ret = string.format("%s %s %s", ret, type, name)
	elseif type == "struct" then
		local structType = _parseStructOrUnionEncoding(aEncoding:sub(i), false)
		if structType == nil then
			_log("Error! type encoding '"..aEncoding.."' is not supported")
			return nil
		end
		ret = ret .. structType
	else
		ret = string.format("%s %s", ret, type)
	end
	
	if isPtr == true then
		ret = ret.."*"
	end
	return ret
end

-- Creates a C function signature string for the given types
function objc.impSignatureForTypeEncoding(retType, argTypes, name)
	name = name or "*" -- Default to an anonymous function pointer
	retType = retType or "v"
	argTypes = argTypes or {}
	
	retType = objc.typeEncodingToCType(retType)
	if retType == nil then
		return nil
	end
	local signature = retType.." ("..name..")("

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
function objc.impForMethod(method)
	local impTypeStr = objc.impSignatureForMethod(method)
	if impTypeStr == nil then
		return nil
	end
	_log("Reading method:", objc.selToStr(C.method_getName(method)), impTypeStr)

	local imp = C.method_getImplementation(method);
	return ffi.cast(_impTypeCache[impTypeStr], imp)
end

-- Convenience functions

function objc.objToStr(aObj) -- Automatically called with tostring(object)
	if aObj == nil then
		return "nil"
	end
	local str = aObj:description():UTF8String()
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
		return ffi.cast(_idType, v)
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

-- Takes a selector string (with colons replaced by underscores) and returns the number of arguments)
function _argCountForSelArg(selArg)
	local counting = false
	local count = 0
	for i=1,#selArg do
		if counting == false then
			counting = (selArg:sub(i,i) ~= "_")
		elseif selArg:sub(i,i) == "_" then
			count = count + 1
		end
	end
	return count
end

-- Replaces all underscores except the ones at the beginning of the string by colons
function _selectorFromSelArg(selArg)
	local replacing = false
	local count = 0
	for i=1,#selArg do
		if replacing == false then
			replacing = (selArg:sub(i,i) ~= "_")
		elseif selArg:sub(i,i) == "_" then
			selArg = table.concat{selArg:sub(1,i-1), ":", selArg:sub(i+1)}
		end
	end
	return selArg
end

-- Used as a __newindex metamethod
local function _setter(self, key, value)
	local selector = "set"..key:sub(1,1):upper()..key:sub(2)
	if C.class_respondsToSelector(C.object_getClass(self), SEL(selector..":")) == 1 then
		return self[selector](self, value)
	elseif objc.fallbackOnMsgSend == true then
		return self:setValue_forKey_(Obj(value), NSStr(key))
    else
        print("[objc] Key "..key.." not found")
	end
end

local function _getter(self, key)
	local idx = tonumber(key)
	if idx ~= nil then
		return self:objectAtIndex(idx)
	else
		if C.class_respondsToSelector(C.object_getClass(self), SEL(key)) == 1 then
			return self[key](self)
		elseif objc.fallbackOnMsgSend == true then
			return self:valueForKey_(NSStr(key))
        else
            print("[objc] Key "..key.." not found")
		end
	end
end


local _emptyTable = {} -- Keep an empty table around so we don't have to create a new one every time a method is called
ffi.metatype("struct objc_class", {
	__call = function(self)
		error("[objc] Classes are not callable\n"..debug.traceback())
	end,
	__tostring = objc.objToStr,
	__index = function(realSelf,selArg)
		return function(self, ...)
			if self ~= realSelf then
				error("[objc] Self not passed. You probably used dot instead of colon syntax\n"..debug.traceback())
				return nil
			end

			if objc.relaxedSyntax == true then
				-- Append missing underscores to the selector
				selArg = selArg .. ("_"):rep(select("#", ...) - _argCountForSelArg(selArg))
			end

			-- First try the cache
			local cached = (_classMethodCache[_classNameCache[self]] or _emptyTable)[selArg]
			if cached ~= nil then
				return cached(self, ...)
			end

			-- Else, load the method
			local selStr = _selectorFromSelArg(selArg)

			local method
			local methodDesc = C.class_getClassMethod(self, SEL(selStr))
			if methodDesc ~= nil then
				method = objc.impForMethod(methodDesc)
			elseif objc.fallbackOnMsgSend == true then
			imp = C.objc_msgSend
			else
				print("[objc] Method "..selStr.." not found")
				return nil
			end

			-- Cache the calling block and execute it
			_classNameCache[self] = _classNameCache[self] or ffi.string(C.class_getName(self))
			local className = _classNameCache[self]
			_classMethodCache[className] = _classMethodCache[className] or {}
			_classMethodCache[className][selArg] = function(receiver, ...)
				local success, ret = pcall(method, ffi.cast(_idType, receiver), SEL(selStr), ...)
				if success == false then
					error(ret.."\n"..debug.traceback())
				end

				if ffi.istype(_idType, ret) and ret ~= nil then
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
	end,
	__newindex = _setter
})

-- Returns a function that takes an object reference and the arguments to pass to the method.
function objc.getInstanceMethodCaller(realSelf,selArg)
	return function(self, ...)
		if self ~= realSelf then
			error("[objc] Self not passed. You probably used dot instead of colon syntax")
			return nil
		end

		-- First try the cache
		if objc.relaxedSyntax == true then
			-- Append missing underscores to the selector
			selArg = selArg .. ("_"):rep(select("#", ...) - _argCountForSelArg(selArg))
		end

		local cached = (_instanceMethodCache[_classNameCache[self] ] or _emptyTable)[selArg]
		if cached ~= nil then
			return cached(self, ...)
		end

		-- Else, load the method
		local selStr = _selectorFromSelArg(selArg)

		local imp
		local methodDesc = C.class_getInstanceMethod(C.object_getClass(self), SEL(selStr))
		if methodDesc ~= nil then
			imp = objc.impForMethod(methodDesc)
		elseif objc.fallbackOnMsgSend == true then
			imp = C.objc_msgSend
		else
			print("[objc] Method "..selStr.." not found")
			return nil
		end

		-- Cache the calling block and execute it
		_classNameCache[self] = _classNameCache[self] or ffi.string(C.object_getClassName(self))
		local className = _classNameCache[self]
		_instanceMethodCache[className] = _instanceMethodCache[className] or {}
		_instanceMethodCache[className][selArg] = function(receiver, ...)
			local success, ret = pcall(imp, receiver, SEL(selStr), ...)
			if success == false then
				error(ret.."\n"..debug.traceback())
			end

			if ffi.istype(_idType, ret) and ret ~= nil and not (selStr == "retain" or selStr == "release") then
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
	__call = _getter, -- Called using aObject[[key]]
	__tostring = objc.objToStr,
	__index = objc.getInstanceMethodCaller,
	__newindex = _setter
})



--
-- Introspection and class extension

-- Creates and returns a new subclass of superclass (or if superclass is nil, a new root class)
function objc.createClass(superclass, className)
	local class = C.objc_allocateClassPair(superclass, className, 0)
	C.objc_registerClassPair(class)
	return class
end

-- Calls the superclass's implementation of a method
function objc.callSuper(self, selector, ...)
	local superClass = C.class_getSuperclass(C.object_getClass(self))
	local method = C.class_getInstanceMethod(superClass, selector)
	return objc.impForMethod(method)(self, selector, ...)
end

-- Swaps two methods of a class (They must have the same type signature)
function objc.swizzle(class, origSel, newSel)
	local origMethod = C.class_getInstanceMethod(class, origSel)
	local newMethod = C.class_getInstanceMethod(class, newSel)
	if C.class_addMethod(class, origSel, C.method_getImplementation(newMethod), C.method_getTypeEncoding(newMethod)) == true then
		C.class_replaceMethod(class, newSel, C.method_getImplementation(origMethod), C.method_getTypeEncoding(origMethod));
	else
		C.method_exchangeImplementations(origMethod, newMethod)
	end
end

-- Adds a function as a method to the given class
-- If the method already exists, it is renamed to __{selector}
-- The function must have self (id), and selector (SEL) as it's first two arguments
-- Defaults are to return void and to take an object and a selector
function objc.addMethod(class, selector, lambda, retType, argTypes)
	retType = retType or "v"
	argTypes = argTypes or {"@",":"}
	local signature = objc.impSignatureForTypeEncoding(retType, argTypes)
	local imp = ffi.cast(signature, lambda)
	imp = ffi.cast("IMP", imp)

	-- If one exists, the existing/super method will be renamed to this selector
	local renamedSel = objc.SEL("__"..objc.selToStr(selector))
	
	local couldAddMethod = C.class_addMethod(class, selector, imp, retType..table.concat(argTypes))
	if couldAddMethod == 0 then
		-- If the method already exists, we just add the new method as old{selector} and swizzle them
		if C.class_addMethod(class, renamedSel, imp, retType..table.concat(argTypes)) == 1 then
			objc.swizzle(class, selector, renamedSel)
		else
			error("Couldn't replace method")
		end
	else
		local superClass = C.class_getSuperclass(class)
		local superMethod = C.class_getInstanceMethod(superClass, selector)
		if superMethod ~= nil then
			C.class_addMethod(class, renamedSel, C.method_getImplementation(superMethod), C.method_getTypeEncoding(superMethod))
		end
	end
end


--
-- Blocks

ffi.cdef[[
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
]]

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

	ret = function(theBlock, ...)
		return lambda(...)
	end
	return ffi.cast(funTypeStr, ret)
end

-- Creates a block and returns it typecast to 'id'
local _blockType = ffi.typeof("struct __block_literal_1")
function objc.createBlock(lambda, retType, argTypes)
	if not lambda then
		return nil
	end

	local block = _blockType()
	block.isa = C._NSConcreteGlobalBlock
	block.flags = bit.lshift(1, 29)
	block.reserved = 0
	block.invoke = ffi.cast("void*", _createBlockWrapper(lambda, retType, argTypes))
	block.descriptor = _sharedBlockDescriptor

	return ffi.cast("id", block)
end

return objc
