_G.maxpower = 130

local old
old = hookmetamethod(game, "__newindex", newcclosure(function(self, idx, val)
    if not checkcaller() and self.Name == "HitBox" and idx == "Velocity" and self.Parent and self.Parent.Name == "ShotPutBall" then
        if typeof(val) == "Vector3" then
            local dir = val.Unit
            return old(self, idx, dir * _G.maxpower)
        end
    end
    return old(self, idx, val)
end))
