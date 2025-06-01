if not FaeLib.Ext.DebugPlus then
    assert(SMODS.load_file("init.lua", "faelib"))()

    local dp_loaded, dpAPI = pcall(require, "debugplus-api")
    local cmds = {}
local help_resp = [[
FaeLib - Modding Utility for Balatro
\t Commands:
]]

    cmds.help = function(args)
        print(help_resp)
    end


    if dp_loaded and dpAPI.isVersionCompatible(1) then -- Make sure DebugPlus is available and compatible
        FaeLib.Ext.DebugPlus = dpAPI.registerID("FaeLib")
        FaeLib.Ext.DebugPlus.addCommand({
            name = "faelib",
            shortDesc = "FaeLib API",
            desc = "Various functions from the FaeLib API exposed to DebugPlus' Console",
            exec = function (args, rawArgs, dp)
                if #args > 0 then
                    local subcmd = args[1]
                    args[1] = nil
                    local subcmd_args = args
                    if (cmds[subcmd]) then
                        cmds[subcmd](subcmd_args)
                    else
                        FaeLib.print("Unknown command: " .. subcmd)
                    end
                else
                    return cmds.help({})
                end
            end
        })
    end
end