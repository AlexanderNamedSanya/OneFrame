GroupFramePlus = { name = "GroupFramePlus", version = "1.2.4", strings = {} }
local A = GroupFramePlus
function A:T(key)
    return self.strings[key] or key
end
