GroupFramePlus = { name = "GroupFramePlus", version = "1.5.1", strings = {} }
local A = GroupFramePlus
function A:T(key)
    return self.strings[key] or key
end
