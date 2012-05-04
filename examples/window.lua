-- Ported from LuaCocoa's MinimalAppKit example
-- Creates a quit menu item and a window. Very minimal indeed.

package.path = package.path .. ';../?/init.lua'
local objc = require("objc")
local bs = require("objc.BridgeSupport")
bs.loadFramework("Foundation", true)
bs.loadFramework("AppKit", true)
bs.loadFramework("ApplicationServices")
setmetatable(_G, {__index=objc})

local NSApp = NSApplication:sharedApplication()
NSApp:setActivationPolicy(NSApplicationActivationPolicyRegular)

-- Create the menubar
local menuBar = NSMenu:alloc():init()
local appMenuItem = NSMenuItem:alloc():init()
menuBar:addItem(appMenuItem)
NSApp:setMainMenu(menuBar)

-- Create the App menu
local appMenu = NSMenu:alloc():init()
local appName = NSProcessInfo:processInfo():processName()
local quitTitle = "Quit " .. tostring(appName)
quitMenuItem = NSMenuItem:alloc():initWithTitle_action_keyEquivalent(NSStr(quitTitle), SEL("terminate:"), NSStr("q"))
appMenu:addItem(quitMenuItem)
appMenuItem:setSubmenu(appMenu)

-- Create a window
local mainWindow = NSWindow:alloc():initWithContentRect_styleMask_backing_defer(CGRect(CGPoint(0, 0), CGSize(200, 200)), NSTitledWindowMask, NSBackingStoreBuffered, false)
mainWindow:cascadeTopLeftFromPoint(CGPoint(20,20))
mainWindow:setTitle(appName)
mainWindow:makeKeyAndOrderFront(NSApp)

-- Bring the app out
NSApp:activateIgnoringOtherApps(true)
NSApp:run()



