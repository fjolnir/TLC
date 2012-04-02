-- Creating blocks: createBlock(myFunction, returnType, argTypes)
   -- returnType: An encoded type specifying what the block should return (Consult https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html for reference)
   -- argTypes: An array of encoded types specifying the argument types the block expects


local objc = require("objc")
local cf = require("objc.CoreFoundation")
local ffi = require("ffi")

ffi.cdef([[
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types);
void method_exchangeImplementations(Method m1, Method m2);
Method class_getInstanceMethod(Class aClass, SEL aSelector);
IMP method_getImplementation(Method method);
const char *method_getTypeEncoding(Method method);

Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);

Class class_getSuperclass(Class cls);

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
]])

local tlcutils = {}

local C = ffi.C

-- Class introspection and extension


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
	imp = ffi.cast("IMP", imp)

	-- If one exists, the existing/super method will be renamed to this selector
	local renamedSel = objc.SEL("__"..objc.selToStr(selector))
	
	local couldAddMethod = C.class_addMethod(class, selector, imp, retType..table.concat(argTypes))
	if couldAddMethod == 0 then
		-- If the method already exists, we just add the new method as old{selector} and swizzle them
		if C.class_addMethod(class, newSel, imp, retType..table.concat(argTypes)) == 1 then
			tlcutils.swizzle(class, selector, newSel)
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

	ret = function(theBlock, ...)
		print("block call")
		return lambda(...)
	end
	return ffi.cast(funTypeStr, ret)
end

-- Creates a block and returns it typecast to 'id'
local _blockType = ffi.typeof("struct __block_literal_1")
function tlcutils.createBlock(lambda, retType, argTypes)
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

return tlcutils
