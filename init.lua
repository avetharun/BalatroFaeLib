if not FaeLib then
    if not class then
        assert(SMODS.load_file("core/lib/class_oop.lua", "faelib"))() -- We use the class-oop API extensively, so we include it globally.
    end
    G.P_CENTERS = G.P_CENTERS or {}
    FaeLib = FaeLib or {}
    if not FaeLib.Enum then
        FaeLib.Enum = assert(SMODS.load_file("core/lib/enum.lua", "faelib"))()
    end
    FaeLib.V = FaeLib.V or {}
    FaeLib.APIs = FaeLib.APIs or {}
    FaeLib.Ext = FaeLib.Ext or {}
    FaeLib.Enums = assert(SMODS.load_file("core/enums.lua", "faelib"))()
    FaeLib.Builtin = FaeLib.Builtin or {}
    FaeLib.Builtin.Events = FaeLib.Builtin.Events or {}
    FaeLib.Builtin.Badges = FaeLib.Builtin.Badges or {}
    FaeLib.print = function (message, severity)
        if FaeLib.DebugState == FaeLib.Enums.DebugState.Disabled then
            return
        end
        if severity == nil then
            print("[FaeLib] " .. message)
            return
        end
        print("[FaeLib] " .."<"..severity..">" .. message)
    end
    local FaeLib_Tags = {

    }
    class 'FaeLib.Tag' : template "T" {
        constructor = function (self, id, elements)
            self.elements = elements or {}
            if not id then error("Missing ID for tag!", 2) end
            self.id = id
            FaeLib_Tags[id] = self
        end,
        equals = function (self, other)
            return instanceOf(other, "FaeLib.Tag") and self.id == other.id
        end,
        keys = function(self)
            return self.elements or {}
        end,
        print_keys = function(self)
            for index, value in ipairs(self:keys()) do
                FaeLib.print(value)
            end
        end,
        contains = function (self, ty)
            local id_ = nil
            if type(ty) == "string" then
                id_ = ty
            elseif type(ty) == "table" then
                id_ = ty.key or ty.id
            end
            if (type(getmetatable(ty).__getid) == "function") then
                id_ = getmetatable(ty).__getid()
            end
            if id_ == nil then
                error("Expected a valid key either in metatable __getid(), or as property \"key\" or \"id\"", 2)
            end
            for _, value in ipairs(self:keys()) do
                
                    
                
                if type(value) == "string" and value:sub(1, 1) == "#" and ty:sub(1,1) ~= "#" then
                    local tag_id = value:sub(2)
                    local tag = FaeLib_Tags[tag_id]
                    if tag and tag.contains then
                        if tag:contains(id_) then
                            return true
                        end
                    end
                else
                    if value == id_ then
                        return true
                    end
                end
                if value == id_ then
                    return true
                end
            end
            return false
        end,
        add = function (self, element, id)
            local id_ = nil
            if type(element) == "string" then
                id_ = element
            elseif type(element) == "table" then
                id_ = id or element.key or element.id
            end
            if (type(getmetatable(element).__getid) == "function") then
                id_ = getmetatable(element).__getid()
            end
            if id_ == nil then
                error("Expected a valid key either in metatable __getid(), or as property \"key\" or \"id\"", 2)
            end
            if (self:contains(id_)) then
                return
            end
            self.elements[#self.elements+1] = id_
        end
    }
    FaeLib.Tags = FaeLib.Tags or {}
    FaeLib.Tags.Common = FaeLib.Tags.Common or {}

    class 'FaeLib.Tooltip' {
        constructor = function(self, key, title, text)
            self.title = title
            self.text = text
            self.key = key
            self:update()
        end,
        setText = function(self, text)
            self.text = text
            self:update()
        end,
        update = function (self)
            G.localization.descriptions["Other"][self.key.."_tooltip"]= {name=self.title, text=self.text or {"test 123"}}
            G.P_CENTERS[self.key.."_tooltip"] = {set = "Other", key = self.key .. "_tooltip", vars = {}}
        end
    }
end