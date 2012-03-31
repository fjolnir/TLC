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
]])

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

