--[[
    Author: https://github.com/lodsdev
    Version: 2.0.0
]]

local classes = {}
local interfaces = {}

local function table_copy(t, st)
    local newTbl = {}
    for i, v in pairs(t) do
        if (not newTbl[i]) then
            newTbl[i] = v
        end
    end
    if (st) then
        newTbl.super = st
        newTbl.baseClassName = st.__name -- make sure to copy all properties added in createClass()
        setmetatable(newTbl, { __index = newTbl.super })
    end
    return newTbl
end

local function table_implements(t, t2)
    local newTbl = {}
    for k, v in ipairs(t2) do
        t[#t+1] = v
    end
    newTbl = table_copy(t)
    return newTbl
end

local function createClass(className, structure, superClass)
    if (classes[className]) then
        error('Class ' .. className .. ' already exists.', 2)
    end

    local newClass = structure
    newClass.__name = className
    local mt = {}
    if (superClass) then
        newClass.super = superClass
        newClass.baseClassName = superClass.__name
        setmetatable(newClass, { __index = superClass })
    end
    classes[className] = newClass
    return newClass
end

function interface(interfaceName)
    local newInterface = {}

    setmetatable(newInterface, {
        __call = function(self, ...)
            if (interfaces[interfaceName]) then
                error('Interface ' .. interfaceName .. ' already exists.', 2)
            end

            local newInstance = ...
            interfaces[interfaceName] = newInstance
            return newInstance
        end
    })

    newInterface.extends = function(self, superInterfaceName)
        return function(subInterface)
            local superInterface = interfaces[superInterfaceName]
            local newInstance = table_implements(subInterface, superInterface)

            if (interfaces[interfaceName]) then
                error('Interface ' .. interfaceName .. ' already exists.', 2)
            end

            interfaces[interfaceName] = newInstance
            return newInstance
        end
    end

    return newInterface
end

function class(className)
    local newClasse = {}
    local modifiers = {
        -- just syntax sugar
        final = function (self)
            return function(subClass)
                local classeCreated = createClass(className, subClass)
                classeCreated.__final = true
                return classeCreated
            end
        end,
        template = function (self, templateTypes)
            
            return function(subClass)
                local classeCreated = createClass(className, subClass)
                local templates = {}
                for name in string.gmatch(templateTypes, "[^,%s]+") do
                    table.insert(templates, name)
                end
                classeCreated.__templateTypes = templates
                return classeCreated
            end
        end,
        extends = function(self, superClassName)
            return function(subClass)
                local superClass = classes[superClassName]
                if (superClass.__final) then
                    error('Class ' .. superClassName .. ' is declared \"final,\" and cannot be inherited!', 2)
                end
                local classCreated = createClass(className, subClass, superClass)
                return classCreated
            end
        end,

        implements = function(self, ...)
            local interfacesNames = {...}
            return function(subClass)
                local classeCreated = createClass(className, subClass)

                for _, v in pairs(interfacesNames) do
                    if (not interfaces[v]) then
                        error('Interface ' .. v .. ' not found', 2)
                    end

                    for _, method in pairs(interfaces[v]) do
                        if (not subClass[method]) then
                            error('Interface ' .. v .. ' not implemented, method ' .. method .. ' not found', 2)
                        end
                    end
                end

                return classeCreated
            end
        end
    }

    setmetatable(newClasse, {
        __index = function (self, key)
            
            if (modifiers[key]) then
                return modifiers[key]
            end

            if (classes[className]) then
                return classes[className][key]
            end

            error('Class ' .. className .. ' not found', 2)
        end,

        __call = function(self, ...)
            if (classes[className]) then
                error('Class ' .. className .. ' already exists.', 2)
            end

            local newInstance = createClass(className, ...)
            return newInstance
        end
    })

    return newClasse
end
local invoke_or_return = function(obj, name, or_else, ...)
    if type(obj[name]) == "function" then
        return obj[name](obj, ...)
    end
    return or_else
end
local mt_template  = {
    __eq = function(a, b) return invoke_or_return(a, "equals", false, b) end,
    __le = function(a,b) return invoke_or_return(a, "le", false, b) or invoke_or_return(a, "lessequals", false, b) end,
    __lt = function(a,b) return invoke_or_return(a, "lt", false, b) or invoke_or_return(a, "less", false, b) end,
    __ge = function(a,b) return invoke_or_return(a, "ge", false, b) or invoke_or_return(a, "greaterequals", false, b) end,
    __gt = function(a,b) return invoke_or_return(a, "gt", false, b) or invoke_or_return(a, "greater", false, b) end,
    __tostring = function(a) return invoke_or_return(a, "tostring", a.__name) end
}
function new(className)
    return function(...)
        local origClassName = className
        local templateStart = string.find(className, "<")
        if templateStart then
            className = string.sub(className, 1, templateStart - 1)
        end
        local classe = classes[className]
        if (not classe) then
            error('Class \"' .. className .. '\" not found', 2)
        end
        -- Handle template types if present
        local templateTypes = classe.__templateTypes
        if templateTypes and #templateTypes > 0 then
            local templateStart = string.find(origClassName, "<")
            local templateEnd = string.find(origClassName, ">")
            if templateStart and templateEnd then
                local templateStr = string.sub(origClassName, templateStart + 1, templateEnd - 1)
                local templateVals = {}
                for val in string.gmatch(templateStr, "[^,%s]+") do
                    table.insert(templateVals, val)
                end
                if #templateVals ~= #templateTypes then
                    error("Class " .. className .. " template argument count mismatch", 2)
                end
                for i, key in ipairs(templateTypes) do
                    classe.__template_t = classe.__template_t or {}
                    classe.__template_t[key] = templateVals[i]
                end
            else
                error("Class " .. className .. " requires template arguments: <" .. table.concat(templateTypes, ",") .. ">", 2)
            end
        end
        local super = classe.super
        local newObj = table_copy(classe, super)
        if (newObj.constructor) then
            newObj:constructor(...)
        end
        
        if newObj.metatable then
            setmetatable(newObj, newObj.metatable)
        else
            setmetatable(newObj, mt_template)
        end
        return newObj
    end
end
---Returns the templates used when running `new`
---@param instance any
---@return table|nil
function get_template_types(instance)
    return instance.__template_t
end
function derivedFrom(instance, className)	
    local class = classes[className]
    if(not class) then
        error("Class \"" .. className .. "\" not found", 2)
    end
    
    if instance and (className == instance.baseClassName) then
        return true
    end

    return false
end

function instanceOf(instance, className)
    if not instance then return false end
    local classe = classes[className]
    if (not classe) then
        error('Class ' .. className .. ' not found', 2)
    end

    if (instance.__name == className) then
        return true
    end

    return false
end