
local flagMasks = {
  activeFlag                    = 1 << 0,
  btnState                      = 1 << 7,
  cmdKey                        = 1 << 8,
  shiftKey                      = 1 << 9,
  alphaLock                     = 1 << 10,
  optionKey                     = 1 << 11,
  controlKey                    = 1 << 12,
  rightShiftKey                 = 1 << 13,
  rightOptionKey                = 1 << 14,
  rightControlKey               = 1 << 15,

  -- I think -- we can't set it, but I see this on keys that I also see this set for when using hs.eventtap
  functionKey                   = 1 << 17,
}

for i, v in ipairs(_xtras.hotkeys()) do
  local hotkey = rawget(hs.keycodes.map, v.kHISymbolicHotKeyCode) or ("{" .. tostring(v.kHISymbolicHotKeyCode) .. "}")
  local mods, mask = {}, v.kHISymbolicHotKeyModifiers
  for k2, v2 in pairs(flagMasks) do
      if (mask & v2) == v2 then
          mask = mask - v2
          table.insert(mods, k2)
      end
  end
  if mask ~= 0 then table.insert(mods, mask) end
  print(string.format("%s %-12s %s", (v.kHISymbolicHotKeyEnabled and "+" or "-"), hotkey, finspect(mods)))
end
