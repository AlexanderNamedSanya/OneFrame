GroupFramePlus = { name = "GroupFramePlus", version = "1.5.2", strings = {} }
local A = GroupFramePlus
function A:T(key)
    return self.strings[key] or key
end
