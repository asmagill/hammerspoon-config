-- mymod.lua
local mod={} -- the module

local vartypes={ -- types for variables
  anumber='number',
  astring='string',
  afunctionvalue='function',
}
local argtypes={ -- types for function/method arguments
  afunction={'number','string'}
}
for fn,args in pairs(argtypes) do
  args.wrapper=function(...)
    for i=1,math.max(select('#',...),#args) do -- check arg types
      local tp = type(select(i,...) or nil)
      if tp~=args[i] then error(string.format('%s: wrong type for argument #%d: %s expected, got %s',fn,i,args[i],tp),2) end
    end
    return mod[fn](...) -- call the function
  end
end

mod.astring='this is a string'
mod.afunctionvalue=function()print('callback')end

function mod.afunction(num,str)
  print(string.rep(str,num))
end

local function get(_,k)
  local fn=argtypes[k]
  if fn then return fn.wrapper --it's a function, return a wrapper
  else return mod[k] end -- it's a value
end
local function set(_,k,v)
  if argtypes[k] then error('cannot override function '..k,2) end -- don't allow overriding functions/methods
  if type(v)~=vartypes[k] then error(string.format('wrong type for variable %s: %s expected, got %s',k,vartypes[k],type(v)),2) end -- can't set wrong type
  mod[k]=v
end

local wrap=setmetatable({},{__index=get,__newindex=set}) -- this is the table that gets exported

return wrap

-- init.lua
--mymod = wrap -- it'd be require'mymod'
--
--local function test(code)
--  local fn=load(code)
--  local ok,error=pcall(fn)
--  if ok then print(code..' -- pass')
--  else print(code..' -- '..error) end
--end
--
--test'print(mymod.astring)'
--test'mymod.astring=42'
--test'mymod.astring="hello"'
--test'mymod.anumber="hi"'
--test'mymod.afunction(1,2)'
--test'mymod.afunction("a")'
--test'mymod.afunction(42)'
--test'mymod.afunction(3,"repeat")'
