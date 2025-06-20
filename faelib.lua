--- STEAMODDED HEADER
--- MOD_NAME: FaeLib
--- MOD_ID: faelib
--- MOD_AUTHOR: [feintha]
--- MOD_DESCRIPTION: Common utility functions for modding Balatro.
--- PRIORITY: -9999
--- PREFIX: faelib
--- 
----------------------------------------------
------------MOD CODE -------------------------
---@diagnostic disable: undefined-field
assert(SMODS.load_file("blind_utils.lua", "faelib"))()
assert(SMODS.load_file("init.lua", "faelib"))()
assert(SMODS.load_file("core/enums.lua", "faelib"))()
assert(SMODS.load_file("extensions/debugplus.lua", "faelib"))()
assert(SMODS.load_file("ui.lua", "faelib"))()
SMODS.Atlas {
	-- Key for code to find it with
	key = "faelib_stickers",
	-- The name of the file, for the code to pull the atlas from
	path = "faelib_stickers.png",
	-- Width of each sprite in 1x size
	px = 71,
	-- Height of each sprite in 1x size
	py = 95
}
local to_version_table = function (version_def, table)
    table = table or {}
    if (instanceOf(version_def, "VersionDef")) then return version_def end
    if type(version_def) == "table" then
        table.major = version_def[0] or version_def.major or 0
        table.minor = version_def[1] or version_def.minor or 0
        table.patch = version_def[2] or version_def.patch or 0
        return table
    end
    if (type(version_def) == "string") then
        local major, minor, patch = version_def:match("^(%d+)%.(%d+)%.(%d+)$")
        table.major = major or 0
        table.minor = minor or 0
        table.patch = patch or 0
        return table
    end
    error("Unexpected type for version: " .. type(version_def))
end

class "VersionDef" : final() {
    constructor = function (self, version_str)
        to_version_table(version_str, self)
    end,
    get_major = function (self) return self.major end,
    get_minor = function (self) return self.minor end,
    get_patch = function (self) return self.patch end,
    tostring = function (self)
        return self.major .. "." .. self.minor .. "." .. self.patch
    end,
    equals = function (self, other)
        local tbl = to_version_table(other)
        return tbl.major == self.major and tbl.minor == self.minor and tbl.patch == self.patch
    end,
    lt = function(self, other)
        local tbl = to_version_table(other)
        return tbl.major < self.major and tbl.minor < self.minor and tbl.patch < self.patch
    end,
    gt = function(self, other)
        local tbl = to_version_table(other)
        return tbl.major > self.major and tbl.minor > self.minor and tbl.patch > self.patch
    end,
    le = function(self, other)
        local tbl = to_version_table(other)
        return tbl.major <= self.major and tbl.minor <= self.minor and tbl.patch <= self.patch
    end,
    ge = function(self, other)
        local tbl = to_version_table(other)
        return tbl.major >= self.major and tbl.minor >= self.minor and tbl.patch >= self.patch
    end,
}
VersionDef = new "VersionDef"
FaeLib.Version = new "VersionDef"("0.1.0")
FaeLib.ClassOopVersion = new "VersionDef"("1.0.0")

VersionMatches = function(version, version_def)
    if (instanceOf(version_def, "VersionDef")) then return version >= version_def end
    return version >= VersionDef(version_def)
end

FaeLib.Builtin.ButtonVisibilityFuncs = FaeLib.Builtin.ButtonVisibilityFuncs or {}
local CACHED_LOCALIZATION_COLORS = {}
local lc = loc_colour
local CardButtons = {}
FaeLib.ForagerCards = {}
FaeLib.DebugState = FaeLib.Enums.DebugState.Enabled
local unknown_tbl = {key = "unknown"}
FaeLib.APIs.Debugging = {
    SetDebugState = function (state) end
}

FaeLib.AdditionalTooltips = false
function FaeLib.debug()
    return FaeLib.AdditionalTooltips == FaeLib.Enums.DebugState.Enabled

end
local function colorproc(key, value)
    local colours = (SMODS.load_file("faelib/colours.lua", value.id) or function()end)()
    if colours then
        FaeLib.print("Loaded colours for mod: " .. value.id)
        for k, v in pairs(colours) do
            if type(v) == "string" then
                v = HEX(v)
            end
            if not G.ARGS.LOC_COLOURS then
                CACHED_LOCALIZATION_COLORS[k] = v
                goto next_color
            end
            G.ARGS.LOC_COLOURS[k] = v
            ::next_color::
        end
    end
end
local function tagproc(key, value)
    for _, file1 in ipairs(NFS.getDirectoryItems(value.path .. "faelib\\tags")) do
        local namespace = "balatro"
        local path = value.path .. "faelib\\tags\\" ..file1
        local info = NFS.getInfo(path)
        local template_type = "?"
        if info.type == "file" then
            local data = {}
            if file1:sub(-4) == ".lua" then
                data = load(NFS.read(path))()
                path = file1:sub(1, -5)
            elseif file1:sub(-5) == ".json" then
                data = JSON.decode(NFS.read(path))
                path = file1:sub(1, -6)
            end
            if data.values then
                data = data.values
                namespace = data.namespace or namespace
                template_type = data.type or template_type
            end
            local tag = FaeLib.CreateOrGetTag(namespace.. ":" ..path, template_type or nil)
            for _, value in ipairs(data) do
                if type(value) ~= "string" then FaeLib.print("Expected a string", "error") else
                    tag:add(value)
                end
            end
        end
    end
end

local faelibloc = init_localization
function init_localization()
    faelibloc()
    FaeLib.print("Initializing localization utilities")
	if not G.ARGS.LOC_COLOURS then
		lc()
	end
    local builtin_colours = (SMODS.load_file("faelib/colours.lua", "faelib") or function()end)()
    if builtin_colours then
        for k, v in pairs(builtin_colours) do
            if type(v) == "string" then
                v = HEX(v)
            end
            if not G.ARGS.LOC_COLOURS then
                CACHED_LOCALIZATION_COLORS[k] = v
                goto fae_next_color
            end
            G.ARGS.LOC_COLOURS[k] = v
            ::fae_next_color::
        end
        FaeLib.print("Loaded buildin FaeLib colours")
        
    end
    for key, value in pairs(SMODS.Mods) do
        if key == "Lovely" or key == "Balatro" or not value.can_load then
            goto skip
        end
        colorproc(key, value)
        tagproc(key, value)
        ::skip::
    end
    FaeLib.Builtin.Tooltips.Forager = {set = "Other", key = "faelib_forager_tooltip", vars = {}, colour = G.C.BLUE}
    FaeLib.Builtin.Badges.Forager = function()
        local bdg = create_badge('Forager', G.ARGS.LOC_COLOURS["forager"], G.C.WHITE, 0.95 )
        bdg.tooltip = FaeLib.Builtin.Tooltips.Forager
        return bdg
    end
end
function loc_colour(_c, _default)
	if not G.ARGS.LOC_COLOURS then
		lc()
	end
    G.ARGS.LOC_COLOURS.bl_small = HEX("2240a3")
    G.ARGS.LOC_COLOURS.bl_large = HEX("df9822")
    G.ARGS.LOC_COLOURS.bl_hook = HEX("9f2909")
    G.ARGS.LOC_COLOURS.bl_ox = HEX("b24700")
    G.ARGS.LOC_COLOURS.bl_wall = HEX("7d459c")
    G.ARGS.LOC_COLOURS.bl_wheel = HEX("3bb96d")
    G.ARGS.LOC_COLOURS.bl_arm = HEX("5653f5")
    G.ARGS.LOC_COLOURS.bl_club = HEX("b2c786")
    G.ARGS.LOC_COLOURS.bl_fish = HEX("2677b7")
    G.ARGS.LOC_COLOURS.bl_psychic = HEX("f0ba24")
    G.ARGS.LOC_COLOURS.bl_goad = HEX("b2488b")
    G.ARGS.LOC_COLOURS.bl_water = HEX("c1dfec")
    G.ARGS.LOC_COLOURS.bl_water_dark = HEX("5d6d74")
    G.ARGS.LOC_COLOURS.bl_window = HEX("a09889")
    G.ARGS.LOC_COLOURS.bl_manacle = HEX("434343")
    G.ARGS.LOC_COLOURS.bl_eye = HEX("3560e3")
    G.ARGS.LOC_COLOURS.bl_mouth = HEX("a66081")
    G.ARGS.LOC_COLOURS.bl_mouth = HEX("a66081")
    G.ARGS.LOC_COLOURS.bl_plant = HEX("5f8676")
    G.ARGS.LOC_COLOURS.bl_serpent = HEX("2c8f3a")
    G.ARGS.LOC_COLOURS.bl_pillar = HEX("6f553d")
    G.ARGS.LOC_COLOURS.bl_needle = HEX("485d17")
    G.ARGS.LOC_COLOURS.bl_head = HEX("a493ad")
    G.ARGS.LOC_COLOURS.bl_head_dark = HEX("4d4352")
    G.ARGS.LOC_COLOURS.bl_tooth = HEX("ae1313")
    G.ARGS.LOC_COLOURS.bl_flint = HEX("e55815")
    G.ARGS.LOC_COLOURS.bl_mark = HEX("581f30")
    -- final blinds
    G.ARGS.LOC_COLOURS.bl_final_acorn = HEX("ff9800")
    G.ARGS.LOC_COLOURS.bl_amber_acorn = HEX("ff9800")

    G.ARGS.LOC_COLOURS.bl_final_leaf = HEX("429e78")
    G.ARGS.LOC_COLOURS.bl_verdant_leaf = HEX("429e78")

    G.ARGS.LOC_COLOURS.bl_final_vessel = HEX("7d60e0")
    G.ARGS.LOC_COLOURS.bl_violet_vessel = HEX("7d60e0")

    G.ARGS.LOC_COLOURS.bl_final_heart = HEX("a41919")
    G.ARGS.LOC_COLOURS.bl_crimson_heart = HEX("a41919")

    G.ARGS.LOC_COLOURS.bl_final_bell = HEX("0091ff")
    G.ARGS.LOC_COLOURS.bl_cerulean_bell = HEX("0091ff")

    for _, value in ipairs(CACHED_LOCALIZATION_COLORS) do
        G.ARGS.LOC_COLOURS[value.key] = value.color
    end

	return lc(_c, _default)
end
function faelib_create_button(tbl) 
    local a = tbl.alignment
    print(a)
    local D = FaeLib.Enums.Direction
    local left_side = a == D.LEFT or a == D.BOTTOMLEFT or a == D.TOPLEFT
    local right_side = a == D.RIGHT or a == D.BOTTOMRIGHT or a == D.TOPRIGHT
    local top = a == D.TOP
    local bottom = a == D.BOTTOM
    local offset = {x=0, y=0}
    local T = tbl.card.T
    local horizontal = left_side or right_side
    if left_side then
        offset.x = -T.w + 0.5
        offset.y = 0.1
    end
    if right_side then
        offset.x = T.w - 0.5
        offset.y = 0.1
    end
    if top then
        offset.y = T.h/2
    end
    if bottom then
        offset.y = 2*T.h
    end
    print(tbl.button_offset)
    if not top then
        offset.y = offset.y + math.max(0,((tbl.button_offset- 1) or 0) * 0.75)
    else
        offset.y = offset.y - math.min(0,((tbl.button_offset- 1) or 0) * 0.75)
    end

    local box = UIBox({definition =
    {
        btn_id=tbl.button_id,n=horizontal and G.UIT.R or G.UIT.C, config={minw = horizontal and 2 or 0, align = horizontal and (left_side and "cl" or (right_side and "cr" or "cm")) or "cm", ref_table = tbl, r = 0.08, padding = 0.15, hover = false, shadow = true, colour = tbl.color or G.C.UI.BACKGROUND_INACTIVE, one_press = false, button = 'faelib_button_proxy'}, nodes={
        {n=G.UIT.T, config={text = localize("b_"..tbl.button_id),colour = G.C.UI.TEXT_LIGHT, scale = 0.45, align = "tl", shadow = true}}
    }},
    config ={
        -- instance_type = "UIBOX",
        align = "tri",
        bond = "Weak",
        offset = offset,
        parent = tbl.card,
    }
    })
    box.btn_id=tbl.button_id
    return box
end
G.FUNCS.faelib_button_proxy = function (e)
    local tbl = e.config.ref_table
    if not tbl then
        FaeLib.print("Error: ref_table is nil in faelib_button_proxy")
        return
    end
    if tbl and tbl.button then
        local card = tbl.card
        -- print("Running action for button: " .. tbl.button_id)
        tbl.button:run_action(card)
    end
end

FaeLib.smoothstep = function(a, b, t)
  t = t * t * t * (t * (t * 6 - 15) + 10)
  return a + (b - a) * t
end
local CardMovements = {}
function FaeLib.lerp(a,b,t) return a * (1-t) + b * t end

local function easeInOutQuint(x)
    if x < 0.5 then
        return 16 * x * x * x * x * x
    else
        return 1 - ((-2 * x + 2) ^ 5) / 2
    end
end
function FaeLib.easeOutElastic(x)
    local c4 = (2 * math.pi) / 3

    if x == 0 then
        return 0
    elseif x == 1 then
        return 1
    else
        return 2 ^ (-10 * x) * math.sin((x * 10 - 0.75) * c4) + 1
    end
end
function FaeLib.easeInCirc(a, b, t)
    return FaeLib.lerp(a, b, 1 - math.sqrt(1 - (t * t)))
end
local function easeOutBack(x)
    local c1 = 1.70158
    local c3 = c1 + 1

    return 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2)
end
FaeLib.Interpolation =  FaeLib.Interpolation or {}
FaeLib.Interpolation.easeOutElastic = function(x, y, t)
    return FaeLib.lerp(x, y, FaeLib.easeOutElastic(t))
end
FaeLib.Interpolation.easeOutBack = function(x, y, t)
    return FaeLib.lerp(x, y, easeOutBack(t))
end
FaeLib.Interpolation.easeOutQuint = function(x, y, t)
    return FaeLib.lerp(x, y, easeOutQuint(t))
end
FaeLib.Interpolation.easeInOutQuint = function(x, y, t)
    return FaeLib.lerp(x, y, easeInOutQuint(t))
end
function FaeLib.map(f, s1, e1, s2, e2)
    return s2 + (f - s1) * (e2 - s2) / (e1 - s1)
end
class 'FaeLib.Tweener' {
    constructor = function (self, name, table, duration, easing, from, to, autorun, on_complete, on_set, destroy_when_complete)
        self.table = table
        self.name = name
        self.duration = duration or 1
        self.easing = easing or FaeLib.lerp
        self.from = from or 0
        self.to = to or 1
        self.rounding = function (x) return x end
        self.autorun = autorun
        self.on_complete = on_complete or function () end
        self.on_set = on_set or function () end
        self.destroy_when_complete = destroy_when_complete or true
        self.task = new 'FaeLib.Task'(function (task, dt)
            self.easing = self.easing or FaeLib.lerp
            self.elapsed_time = (self.elapsed_time or 0) + dt
            if type(self.name) == "table" then
                -- if name is a table, we assume it's a table of names to tween
                
                for _, name in ipairs(self.name) do
                    self.set(self, name, self.rounding(self.easing(self.from[name], self.to[name], math.min(1,self.elapsed_time / self.duration))))
                end
                self.on_set(self.table, self.name, self.table)
            else
                -- otherwise, we assume it's a single name
                self.set(self, self.name, self.rounding(self.easing(self.from, self.to, math.min(1,self.elapsed_time / self.duration))))
                self.on_set(self.table, self.name, self.table[self.name])
            end
        end, false, self.duration, nil, self.autorun ):with_data(self):with_id("<FaeLib.Tweener>("..(tostring(self.name) or "unnamed")..")")
    end,
    set = function (self, name, value)
        -- print(value)
        self.table[name] = value
    end,
    and_reverse = function (self, duration)
        return self:and_then(self.to, self.from, duration or self.duration)
    end,
    and_then = function (self, from, to, duration)
        duration = duration or 0
        local elapsed_time = 0
        self.task = self.task:and_then(
            function (task, dt)
                elapsed_time = elapsed_time + dt
                if type(self.name) == "table" then
                    for _, name in ipairs(self.name) do
                        self.set(self, name, self.easing(from[name], to[name], elapsed_time / duration))
                    end
                    self.on_set(self.table, self.name, self.table)
                else
                    self.set(self, self.name, self.easing(from, to, elapsed_time / duration))
                    self.on_set(self.table, self.name, self.table[self.name])
                end
        end, false, duration
        )
        return self
    end,
    then_wait = function (self, delay, while_delaying)
        self.task = self.task:and_then(while_delaying or function()end, false, delay)
        return self
    end,
    after = function(self, callback) 
        self.task = self.task:and_then(callback, false, 0)
        return self
    end,

    run = function (self)
        self.task.run = true
        return self
    end,
    wait_to_start = function(self, delay)
        self.task = self.task:wait_to_start(delay)
        return self
    end,
    set_rounding = function(self, rounding_func)
        self.rounding = rounding_func
        return self
    end,
    floor = function(self)
        self.rounding = math.floor
        return self
    end,
    ceil = function(self)
        self.rounding = math.ceil
        return self
    end
}
function FaeLib.Builtin.DeepCopyTable(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no
  if type(o) == 'table' then
    no = {}
    seen[o] = no

    for k, v in next, o, nil do
      no[FaeLib.Builtin.DeepCopyTable(k, seen)] = FaeLib.Builtin.DeepCopyTable(v, seen)
    end
    setmetatable(no, FaeLib.Builtin.DeepCopyTable(getmetatable(o), seen))
  else -- number, string, boolean, etc
    no = o
  end
  return no
end

class 'FaeLib.CardMovement' {
    constructor = function(self, card, target_x, target_y, duration, delay, start,while_delaying, finished, reverses, returns_to_area, easing, reverse_duration, delay_started)
        self.card = card
        self.target_x = target_x
        self.target_y = target_y
        self.start_x = card.T.x
        self.start_y = card.T.y
        self.x = 0
        self.y = 0
        self.duration = (duration or 1)
        self.area = card.area
        self.index = 0
        self.lookat = false
        self.easing = easing or FaeLib.lerp
        self:__card_pop()
        local tweener = new 'FaeLib.Tweener'({"x", "y"},
            self,
            duration,
            self.easing,
            {x=self.start_x, y=self.start_y},
            {x=self.target_x, y=self.target_y},
            true,nil,
            function (tbl, name, value)self:__card_setpos()end
        )
        if delay and delay > 0 then
            if delay_started then
                tweener = tweener:after(delay_started)
            end
            tweener = tweener:then_wait(delay, while_delaying)
        end
        if reverses then
            tweener = tweener:and_reverse(reverse_duration or duration)
        end
        if returns_to_area then
            tweener = tweener:after(function ()
                self:__card_return()
            end)
        end
        tweener = tweener:after(function ()
            if type(finished) == "function" then
                finished()
            end
            card.area = self.area
        end)
        start()
    end,
    __card_setpos = function (self)
        local w = (self.card.T.w)
        local h = (self.card.T.h)
        Moveable.hard_set_T(self.card,self.x, self.y, w, h)
        if self.card.children.front then self.card.children.front:hard_set_T(self.x, self.y, w, h) end
        self.card.children.back:hard_set_T(self.x, self.y, w, h)
        self.card.children.center:hard_set_T(self.x, self.y, w, h)
    end,
    __card_pop = function (self)
        for i = #self.area.cards,1,-1 do
            if self.area.cards[i] == self.card then
                self.card:remove_from_area()
                table.remove(self.area.cards, i)
                local t = FaeLib.Builtin.DeepCopyTable(self.card)
                t.faelib_card_movement = i
                t.draw = function ()end
                table.insert(self.area.cards, i, t)
                index = i
                self.area:remove_from_highlighted(self.card, true)
                break
            end
        end
    end,
    __card_return = function (self)
        for i = #self.area.cards,1,-1 do
            local current = self.area.cards[i]
            if self.area.cards[i].faelib_card_movement == index then
                current:remove_from_area()
                table.remove(self.area.cards, i)
                table.insert(self.area.cards, i, self.card)
                break
            end
        end
    end,
    looks_at_target = function (self)
        self.lookat = true
    end
}
FaeLib.V.FrameTasks = {}
class 'FaeLib.Task' {
    constructor = function(self, func, repeating, duration, should_stop_repeating, auto_start, dont_assign)
        if not func or type(func) ~= "function" then
            error("Task requires a function as an argument")
        end
        if repeating and (duration) then
            if duration > 0 then
                error("Task cannot be repeating and have a duration.")
            end
        end
        self.duration = duration or 0
        self.func = func
        self.index = #FaeLib.V.FrameTasks + 1
        self.repeating = repeating or false
        self.should_stop_repeating = should_stop_repeating or function () return false end
        self.run = auto_start or true
        self.next_delay_time = 0
        self.__tail = self
        self.start_delay_time = 0
        self._dont_run_while_delaying = false
        self.id = nil
        self.manual = false
        self.last_invoke_time = 0
        if not dont_assign then
            FaeLib.V.FrameTasks[self.index] = self
        end
    end,
    mark_discarded = function(self) 
        self.discard = true
    end,
    and_then = function (self, func, repeating, duration, should_stop_repeating, delay_before_starting)
        local next_task = new 'FaeLib.Task'(func, repeating, duration, should_stop_repeating, true, true)
        self.__tail.next = next_task
        self.__tail.next.run = false
        self.__tail.next.manual = self.manual
        self.__tail.next_delay_time = delay_before_starting or self.next_delay_time or 0
        self.__tail = self.__tail.next
        return self
    end,
    with_data = function(self, data)
        self.data = data
        return self
    end,
    dont_run_while_delaying = function(self)
        self.__tail._dont_run_while_delaying = true
        return self
    end,
    with_duration = function(self, duration)
        self.duration = duration
        return self
    end,
    with_id = function(self, id)
        self.id = id
        return self
    end,
    with_delay = function(self, duration)
        self.next_delay_time = duration
        return self
    end,
    wait_to_start = function(self, duration)
        self.start_delay_time = duration
        return self
    end,
    start = function(self)
        self.run = true
        self.manual = false
        return self
    end,
    manual_run = function(self)
        self.run = false
        self.manual = true
        return self
    end,
}

function FaeLib.V.TaskClearForId(id)
    if id == nil then return end
    for key, value in pairs(FaeLib.V.FrameTasks) do
        if value.id == id then
            FaeLib.V.FrameTasks[key] = nil
        end
    end
end
local game_main_menu_ref = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
    local ret = game_main_menu_ref(self, change_context)
    
    G.GAME.round_resets.blind_states = {Small = 'Select', Big = 'Upcoming', Medium= 'Upcoming', Boss = 'Upcoming'}
    UIBox{
        definition = 
        {n=G.UIT.ROOT, config={align = "cm", colour = G.C.UI.TRANSPARENT_DARK}, nodes={
            {n=G.UIT.T, config={text = tostring(FaeLib.Version) .. "-FAELIB", scale = 0.3, colour = G.C.UI.TEXT_LIGHT}}
        }}, 
        config = {align="tri", offset = {x=0,y=-.5}, major = G.ROOM_ATTACH, bond = 'Weak'}
    }
    return ret
end
function FaeLib.render()
    local dt= love.timer.getDelta()
end



SMODS.DrawStep {
    key = 'faelib_card_buttons',
    order = -1000,
	func = function(card, layer)

		if not card.children then
			card.children = {}
		end
        local tbl = {
            layer = layer,
            button_id = nil,
            card = card,
        }
        local update = false
        local buttons_per_side = {}
        for key, button in pairs(CardButtons) do
            local has_button_already = false
            local existing_button = nil
            for i = 1, #card.children do
                local child = card.children[i]
                -- print("Checking button: " .. (child and child.btn_id or "nil"))
                if child and child.btn_id == key then
                    has_button_already = true
                    existing_button = child
                end
            end
            
            if button:can_display(card) then
                if not has_button_already then
                    FaeLib.print("Adding button: " .. key)
                    local button_id = key
                    local tbl1 = {}
                    tbl1.button = button
                    tbl1.button_id = button_id
                    tbl1.text = button.text
                    tbl1.color = button.color
                    -- print(button.side)
                    tbl1.side = button.side
                    tbl1.alignment = button.side
                    tbl1.card = card
                    buttons_per_side[button.side] = (buttons_per_side[button.side] or 0) + 1
                    tbl1.button_offset = buttons_per_side[button.side]
                    local btn = faelib_create_button(tbl1)
                    btn.btn_id = button_id
                    local oldupdate = btn.update
                    btn.update = function (self, dt)
                        oldupdate(self,dt)
                        if self.config.major.REMOVED then 
                            self:remove()
                        end
                    end
                    card.children[#card.children + 1] = btn
                end
            elseif card.children then
                for i = 1, #card.children do
                    local child = card.children[i]
                    if child and child.btn_id == key then
                        card.children[i]:remove()
                        card.children[i] = nil
                        FaeLib.print("Removing button: " .. key)
                    end
                end
            end
        end
	end
}
FaeLib.Builtin.ButtonVisibilityFuncs = FaeLib.Builtin.ButtonVisibilityFuncs or {}
FaeLib.Builtin.ButtonVisibilityFuncs.Selected = function (card)
    if not card then
        return false
    end
    if card.selected then
        return true
    end
end
FaeLib.Builtin.ButtonVisibilityFuncs.Sellable = function (card)
    if not card then
        return false
    end
    if card.ability.extra and card.ability.extra.sellable then
        return true
    end
end
FaeLib.Builtin.ButtonVisibilityFuncs.Buyable = function (card)
    if not card then
        return false
    end
    if card.ability.extra and card.ability.extra.buyable then
        return true
    end
end
FaeLib.Builtin.ButtonVisibilityFuncs.AlwaysTrue = function (card)
    if not card then
        return false
    end
    return true
end
FaeLib.Builtin.ButtonVisibilityFuncs.AlwaysFalse = function (card)
    return false
end
--- @class FaeLib.Enums.Direction
--- @field TOP integer
--- @field BOTTOM integer
--- @field LEFT integer
--- @field RIGHT integer
--- @field BOTTOMLEFT integer
--- @field BOTTOMRIGHT integer
--- @field TOPLEFT integer
--- @field TOPRIGHT integer
FaeLib.Enums.Direction = FaeLib.Enum[[
    TOP
    BOTTOM
    LEFT
    RIGHT
    BOTTOMLEFT
    BOTTOMRIGHT
    TOPLEFT
    TOPRIGHT
]]
class 'FaeLib.CardButton' {
    constructor = function (self, key, alignment, run_action, color, can_display)
        self.can_display = can_display or function (card)
            return true
        end
        self.key = key
        self.side = alignment or FaeLib.Enums.Direction.RIGHT
        self.run_action = run_action or function (self, card) end
        G.FUNCS[self.key.."_run_action"] = function (e)
            if e.ref_table and e.ref_table.card then
                self:run_action(e.ref_table.card)
            end
        end
        self.color = color or G.C.WHITE
        CardButtons[self.key] = self
    end,
    can_display = function (self, card)end,
    run_action = function (self, card)end,
}

class 'FaeLib.LocalizationColor' {
    constructor = function(self, key, color)
        self.color = color
        if type(color) == "table" or type(color) == "string" then
            self.color = HEX(color)
        end
        self.key = key
        self:update()
    end,
    update = function (self)
        if not G.ARGS.LOC_COLOURS then
            FaeLib.print("G.ARGS.LOC_COLOURS is not initialized, caching localization color to set upon initialize: " .. self.key)
            CACHED_LOCALIZATION_COLORS[#CACHED_LOCALIZATION_COLORS + 1] = self
            return
        end

        G.ARGS.LOC_COLOURS[self.key] = self.color
    end
}

SMODS.Sticker{
	key = "foraged_sticker",
	atlas = "faelib_stickers",
	default_compat = true,
	default_compat = true,
}
FaeLib.Ext.GenCardExtTooltips = function (_c, info_queue, card)
    if (FaeLib.AdditionalTooltips) then
        if card then
            local ability = card.ability or unknown_tbl
            local edition = card.edition or unknown_tbl
            local seal = card.seal or unknown_tbl

            info_queue[#info_queue+1] = {set = "Other", key = "faelib_extended_info_tooltip", vars = {card.key or card.config.center.key or "unknown", card.set or "unknown", ability.key, edition.key, seal.key, type(card.sticker) == "table" and tprint(card.sticker) or card.sticker or unknown_tbl}}
        end
    end
end
G.localization.descriptions["Other"] = G.localization.descriptions["Other"] or {}
FaeLib.Builtin.PopupAtCard = function (card, data)
    data = data or {}
    attention_text({
        text = data.message or "TEST",
        scale = data.scale or 1,
        hold = data.duration or 1,
        backdrop_colour = data.colour or G.C.WHITE,
        align = data.alignment or "bm",
        major = card,
        offset = data.offset or {x = 0, y = -0.2}
    })
end
FaeLib.Builtin.TextPopupAtCard = function (card, text, color)
    FaeLib.Builtin.PopupAtCard(card, {message = text, colour = color or G.C.WHITE})
end
FaeLib.Builtin.AddCardToSlot = function (card, slot)
    card:add_to_deck()
    card:start_materialize()
    slot:emplace(card)
end
SMODS.Keybind {
    key_pressed = "f3",
    action = function (self)
        FaeLib.AdditionalTooltips = not FaeLib.AdditionalTooltips
        print("Toggling Additional Tooltips " .. (FaeLib.AdditionalTooltips and "ON" or "OFF"))
    end
}
FaeLib.Builtin.AddCardToJokerSlots = function (card)
    FaeLib.Builtin.AddCardToSlot(card, G.jokers)
end
FaeLib.Builtin.AddJokerToDeck = function (joker)
    FaeLib.Builtin.AddCardToSlot(joker, G.jokers)
end
FaeLib.Builtin.NumSelectedCards = function (area)
    local amt = 0
    area = area or G.hand
    if area then
        for _, value in ipairs(area.cards) do
            amt = value.highlighted and (amt + 1) or amt
        end
    end
    return amt
end
FaeLib.Builtin.SetCard = function (card, suit, value, enhancement)
    card:set_ability(G.P_CENTERS[enhancement] or {})
    assert(SMODS.change_base(card, suit, value))
end
FaeLib.Builtin.SetCardsBulk = function (cards, suit, value, enhancement, edition, seal)
    for i = 1, #cards do
        local card = cards[i]
        if enhancement then
            card:set_ability((type(enhancement) == "table" and enhancement or G.P_CENTERS[enhancement]) or {})
        end
        if edition then
            card:set_edition(edition, true)
        end
        if seal then
            card:set_seal(seal, nil, true)
        end
        if suit and value then
            assert(SMODS.change_base(card, suit, value))
        end
    end
end
FaeLib.Builtin.Tooltips = {
    bl_head = {set = "Blind", key = "bl_head", vars = {}},
    bl_arm = {set = "Blind", key = "bl_arm", vars = {}},
    bl_window = {set = "Blind", key = "bl_window", vars = {}},
    bl_wheel = {set = "Blind", key = "bl_wheel", vars = {}},
    bl_water = {set = "Blind", key = "bl_water", vars = {}},
    bl_wall = {set = "Blind", key = "bl_wall", vars = {}},
    bl_tooth = {set = "Blind", key = "bl_tooth", vars = {}},
    bl_small = {set = "Blind", key = "bl_small", vars = {}},
    bl_serpent = {set = "Blind", key = "bl_serpent", vars = {}},
    bl_psychic = {set = "Blind", key = "bl_psychic", vars = {}},
    bl_plant = {set = "Blind", key = "bl_plant", vars = {}},
    bl_pillar = {set = "Blind", key = "bl_pillar", vars = {}},
    bl_ox = {set = "Blind", key = "bl_ox", vars = {}},
    bl_needle = {set = "Blind", key = "bl_needle", vars = {}},
    bl_mouth = {set = "Blind", key = "bl_mouth", vars = {}},
    bl_mark = {set = "Blind", key = "bl_mark", vars = {}},
    bl_manacle = {set = "Blind", key = "bl_manacle", vars = {}},
    bl_house = {set = "Blind", key = "bl_house", vars = {}},
    bl_hook = {set = "Blind", key = "bl_hook", vars = {}},
    bl_goad = {set = "Blind", key = "bl_goad", vars = {}},
    bl_flint = {set = "Blind", key = "bl_flint", vars = {}},
    bl_fish = {set = "Blind", key = "bl_fish", vars = {}},
    bl_final_vessel = {set = "Blind", key = "bl_final_vessel", vars = {}},
    bl_final_lead = {set = "Blind", key = "bl_final_lead", vars = {}},
    bl_final_heart = {set = "Blind", key = "bl_final_heart", vars = {}},
    bl_final_bell = {set = "Blind", key = "bl_final_bell", vars = {}},
    bl_eye = {set = "Blind", key = "bl_eye", vars = {}},
    bl_club = {set = "Blind", key = "bl_club", vars = {}},
    bl_big = {set = "Blind", key = "bl_big", vars = {}},
}
if not G.P_CENTERS then
    G.P_CENTERS = {}
end
G.P_CENTERS = G.P_CENTERS or {}
-- G.P_CENTERS["faelib_popup_example"] = {set = "Other", key = "faelib_popup_example", vars = {}}
G.P_CENTERS["bl_head_tooltip"] = FaeLib.Builtin.Tooltips.bl_head
G.P_CENTERS["bl_arm_tooltip"] = FaeLib.Builtin.Tooltips.bl_arm
G.P_CENTERS["bl_window_tooltip"] = FaeLib.Builtin.Tooltips.bl_window
G.P_CENTERS["bl_wheel_tooltip"] = FaeLib.Builtin.Tooltips.bl_wheel
G.P_CENTERS["bl_water_tooltip"] = FaeLib.Builtin.Tooltips.bl_water
G.P_CENTERS["bl_wall_tooltip"] = FaeLib.Builtin.Tooltips.bl_wall
G.P_CENTERS["bl_tooth_tooltip"] = FaeLib.Builtin.Tooltips.bl_tooth
G.P_CENTERS["bl_small_tooltip"] = FaeLib.Builtin.Tooltips.bl_small
G.P_CENTERS["bl_serpent_tooltip"] = FaeLib.Builtin.Tooltips.bl_serpent
G.P_CENTERS["bl_psychic_tooltip"] = FaeLib.Builtin.Tooltips.bl_psychic
G.P_CENTERS["bl_plant_tooltip"] = FaeLib.Builtin.Tooltips.bl_plant
G.P_CENTERS["bl_pillar_tooltip"] = FaeLib.Builtin.Tooltips.bl_pillar
G.P_CENTERS["bl_ox_tooltip"] = FaeLib.Builtin.Tooltips.bl_ox
G.P_CENTERS["bl_needle_tooltip"] = FaeLib.Builtin.Tooltips.bl_needle
G.P_CENTERS["bl_mouth_tooltip"] = FaeLib.Builtin.Tooltips.bl_mouth
G.P_CENTERS["bl_mark_tooltip"] = FaeLib.Builtin.Tooltips.bl_mark
G.P_CENTERS["bl_manacle_tooltip"] = FaeLib.Builtin.Tooltips.bl_manacle
G.P_CENTERS["bl_house_tooltip"] = FaeLib.Builtin.Tooltips.bl_house
G.P_CENTERS["bl_hook_tooltip"] = FaeLib.Builtin.Tooltips.bl_hook
G.P_CENTERS["bl_goad_tooltip"] = FaeLib.Builtin.Tooltips.bl_goad
G.P_CENTERS["bl_flint_tooltip"] = FaeLib.Builtin.Tooltips.bl_flint
G.P_CENTERS["bl_fish_tooltip"] = FaeLib.Builtin.Tooltips.bl_fish
G.P_CENTERS["bl_final_vessel_tooltip"] = FaeLib.Builtin.Tooltips.bl_final_vessel
G.P_CENTERS["bl_final_lead_tooltip"] = FaeLib.Builtin.Tooltips.bl_final_lead
G.P_CENTERS["bl_final_heart_tooltip"] = FaeLib.Builtin.Tooltips.bl_final_heart
G.P_CENTERS["bl_final_bell_tooltip"] = FaeLib.Builtin.Tooltips.bl_final_bell
G.P_CENTERS["bl_final_bell_tooltip"] = FaeLib.Builtin.Tooltips.bl_final_bell
G.P_CENTERS["bl_eye_tooltip"] = FaeLib.Builtin.Tooltips.bl_eye
G.P_CENTERS["bl_club_tooltip"] = FaeLib.Builtin.Tooltips.bl_club
G.P_CENTERS["bl_big_tooltip"] = FaeLib.Builtin.Tooltips.bl_big
G.P_CENTERS["bl_arm_tooltip"] = FaeLib.Builtin.Tooltips.bl_arm


FaeLib.Builtin.Events.JokerAdded = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.CardAdded = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.HandPlayed = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.HandScored = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.StartHandScoring = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.CardRemoved = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.ConsumableUsed = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindStarted = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindSkipped = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindCompleted = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindFailed = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.MousePressed = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.MouseMoved = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.MouseReleased = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.RenderPost = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.RenderPre = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.InitItemPrototypes = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.MainMenuOpened = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.ResetBlinds = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving = {}
FaeLib.Builtin.Events.Saving.SaveProfile = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.LoadProfile = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.SaveSettings = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.LoadSettings = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.SaveRun = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.LoadRun = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.NewRun = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.RunDataReset = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.DeleteRun = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.Saving.LoadMetadata = new 'FaeLib.AbstractEventHandler' ()


FaeLib.Builtin.Events.KeyPressed = new 'FaeLib.AbstractEventHandler' ()

FaeLib.Builtin.Tooltips.test_tooltip = new 'FaeLib.Tooltip' (
    "faelib_popup_example",
    "Faelib Test Popup",
    {"Example {C:dark_edition,E:3}tooltip{} using the {C:legendary,E:3}FaeLib{} library.", "This is created using the following LUA code: \"new 'FaeLib.Tooltip' (key:String, title:String, text:Table[String])\"",}
)
FaeLib.Builtin.Tooltips.extended_tooltip = new 'FaeLib.Tooltip' (
    "faelib_extended_info",
    "FaeLib - Card Info",
    {
        "id:\"#1#\"",
        "type:\"#2#\"",
        "enhancement:\"#3#\"",
        "edition:\"#4#\"",
        "seal:\"#5#\"",
        "sticker:\"#6#\""
    }
)
FaeLib.Builtin.GetCurrentBlindKey = function ()
    return G.GAME.blind.config.blind.key
end

--- Gets the full deck (discard, hand, and deck)
--- Ordered as deck -> discard -> hand
FaeLib.Builtin.GetFullDeck = function ()
    return FaeLib.JoinTable(FaeLib.JoinTable(G.deck, G.discard, FaeLib.DuplicateHandling.APPEND), G.hand, FaeLib.DuplicateHandling.APPEND)
end
--- comments
--- @param area CardArea|Card[]
FaeLib.Builtin.NumCardsOfSuit = function (area)
    area = area or FaeLib.Builtin.GetFullDeck()
    local cards = area.cards and area.cards or area

end
FaeLib.Tags.ForagerCards = FaeLib.CreateOrGetTag("balatro:forager_cards", "Card")
FaeLib.Tags.FoodCards = FaeLib.CreateOrGetTag("balatro:food_cards", "Card")
FaeLib.Tags.AmogusCards = FaeLib.CreateOrGetTag("faelib:amogus_cards", "Card")
FaeLib.Tags.Blinds = FaeLib.CreateOrGetTag("balatro:blinds", "Blind")
FaeLib.Tags.BossBlinds = FaeLib.CreateOrGetTag("balatro:boss_blinds", "Blind")
FaeLib.Tags.FinalBlinds = FaeLib.CreateOrGetTag("balatro:final_blinds", "Blind")

FaeLib.Tags.BossBlinds:add("bl_ox")
FaeLib.Tags.BossBlinds:add("bl_hook")
FaeLib.Tags.BossBlinds:add("bl_mouth")
FaeLib.Tags.BossBlinds:add("bl_fish")
FaeLib.Tags.BossBlinds:add("bl_club")
FaeLib.Tags.BossBlinds:add("bl_manacle")
FaeLib.Tags.BossBlinds:add("bl_tooth")
FaeLib.Tags.BossBlinds:add("bl_wall")
FaeLib.Tags.BossBlinds:add("bl_house")
FaeLib.Tags.BossBlinds:add("bl_mark")
FaeLib.Tags.BossBlinds:add("bl_wheel")
FaeLib.Tags.BossBlinds:add("bl_arm")
FaeLib.Tags.BossBlinds:add("bl_psychic")
FaeLib.Tags.BossBlinds:add("bl_goad")
FaeLib.Tags.BossBlinds:add("bl_water")
FaeLib.Tags.BossBlinds:add("bl_eye")
FaeLib.Tags.BossBlinds:add("bl_plant")
FaeLib.Tags.BossBlinds:add("bl_needle")
FaeLib.Tags.BossBlinds:add("bl_head")
FaeLib.Tags.BossBlinds:add("bl_window")
FaeLib.Tags.BossBlinds:add("bl_serpent")
FaeLib.Tags.BossBlinds:add("bl_pillar")
FaeLib.Tags.BossBlinds:add("bl_flint")

FaeLib.Tags.BossBlinds:add("bl_final_acorn")
FaeLib.Tags.BossBlinds:add("bl_final_heart")
FaeLib.Tags.BossBlinds:add("bl_final_bell")
FaeLib.Tags.BossBlinds:add("bl_final_leaf")
FaeLib.Tags.BossBlinds:add("bl_final_vessel")


FaeLib.Tags.FinalBlinds:add("bl_final_acorn")
FaeLib.Tags.FinalBlinds:add("bl_final_heart")
FaeLib.Tags.FinalBlinds:add("bl_final_bell")
FaeLib.Tags.FinalBlinds:add("bl_final_leaf")
FaeLib.Tags.FinalBlinds:add("bl_final_vessel")

FaeLib.Tags.Blinds:add("bl_small")
FaeLib.Tags.Blinds:add("bl_big")

FaeLib.Tags.Blinds:add("#balatro:boss_blinds")
FaeLib.Tags.Blinds:add("#balatro:final_blinds")

local smods_oldi = SMODS.Blind.inject
SMODS.Blind.inject = function (self, i)
    smods_oldi(self,i)
    FaeLib.Tags.Blinds:add(self)
end
FaeLib.SMODS = {}
FaeLib.SMODS.RepetitionWarning = FaeLib.Enums.State.Disabled
local smods_irep = SMODS.insert_repetitions
SMODS.insert_repetitions = function(ret, eval, effect_card, _type)
    repeat
        eval.repetitions = eval.repetitions or 0
        if eval.repetitions <= 0 then
            if (FaeLib.SMODS.RepetitionWarning == FaeLib.Enums.State.Enabled) then
                sendWarnMessage('Found effect table with no assigned repetitions during repetition check')
            end
        end
        local effect = {}
        for k,v in pairs(eval) do
            if k ~= 'extra' then effect[k] = v end
        end
        if _type == 'joker_retrigger' then
            effect.retrigger_card = effect_card
            effect.message_card = effect.message_card or effect_card
            effect.retrigger_flag = true
        elseif _type == 'individual_retrigger' then
            effect.retrigger_card = effect_card.object
            effect.message_card = effect.message_card or effect_card.scored_card
        elseif not _type then
            effect.card = effect.card or effect_card
        end
        effect.message = effect.message or (not effect.remove_default_message and localize('k_again_ex'))
        for h=1, effect.repetitions do
            table.insert(ret, _type == "joker_retrigger" and effect or { retriggers = effect})
        end
        eval = eval.extra
    until not eval
end


class 'FaeLib.Card.ForagerJoker' {
    constructor = function (self, original_card, card_to_create, area)
        self.original_card = original_card
        self.card_to_create = card_to_create
        self.area = area or G.deck
        FaeLib.ForagerCards[original_card.key or original_card.config.center.key] = self
    end,
    create = function (self)
        return create_playing_card({center = G.P_CENTERS[self.card_to_create.key or self.card_to_create.config.center.key]}, G.deck)
    end
}

FaeLib.Builtin.Events.BlindCompleted:register(function (blind)
    if (FaeLib.Tags.BossBlinds:contains(FaeLib.Builtin.GetCurrentBlindKey())) then
        for _, value in ipairs(G.jokers.cards) do
            if FaeLib.ForagerCards[value.config.center.key] then
                G.E_MANAGER:add_event(Event({
                    trigger = "immediate",
                    func = function()
                        local card =FaeLib.ForagerCards[value.config.center.key]:create()
                        card.from_foraging = true
                        card.sticker = "faelib_foraged_sticker"
                        SMODS.calculate_context({ playing_card_added = true, cards = {card} })
                        FaeLib.Builtin.TextPopupAtCard(card, "Foraged", G.ARGS.LOC_COLOURS.forager)
                        return true
                    end})
                )
            end
        end
    end
end
)
FaeLib.Distance = function (x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

local love_callbacks = {
    mousepressed = love.mousepressed,
    mousereleased = love.mousereleased,
    mousemoved = love.mousemoved,
    draw = love.draw,
    keypressed = love.keypressed,
    wheelmoved = love.wheelmoved
}

function love.keypressed(key)
    love_callbacks.keypressed(key)
    FaeLib.Builtin.Events.KeyPressed:invoke(key)
end

-- love.wheelmoved = function (x, y)
    -- love_callbacks.wheelmoved(x, y)
-- end
FaeLib.Mouse = {
    State = {
        just_pressed = {},
        just_released = {}
    },
    was_pressed = function (button) return FaeLib.Mouse.State.just_pressed[button] or false end,
    was_released = function (button) return FaeLib.Mouse.State.just_released[button] or false end
}
function FaeLib.GetElementKey(tbl, element, default)
    for key, value in pairs(tbl) do
        if value == element then return key end
    end
    return default
end
local function ExecTaskImpl(_, task, dt)
    dt= dt or love.timer.getDelta()
    _ = _ or FaeLib.GetElementKey(FaeLib.V.FrameTasks, task)
    if not _ then
        error("Unexpected task found! Is it valid, or properly registered?")
    end
    if (task.discard) then
        table.remove(FaeLib.V.FrameTasks, _)
        return
    end
    if task.start_delay_time and task.start_delay_time > 0 then
        task.start_delay_time = task.start_delay_time - dt
        return
    end
    task.next_delay_time = task.next_delay_time or 0
    if task.duration > 0 or task.next_delay_time > 0 then
        if task.duration <= 0 and task.next_delay_time > 0 then
            task.next_delay_time = task.next_delay_time - dt
        end
        if task.duration > 0 then
            task.duration = task.duration - dt
        end
        if not task._dont_run_while_delaying then
            if task.func then
                task:func(dt)
                task.last_invoke_time = love.timer.getTime()
            end
        end
        
        return
    end
    if task.repeating and task.should_stop_repeating() then
        if task.next then
            task.next.run=not task.manual
            task.next.manual = task.manual
            task.next.data = task.data
            task.next.id = task.id
            table.remove(FaeLib.V.FrameTasks, _)
            FaeLib.V.FrameTasks[#FaeLib.V.FrameTasks+1] = task.next
            if task.next.func then
                task.next:func(dt)
                task.next.last_invoke_time = love.timer.getTime()
            end
        else
            -- FaeLib.print("VTASK Discarding- repeating " .. tostring(task.id) .. " @" ..(task.manual and "manual" or "auto"))
            table.remove(FaeLib.V.FrameTasks, _)
        end
        return
    end
    if not task.repeating and (task.duration <= 0 and task.next_delay_time <= 0) then
        if task.next then
            task.next.run=not task.manual
            task.next.manual = task.manual
            task.next.id = task.id
            task.next.data = task.data
            -- FaeLib.print("VTASK Discarding- next task " .. tostring(task.id) .. " @" ..(task.manual and "manual" or "auto"))
            table.remove(FaeLib.V.FrameTasks, _)
            FaeLib.V.FrameTasks[#FaeLib.V.FrameTasks+1] = task.next
            if task.next.func then
                task.next:func(dt)
                task.next.last_invoke_time = love.timer.getTime()
            end
        else
            -- FaeLib.print("VTASK Discarding- not repeating ".. tostring(task.id) .. " @" ..(task.manual and "manual" or "auto"))
            table.remove(FaeLib.V.FrameTasks, _)
        end
        return
    end
end

function FaeLib.Builtin.ExecTasksForId(id, dt)
    for _, task in ipairs(FaeLib.V.FrameTasks) do
        if task.id == id and task.manual then
            ExecTaskImpl(_, task, dt or (love.timer.getTime() - task.last_invoke_time))
        end
    end
end
function FaeLib.Builtin.GetTasksForId(id)
    local tasks = {}
    for _, task in ipairs(FaeLib.V.FrameTasks) do
        if task.id == id then
            table.insert(tasks, task)
        end
    end
    return tasks
end
love.mouse.was_pressed = function (button) return FaeLib.Mouse.State.just_pressed[button] or false end
love.mouse.was_released = function (button) return FaeLib.Mouse.State.just_released[button] or false end
love.draw = function ()
    FaeLib.Builtin.Events.RenderPre:invoke()
    love_callbacks.draw()
    FaeLib.Builtin.Events.RenderPost:invoke()
    
    local dt= love.timer.getDelta()
    for _, task in ipairs(FaeLib.V.FrameTasks) do
        if task.run and not task.manual then
            ExecTaskImpl(_, task, dt)
        end
    end
    for index, _ in ipairs(FaeLib.Mouse.State.just_pressed) do
        FaeLib.Mouse.State.just_pressed[index] = false
    end
    for index, _ in ipairs(FaeLib.Mouse.State.just_released) do
        FaeLib.Mouse.State.just_released[index] = false
    end
end
love.mousemoved = function (x, y, dx, dy, is_touch)
    love_callbacks.mousemoved(x,y,dx,dy,is_touch)
    FaeLib.Builtin.Events.MouseMoved:invoke(x,y,dx,dy,is_touch)
end
love.mousepressed = function( x, y, button, touch )
	love_callbacks.mousepressed(x,y,button, touch)
    FaeLib.Builtin.Events.MousePressed:invoke(x,y,button, touch)
    FaeLib.Mouse.State.just_pressed[button] = true
end
love.mousereleased = function( x, y, button, touch )
	love_callbacks.mousereleased(x,y,button, touch)
    FaeLib.Builtin.Events.MouseReleased:invoke(x,y,button, touch)
    FaeLib.Mouse.State.just_released[button] = true
end

FaeLib.APIs.Drawing = {}
FaeLib.APIs.Drawing.text_centered = function(text, x, y, rads, scx, scy, kx, ky, y_align)
	y_align = y_align or false
	local w = love.graphics.getFont():getWidth(text) * 0.5
	local h = (y_align and w or 0) * 0.5
	love.graphics.print(text, x - w, y - h, rads, scx, scy, w, h, kx, ky)
end
FaeLib.APIs.Drawing.text_ease_alpha = function(text, x, y, rgb_colour, fade_in_time, hold_time, fade_out_time, easing, rads, scx, scy, kx, ky)
    easing = easing or lerp
    new 'FaeLib.Task'(function (self, delta)
        self.data.color[4] = math.min(easing(self.data.color[4], 1, delta / fade_in_time), 1)
        love.graphics.setColor(self.data.color[1], self.data.color[2], self.data.color[3], self.data.color[4])
        love.graphics.print(text, self.data.pos.x, self.data.pos.y, rads, scx, scy, kx, ky)
    end, false, fade_in_time)
    :with_data({
        color = {rgb_colour[1], rgb_colour[2], rgb_colour[3], 0}, -- Start with alpha = 0
        pos = {x = x, y = y}
    })
    :with_delay(hold_time)
    :and_then(
        function (self, delta)
            self.data.color[4] = math.max(easing(self.data.color[4], 0, delta / fade_out_time), 0)
            love.graphics.setColor(self.data.color[1], self.data.color[2], self.data.color[3], self.data.color[4])
            love.graphics.print(text, self.data.pos.x, self.data.pos.y, rads, scx, scy, kx, ky)
        end, false, fade_out_time
    )
end
FaeLib.APIs.Drawing.text_ease_alpha_centered = function(text, x, y, rgb_colour, fade_in_time, hold_time, fade_out_time, easing, rads, scx, scy, kx, ky, center_y)
    easing = easing or FaeLib.lerp
    new 'FaeLib.Task'(function (self, delta)
        self.data.color[4] = math.min(easing(self.data.color[4], 1, delta / fade_in_time), 1)
        love.graphics.setColor(self.data.color[1], self.data.color[2], self.data.color[3], self.data.color[4])
        FaeLib.APIs.Drawing.text_centered(text, self.data.pos.x, self.data.pos.y, rads, scx, scy, kx, ky, center_y)
    end, false, fade_in_time)
    :with_data({
        color = {rgb_colour[1], rgb_colour[2], rgb_colour[3], 0}, -- Start with alpha = 0
        pos = {x = x, y = y}
    })
    :with_delay(hold_time)
    :and_then(
        function (self, delta)
            self.data.color[4] = math.max(easing(self.data.color[4], 0, delta / fade_out_time), 0)
            love.graphics.setColor(self.data.color[1], self.data.color[2], self.data.color[3], self.data.color[4])
            FaeLib.APIs.Drawing.text_centered(text, self.data.pos.x, self.data.pos.y, rads, scx, scy, kx, ky, center_y)
        end, false, fade_out_time
    )
end

local SaveDataStorage = {}

class 'FaeLib.SaveData'{
    constructor = function (self, key)
        self.key = key
        self.on_reset_run_data = FaeLib.empty_func
        self.on_new_run = FaeLib.empty_func
        self.on_run_delete = FaeLib.empty_func
        self.on_run_save = FaeLib.empty_func
        self.on_run_load = FaeLib.empty_func
        self.on_save_settings = FaeLib.empty_func
        self.on_load_settings = FaeLib.empty_func
        self.on_save_profile = FaeLib.empty_func
        self.on_load_profile = FaeLib.empty_func
        self.on_load_profile_metadata = FaeLib.empty_func
        SaveDataStorage[key] = self
        return self
    end,
    run_save = function (self, func)
        self.on_run_save = func
        return self
    end,
    settings_save = function (self, func)
        self.on_save_settings = func
        return self
    end,
    profile_save = function (self, func)
        self.on_save_profile = func
        return self
    end,
    run_clear_data = function (self, func)
        self.on_reset_run_data = func
        return self
    end,
    new_run = function (self, func)
        self.on_new_run = func
        return self
    end,
    run_delete = function (self, func)
        self.on_run_delete = func
        return self
    end,
    run_load = function (self, func)
        self.on_run_load = func
        return self
    end,
    settings_load = function (self, func)
        self.on_load_settings = func
        return self
    end,
    profile_load = function (self, func)
        self.on_load_profile = func
        return self
    end,
    profile_metadata_load = function (self, func)
        self.on_load_profile_metadata = func
        return self
    end,
    data = {}
}
local resetSaveDataOnNextEvent = false
local hasLoadedOnce = false
local mainmenu_old = Game.main_menu
function Game:main_menu(change_context)
    hasLoadedOnce = false
    mainmenu_old(self, change_context)
    FaeLib.Builtin.Events.MainMenuOpened:invoke()
end

FaeLib.UI = FaeLib.UI or {}
FaeLib.Builtin.CreateCard = function (key)
---@diagnostic disable-next-line: missing-fields
    return SMODS.create_card({area={T={x=0,y=0,w=0,h=0}}, key = key})
end
local lastProfileIndex = 0
FaeLib.Builtin.Events.Saving.SaveProfile:register(function (profile)
    if lastProfileIndex ~= G.SETTINGS.profile or not hasLoadedOnce then
        hasLoadedOnce = true
        print("Hasn't loaded yet, need to load manually!")
        G.PROFILES[G.SETTINGS.profile].faelib = G.PROFILES[G.SETTINGS.profile].faelib or {}
        print(lastProfileIndex)
        for index, value in pairs(SaveDataStorage) do
            G.PROFILES[G.SETTINGS.profile].faelib[index] = G.PROFILES[G.SETTINGS.profile].faelib[index] or {}
            if lastProfileIndex ~= 0 then
                value.on_save_profile(G.PROFILES[lastProfileIndex].faelib[index])
            end
            value.on_load_profile_metadata()
            value.on_load_profile(G.PROFILES[G.SETTINGS.profile].faelib[index])
        end
        lastProfileIndex = G.SETTINGS.profile
    end
    profile.faelib = profile.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        profile.faelib[index] = value.data or {}
        value.on_save_profile(profile.faelib[index])
    end
end)
FaeLib.Builtin.Events.Saving.LoadMetadata:register(function (profile)
    profile.faelib = profile.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        profile.faelib[index] = profile.faelib[index] or {}
        value.on_load_profile_metadata(profile.faelib[index])
    end
end)
FaeLib.Builtin.Events.Saving.SaveSettings:register(function (profile)
    profile.faelib = profile.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        profile.faelib[index] = profile.faelib[index] or {}
        value.on_save_settings(profile.faelib[index])
    end
end)
FaeLib.Builtin.Events.Saving.SaveRun:register(function (profile)
    profile.faelib = profile.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        profile.faelib[index] = profile.faelib[index] or {}
        value.on_run_save(profile.faelib[index])
    end
end)


FaeLib.Builtin.Events.Saving.LoadProfile:register(function (data)
    -- data.faelib = data.faelib or {}
    -- for index, value in pairs(SaveDataStorage) do
    --     data.faelib[index] = data.faelib[index] or {}
    --     value.on_load_profile(data.faelib[index])
    -- end
end)

FaeLib.Builtin.Events.Saving.LoadRun:register(function (data)
    data.faelib = data.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        data.faelib[index] = data.faelib[index] or {}
        value.on_new_run(data.faelib[index])
    end
end)

FaeLib.Builtin.Events.Saving.LoadSettings:register(function (data)
    data.faelib = data.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        data.faelib[index] = data.faelib[index] or {}
        value.on_load_settings(data.faelib[index])
    end
end)

FaeLib.Builtin.Events.Saving.NewRun:register(function (data)
    data.faelib = data.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        data.faelib[index] = data.faelib[index] or {}
        value.on_new_run(data.faelib[index])
    end
end)
FaeLib.Builtin.Events.Saving.DeleteRun:register(function (data)
    data.faelib = data.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        data.faelib[index] = data.faelib[index] or {}
        value.on_run_delete(data.faelib[index])
    end
end)
FaeLib.Builtin.Events.Saving.RunDataReset:register(function (data)
    data.faelib = data.faelib or {}
    for index, value in pairs(SaveDataStorage) do
        data.faelib[index] = data.faelib[index] or {}
        value.on_reset_run_data(data.faelib[index])
    end
end)
FaeLib.Builtin.StripDecimalAfter = function(num, amount)
    amount = amount or 2
    return tonumber(string.format("%."..amount.."f", num))
end
FaeLib.Builtin.CurrentlyDraggedCard = nil
FaeLib.Builtin.PreviouslyDraggedCard = nil
local cdDrag = Card.drag or Moveable.drag
function Card:drag(offset)
    cdDrag(self, offset)
    FaeLib.Builtin.CurrentlyDraggedCard = self
end

local cdRemoveFromArea = Card.remove_from_area
function Card:remove_from_area()
    local a = self.area
    cdRemoveFromArea(self)
    if (self.config.center.on_removed_from_area) then self.config.center:on_removed_from_area(self, a) end
    if (self.on_removed_from_area) then self:on_removed_from_area(self, a) end
end
local cdaEmplace = CardArea.emplace
function CardArea:emplace(card, location, stay_flipped)
    local c = cdaEmplace(self, card, location, stay_flipped)
    if (self.on_card_added) then self:on_card_added(card) end
    if (card.on_added_to_area) then card:on_added_to_area(self, location, stay_flipped) end
    if (card.config.center.on_added_to_area) then card.config.center:on_added_to_area(card, self, location, stay_flipped) end
    return c
end
local cdaRemoveFromArea = CardArea.remove_card
function CardArea:remove_card(card, discarded_only)
    local c = cdaRemoveFromArea(self, card, discarded_only)
    if (self.on_card_removed) then self:on_card_removed(card) end
    return c
end
local cdaUpdate = CardArea.update
function CardArea:update(dt)
    if self.first_frame then
        self.first_frame = false
        self.__first_frame_proc = true
    elseif not self.__first_frame_proc then
        self.first_frame = true
    end
    cdaUpdate(self, dt)
    -- self.states.hover.can = true
    self.states.collide.can = true
    
end
FaeLib.TableContains = function(table, element)
    for key, value in pairs(table) do
        if value == element then
            return key
        end
    end
    return false
end
local cdUpdate = Card.update
function Card:update(dt)
    self.config.stackable = self.config.stackable or self.config.center.stackable or false
    if self.config.center.post_create and not self.___created then
        self.config.center:post_create(self)
        self.___created=true
    end
    cdUpdate(self, dt)
    if FaeLib.Builtin.CurrentlyDraggedCard == self then
        if not self.states.drag.is then
            FaeLib.Builtin.CurrentlyDraggedCard = nil
            FaeLib.Builtin.PreviouslyDraggedCard = self
        end
    end
    self.states.drag.was_2f = self.states.drag.was or self.states.drag.is
    self.states.drag.was = self.states.drag.is
    if self.states.drag.is then
        if not self.config.transfer_on_release then
            for i, k in ipairs(G.CONTROLLER.collision_list) do
                if k and k:is(CardArea) then
                    if k ~= self.area then
                        if self.config.transferrable_areas and #self.config.transferrable_areas > 0 then
                            
                            local t = (self.config.transferrable_areas and FaeLib.TableContains(self.config.transferrable_areas, k))
                            if t and self.config.transferrable_areas then
                                for key, value in pairs(self.config.transferrable_areas) do
                                    if k.config.id then
                                        print(tprint(value))
                                    end
                                    t = t or k.id and value.for_id and value.for_id == k.id
                                    t = t or value.for_type and k.config.type == value.for_type
                                end
                                for key, value in pairs(self.config.transferrable_areas) do
                                    if value == k then
                                        local can_add = true
                                        if value.can_add_card then
                                            can_add = value:can_add_card(self)
                                        end
                                        if can_add then
                                            self.area:remove_card(self)
                                            value:emplace(self)
                                        end
                                    end
                                end
                            end
                           
                        elseif self.config.transferrable then
                            local can_add = true
                            if k.can_add_card then
                                can_add =  k:can_add_card(self)
                            end
                            if can_add then
                                self.area:remove_card(self)
                                k:emplace(self)
                            end
                        end
                    end
                end
            end
        end
    end
end
local cdStopDrag = Card.stop_drag
function Card:stop_drag()
    if cdStopDrag then
        cdStopDrag(self)
    end
    
    for i, k in ipairs(G.CONTROLLER.collision_list) do
        -- print(tprint(k))
        if k and k:is(Card) and k ~= self then
            if self.config.stackable then
                if k.config.stackable and k.config.center_key == self.config.center_key and ((k.edition or {}).type or "none") == ((self.edition or {}).type or "none") and ((k.can_stack and k:can_stack(self)) or not k.can_stack)then
                    k.stack_count = (k.stack_count or 1) + (self.stack_count or 1)
                    k:juice_up()
                    self.area:remove_card(self)
                    if k.on_merged and type(k.on_merged) == "function" then
                        k:on_merged(self, k.stack_count, self.stack_count)
                    end
                    G.E_MANAGER:add_event(Event({
                        trigger = "immediate",
                        func = function ()
                            self:remove()
                            return true
                        end
                    }))
                    
                end
            end
        end
    end
    if self.config.transfer_on_release then
        for i, k in ipairs(G.CONTROLLER.collision_list) do
            if k and k:is(CardArea) then
                if k ~= self.area then
                    if self.config.transferrable_areas and #self.config.transferrable_areas > 0 then
                        if FaeLib.TableContains(self.config.transferrable_areas, k) then
                            self.area:remove_card(self)
                            k:emplace(self)
                        end
                    elseif self.config.transferrable then
                        self.area:remove_card(self)
                        k:emplace(self)
                        
                    end
                end
            end
        end
    end
end


local cdDraw = Card.draw
function Card:draw(layer)
    cdDraw(self, layer)
    if self.config.stackable then
		love.graphics.setColor(0,0,0,0.75 )
		love.graphics.printf("x"..(self.stack_count or 1),((self.VT.x + self.VT.w/1.15)*G.TILESCALE*G.TILESIZE)-1,((self.VT.y+self.VT.h/1.15)*G.TILESCALE*G.TILESIZE)-1, 100)
		love.graphics.printf("x"..(self.stack_count or 1),((self.VT.x + self.VT.w/1.15)*G.TILESCALE*G.TILESIZE)-2,((self.VT.y+self.VT.h/1.15)*G.TILESCALE*G.TILESIZE)-2, 100)
		love.graphics.printf("x"..(self.stack_count or 1),((self.VT.x + self.VT.w/1.15)*G.TILESCALE*G.TILESIZE)-3,((self.VT.y+self.VT.h/1.15)*G.TILESCALE*G.TILESIZE)-3, 100)
		love.graphics.setColor(1,1,1,1)
		love.graphics.printf("x"..(self.stack_count or 1),((self.VT.x + self.VT.w/1.15)*G.TILESCALE*G.TILESIZE)-3,((self.VT.y+self.VT.h/1.15)*G.TILESCALE*G.TILESIZE)-3, 100)
    end
end
local function expanding_random(items, weights)
  local list = {}
  for _, item in ipairs(items) do
    local n = weights[item] * 100
    for i = 1, n do table.insert(list, item) end
  end
  return function()
    return list[math.random(1, #list)]
  end
end
local function pick_weighted_element(elements)
    local total_weight = 0
    local weights = {}

    -- Assign decreasing weights to lower-indexed elements
    for i = 1, #elements do
        local weight = 1 / i
        weights[i] = weight
        total_weight = total_weight + weight
    end

    -- Generate a weighted random selection
    local random_value = math.random() * total_weight
    local accumulated_weight = 0

    for i = 1, #elements do
        accumulated_weight = accumulated_weight + weights[i]
        if random_value <= accumulated_weight then
            return elements[i]
        end
    end
end

FaeLib.Builtin.GenCardForPool = function(pool_type, max_rarity)
    max_rarity = max_rarity or #SMODS.ObjectTypes[pool_type].rarity_pools
    local elements = {}

    for i = 1, max_rarity * 10 do
        local idx = math.min(math.ceil(i * 0.1),max_rarity)
        local element = pseudorandom_element(SMODS.ObjectTypes[pool_type].rarity_pools[idx])
        elements[#elements+1] = element
        
    end
    return pick_weighted_element(elements)
end





FaeLib.Builtin.Events.ResetBlinds:register(function ()
    print("Reset blinds (Boss blind completed!)")
end)