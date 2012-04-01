-- Defines metatypes for NSDictionary&NSArray (And their mutable equivalents) to make them nicer to work with
-- Currently you must explicitly cast an object to use them. (This will hopefully change in a future version)

-- Example:
-- myDict = ffi.cast("NSMutableDictionary", aObject:getDict())
-- print(myDict["aKey"])
-- myDict["anotherKey"] = "foobar"

local objc = require("objc")
local cf = require("corefoundation")
local ffi = require("ffi")

ffi.cdef([[
// (Can't cast objc_object because then I would not be able to set a new metatable)
typedef struct { Class isa; } NSString;
typedef NSString NSCFString;
typedef NSString NSMutableString;
typedef NSString NSCFMutableString;
typedef struct { Class isa; } NSArray;
typedef NSArray NSCFArray;
typedef NSArray NSMutableArray;
typedef NSArray NSCFMutableArray;
typedef NSArray __NSArrayM;
typedef struct { Class isa; } NSDictionary;
typedef NSDictionary NSCFDictionary;
typedef NSDictionary NSMutableDictionary;
typedef NSDictionary NSCFMutableDictionary;
typedef NSDictionary __NSDictionaryM;

IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
void method_exchangeImplementations(Method m1, Method m2);
Method class_getInstanceMethod(Class aClass, SEL aSelector);
IMP method_getImplementation(Method method);
const char *method_getTypeEncoding(Method method);

Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);

Class class_getSuperclass(Class cls);
]])

local tlcutils = {}

local C = ffi.C

ffi.metatype("NSDictionary", {
	__call = _objectCall,
	__tostring = objc.objToStr,
	__index = function(self, key)
		local val = cf.CFDictionaryGetValue(self, objc.Obj(key))
		if val ~= nil then
			return ffi.cast("id", val)
		else
			return objc.getInstanceMethodCaller(self, key)
		end
	end,
	__newindex = function(self, key, value)
		value = objc.Obj(value)
		cf.CFDictionarySetValue(ffi.cast("id", self), objc.Obj(key), value)
		return value
	end
})

ffi.metatype("NSArray", {
	__call = _objectCall,
	__tostring = objc.objToStr,
	__index = function(self, idx)
		if type(idx) == "number" then
			local val = cf.CFArrayGetValueAtIndex(self, ifx)
			return ffi.cast("id", val)
		else
			return objc.getInstanceMethodCaller(self, idx)
		end
	end,
	__newindex = function(self, idx, value)
		value = objc.Obj(value)
		cf.CFArraySetValueAtIndex(ffi.cast("id", self), idx, value)
		return value
	end
})

-- Swaps two methods of a class (They must have the same type signature)
function tlcutils.swizzle(class, origSel, newSel)
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
function tlcutils.addMethod(class, selector, lambda, retType, argTypes)
	retType = retType or "v"
	argTypes = argTypes or {"@",":"}
	local signature = objc.impSignatureForTypeEncoding(retType, argTypes)
	local imp = ffi.cast(signature, lambda)
	
	local couldAddMethod = C.class_addMethod(class, selector, imp, retType..table.concat(argTypes))
	if couldAddMethod == 0 then
		-- If the method already exists, we just add the new method as old{selector} and swizzle them
		local newSel = objc.SEL("__"..objc.selToStr(selector))
		if C.class_addMethod(class, newSel, imp, retType..table.concat(argTypes)) == 1 then
			tlcutils.swizzle(class, selector, newSel)
		else
			error("Couldn't replace method")
		end
	end
end

-- Creates and returns a new subclass of superclass (or if superclass is nil, a new root class)
function tlcutils.createClass(superclass, className)
	local class = C.objc_allocateClassPair(superclass, className, 0)
	C.objc_registerClassPair(class)
	return class
end

-- Calls the superclass's implementation of a method
function tlcutils.callSuper(self, selector, ...)
	local superClass = C.class_getSuperclass(C.object_getClass(self))
	local method = C.class_getInstanceMethod(superClass, selector)
	return objc.impForMethod(method)(self, selector, ...)
end

return tlcutils
