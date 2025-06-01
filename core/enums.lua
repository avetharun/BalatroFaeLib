if not FaeLib.Enums then
    if not FaeLib.Enum then
        FaeLib.Enum = assert(SMODS.load_file("core/lib/enum.lua", "faelib"))()
    end
    FaeLib.Enums = FaeLib.Enums or {}
    FaeLib.Enums.DebugState = FaeLib.Enum[[
        Enabled
        Disabled
    ]]

end
return FaeLib.Enums