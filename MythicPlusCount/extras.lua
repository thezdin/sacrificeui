-- MythicPlusCount - Extras Framework
-- Registry for optional features that can be enabled/disabled.
-- Each extra registers itself and provides an Init + BuildTab callback.
local ADDON_NAME, NS = ...
local MPC = NS.MPC

local Extras = {
    registry = {},   -- { [key] = { key, name, description, Init, BuildTab } }
    order = {},      -- ordered list of keys for display
}
MPC.Extras = Extras

function Extras:Register(key, definition)
    definition.key = key
    self.registry[key] = definition
    self.order[#self.order + 1] = key
end

function Extras:IsEnabled(key)
    if not MPC.db or not MPC.db.extras then return false end
    local settings = MPC.db.extras[key]
    return settings and settings.enabled
end

function Extras:SetEnabled(key, enabled)
    if not MPC.db then return end
    if not MPC.db.extras then MPC.db.extras = {} end
    if not MPC.db.extras[key] then MPC.db.extras[key] = {} end
    MPC.db.extras[key].enabled = enabled

    local def = self.registry[key]
    if enabled and def and def.Init then
        def:Init()
    end
end

function Extras:GetSettings(key)
    if not MPC.db then return {} end
    if not MPC.db.extras then MPC.db.extras = {} end
    if not MPC.db.extras[key] then MPC.db.extras[key] = {} end
    return MPC.db.extras[key]
end

function Extras:Init()
    if not MPC.db.extras then MPC.db.extras = {} end
    for _, key in ipairs(self.order) do
        local def = self.registry[key]
        if self:IsEnabled(key) and def and def.Init then
            def:Init()
        end
    end
end
