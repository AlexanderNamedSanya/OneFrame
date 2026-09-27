GroupFramePlus = { name = "GroupFramePlus", version = "1.2.0", strings = {} }
local A = GroupFramePlus
function A:T(key)
    return self.strings[key] or key
end
