if not FaeLib.Enums then
    if not FaeLib.Enum then
        FaeLib.Enum = assert(SMODS.load_file("core/lib/enum.lua", "faelib"))()
    end
    FaeLib.Enums = FaeLib.Enums or {}
    --- @class EnumEnabledDisabled
    --- @field Enabled integer
    --- @field Disabled integer
    FaeLib.Enums.State = FaeLib.Enum[[
        Disabled
        Enabled
    ]]
    --- @class EnumEnabledDisabled 
    FaeLib.Enums.DebugState = FaeLib.Enums.State

end
return FaeLib.Enums