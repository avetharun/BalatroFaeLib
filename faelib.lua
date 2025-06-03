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

assert(SMODS.load_file("blind_utils.lua"))()
assert(SMODS.load_file("init.lua", "faelib"))()
assert(SMODS.load_file("core/enums.lua", "faelib"))()
assert(SMODS.load_file("extensions/debugplus.lua"))()
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
        if key == "Lovely" or key == "Balatro" or key == "faelib" or not value.can_load then
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
    return {btn_id=tbl.button_id,n=G.UIT.R, config={ref_table = tbl, r = 0.08, padding = 0.15, align = "tl", hover = false, shadow = true, colour = tbl.color or G.C.UI.BACKGROUND_INACTIVE, one_press = false, button = 'faelib_button_proxy', }, nodes={
        {n=G.UIT.T, config={text = localize("b_"..tbl.button_id),colour = G.C.UI.TEXT_LIGHT, scale = 0.45, align = "tl", shadow = true}}
        }}
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
local function lerp(a,b,t) return a * (1-t) + b * t end
local function easeInOutQuint(x)
    if x < 0.5 then
        return 16 * x * x * x * x * x
    else
        return 1 - ((-2 * x + 2) ^ 5) / 2
    end
end
local Tweeners = {}
local function tweener_update_proc(self, dt)
    self.elapsed_time = self.elapsed_time + dt
    -- assume tween is a delay/wait tween
    if self.name == nil or self.table == nil then
        return self.elapsed_time >= self.duration
    end
    if self.elapsed_time < self.duration then
        if type(self.name) == "table" then
            -- if name is a table, we assume it's a table of names to tween
            for _, name in ipairs(self.name) do
                self.set(self, name, self.easing(self.from[name], self.to[name], self.elapsed_time / self.duration))
            end
            self.on_set(self.table, self.name, self.table)
        else
            -- otherwise, we assume it's a single name
            self.set(self, self.name, self.easing(self.from, self.to, self.elapsed_time / self.duration))
            self.on_set(self.table, self.name, self.table[self.name])
        end
    elseif self.elapsed_time >= self.duration then
        self.table[self.name] = self.to
        if self.delay_started then
            self.on_complete("DELAY_STARTED")
        end
        self.delay_started = false
        if (self.delay_tail and self.delay_tail > 0) then
            self.delay_tail = self.delay_tail - dt
            if (self.do_while and type(self.do_while) == "function") then
                self:do_while(table)
            end
            if self.delay_tail > 0 then
                return false
            else
                self.on_complete("DELAY_COMPLETE")
            end
        end
        if self.next_tweener then
            Tweeners[self.index] = self.next_tweener
            self.next_tweener.index = self.index
            self.next_tweener.autorun = true
            return false
        elseif self.destroy_when_complete then
            Tweeners[self.index] = nil
        end
        return true
    end
    return false
end
class 'FaeLib.Tweener' {
    constructor = function (self, name, table, duration, easing, from, to, autorun, on_complete, on_set, destroy_when_complete)
        self.table = table
        self.name = name
        self.duration = duration or 1
        self.easing = easing or lerp
        self.from = from or 0
        self.to = to or 1
        self.elapsed_time = 0
        self.autorun = autorun
        self.completed = false
        self.next_tweener = nil
        self.delay_started = true
        self.on_complete = on_complete or function (delay_completed) end
        self.on_set = on_set or function (table, name, value) end
        self.destroy_when_complete = destroy_when_complete or true
        if self.autorun then
            self.index = #Tweeners + 1
            Tweeners[self.index] = self
        else 
            self.autorun = true
        end
    end,
    set = function (self, name, value)
        self.table[name] = value
    end,
    and_reverse = function (self)
        return self.and_then(self, new 'FaeLib.Tweener' (self.name, self.table, self.duration, self.easing, self.to, self.from, false, self.on_complete, self.on_set))
    end,
    and_then = function (self, tweener)
        self.next_tweener = tweener
        return self.next_tweener
    end,
    then_wait = function (self, delay, do_while)
        if not delay or delay < 0 then
            return self -- no delay, just return self
        end
        self.delay_tail = delay or 0
        self.do_while = do_while
        return self
    end,
    run = function (self)
        if self.autorun then
            return
        end
        self.autorun = true
        self.index = #Tweeners + 1
        Tweeners[self.index] = self
    end,
}
class 'FaeLib.CardMovement' {
    constructor = function(self, card, target_x, target_y, duration, delay, delay_started, delay_ended, while_delaying, movement_completed)
        self.card = card
        self.target_x = target_x
        self.target_y = target_y
        self.duration = (duration or 1)
        new 'FaeLib.Tweener' (
            {"x", "y"},
            {x=0,y=0},
            self.duration,
            smoothstep,
            {x = card.T.x, y = card.T.y},
            {x = self.target_x, y = self.target_y},
            true,
            function (completion_state)
                if completion_state == "DELAY_STARTED" and delay_started and not self.started_once then
                    self.started_once = true
                    delay_started(card)
                    return
                end
                if completion_state == "DELAY_COMPLETE" and delay_ended and not self.completed_once then
                    self.completed_once = true
                    delay_ended(card)
                    return
                end
                if movement_completed and completion_state ~= "DELAY_COMPLETE" and completion_state ~= "DELAY_STARTED" then
                    -- movement_completed(card)
                end
            end,
            function (table, name, value)
                card:hard_set_T(value.x, value.y, card.T.w, card.T.h)
            end
        ):then_wait(delay or 0.1, function (_self, table)
            card:hard_set_T(target_x, target_y, card.T.w, card.T.h)
            if while_delaying then
                while_delaying(_self, table)
            end
        end):and_reverse()
    end,
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
        if not dont_assign then
            FaeLib.V.FrameTasks[self.index] = self
        end
    end,
    and_then = function (self, func, repeating, duration, should_stop_repeating, delay_before_starting)
        local next_task = new 'FaeLib.Task'(func, repeating, duration, should_stop_repeating, true, true)
        self.__tail.next = next_task
        self.__tail.next_delay_time = delay_before_starting or self.next_delay_time or 0
        self.__tail = self.__tail.next
        return self
    end,
    with_data = function(self, data)
        self.data = data
        return self
    end,
    with_duration = function(self, duration)
        self.duration = duration
        return self
    end,
    with_delay = function(self, duration)
        self.next_delay_time = duration
        return self
    end
}

local game_main_menu_ref = Game.main_menu
---@diagnostic disable-next-line: duplicate-set-field
function Game:main_menu(change_context)
    local ret = game_main_menu_ref(self, change_context)
    
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
    for _, tweener in ipairs(Tweeners) do
        if (tweener_update_proc(tweener, dt)) then
            Tweeners[tweener.index] = nil
            if tweener.on_complete then
                tweener.on_complete(tweener.table)
            end
        end
    end
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
        if not card.children.faelib_button_box then
            card.children.faelib_button_box = UIBox{
                definition = {n=G.UIT.ROOT, config = {padding = 0, colour = G.C.CLEAR}, nodes=nodes},
                config = {align="cr",
                    parent =card}
            }
            card.children.faelib_button_box.nodes = card.children.faelib_button_box.nodes or {}
        end
        local update = false
        for key, button in pairs(CardButtons) do
            local has_button_already = false
            local existing_button = nil
            card.children.faelib_button_box.nodes = card.children.faelib_button_box.nodes or {}
            for i = 1, #card.children.faelib_button_box.nodes do
                local child = card.children.faelib_button_box.nodes[i]
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
                    tbl1.side = button.side
                    tbl1.alignment = tbl.side
                    tbl1.card = card
                    card.children.faelib_button_box.nodes[#card.children.faelib_button_box.nodes + 1] = faelib_create_button(tbl1)
                    update = true
                end
            elseif card.children.faelib_button_box.nodes then
                for i = 1, #card.children.faelib_button_box.nodes do
                    local child = card.children.faelib_button_box.nodes[i]
                    if child and child.btn_id == key then
                        card.children.faelib_button_box.nodes[i] = nil
                        FaeLib.print("Removing button: " .. key)
                        update = true
                    end
                end
            end
            if update then
                local new_node = UIBox{
                    definition = {n=G.UIT.ROOT, config = {padding = 0.1, colour = G.C.CLEAR,minw = card.T.w,minh = card.T.h}, nodes=card.children.faelib_button_box.nodes},
                    config = {align="cr",
                    minw = 1,
                    minh = 1,
                    emboss = 0,
                    padding = 0.5,
                    hover=false,
                    offset = {x = 0, y = 0},
                parent =card}}
                new_node.nodes = card.children.faelib_button_box.nodes
                card.children.faelib_button_box:remove()
                card.children.faelib_button_box = new_node
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
class 'FaeLib.CardButton' {
    constructor = function (self, key, alignment, run_action, color, can_display)
        self.can_display = can_display or function (card)
            return true
        end
        self.key = key
        self.side = alignment
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
    FaeLib.Builtin.AddCardToSlot(card, G.jokers)
end
FaeLib.Builtin.NumSelectedCards = function ()
    local amt = 0
    if G.hand then
        for _, value in ipairs(G.hand.cards) do
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
    return G.HUD_blind:get_UIE_by_ID('HUD_blind_name').config.object.config.string[1].ref_table.config.blind.key
end
FaeLib.Tags.ForagerCards = FaeLib.CreateOrGetTag("faelib:forager_cards", "Card")
FaeLib.Tags.FoodCards = FaeLib.CreateOrGetTag("faelib:food_cards", "Card")
FaeLib.Tags.Blinds = FaeLib.CreateOrGetTag("balatro:blinds", "Blind")
FaeLib.Tags.BossBlinds = FaeLib.CreateOrGetTag("balatro:boss_blinds", "Blind")
FaeLib.Tags.FinalBlinds = FaeLib.CreateOrGetTag("balatro:final_blinds", "Blind")

FaeLib.Tags.Blinds:add("bl_small")
FaeLib.Tags.Blinds:add("bl_big")

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

FaeLib.Tags.FinalBlinds:add("bl_final_acorn")
FaeLib.Tags.FinalBlinds:add("bl_final_heart")
FaeLib.Tags.FinalBlinds:add("bl_final_bell")
FaeLib.Tags.FinalBlinds:add("bl_final_leaf")
FaeLib.Tags.FinalBlinds:add("bl_final_vessel")


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
local love_callbacks = {
    mousepressed = love.mousepressed,
    mousereleased = love.mousereleased,
    mousemoved = love.mousemoved,
    draw = love.draw,
    textinput = love.textinput,
    wheelmoved = love.wheelmoved
}

-- love.textinput = function (t)
    -- love_callbacks.textinput(t)
-- end

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
love.mouse.was_pressed = function (button) return FaeLib.Mouse.State.just_pressed[button] or false end
love.mouse.was_released = function (button) return FaeLib.Mouse.State.just_released[button] or false end
love.draw = function ()
    for index, _ in ipairs(FaeLib.Mouse.State.just_pressed) do
        FaeLib.Mouse.State.just_pressed[index] = false
    end
    for index, _ in ipairs(FaeLib.Mouse.State.just_released) do
        FaeLib.Mouse.State.just_released[index] = false
    end
    FaeLib.Builtin.Events.RenderPre:invoke()
    love_callbacks.draw()
    FaeLib.Builtin.Events.RenderPost:invoke()
    
    local dt= love.timer.getDelta()
    for _, task in ipairs(FaeLib.V.FrameTasks) do
        if task.run then
            task.next_delay_time = task.next_delay_time or 0
            if task.duration > 0 or task.next_delay_time > 0 then
                if task.func then
                    task:func(dt)
                end
                if task.duration <= 0 and task.next_delay_time > 0 then
                    task.next_delay_time = task.next_delay_time - dt
                end
                if task.duration > 0 then
                    task.duration = task.duration - dt
                end
                goto continue
            end
            if task.repeating and task.should_stop_repeating() then
                if task.next then
                    task.next.run=true
                    task.next.data = task.data
                    table.remove(FaeLib.V.FrameTasks, _)
                    FaeLib.V.FrameTasks[#FaeLib.V.FrameTasks+1] = task.next
                    if task.next.func then
                        task.next:func(dt)
                    end
                else
                    FaeLib.V.FrameTasks[_] = nil
                end
                goto continue
            end
            if not task.repeating and (task.duration <= 0 and task.next_delay_time <= 0) then
                if task.next then
                    task.next.run=true
                    task.next.data = task.data
                    table.remove(FaeLib.V.FrameTasks, _)
                    FaeLib.V.FrameTasks[#FaeLib.V.FrameTasks+1] = task.next
                    if task.next.func then
                        task.next:func(dt)
                    end
                else
                    table.remove(FaeLib.V.FrameTasks, _)
                end
                goto continue
            end
        end
        ::continue::
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
	local w = love.graphics.getFont():getWidth(text)
	local h = y_align and w or 0
	love.graphics.print(text, x - w*0.5, y - h*0.5, rads, scx, scy, kx, ky)
end
FaeLib.APIs.Drawing.text_ease_alpha = function(text, x, y, rgb_colour, fade_in_time, hold_time, fade_out_time, easing)
    easing = easing or lerp
    new 'FaeLib.Task'(function (self, delta)
        self.data.color[4] = math.min(easing(self.data.color[4], 1, delta / fade_in_time), 1)
        love.graphics.setColor(self.data.color[1], self.data.color[2], self.data.color[3], self.data.color[4])
        love.graphics.print(text, self.data.pos.x, self.data.pos.y)
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
            love.graphics.print(text, self.data.pos.x, self.data.pos.y)
        end, false, fade_out_time
    )
end
FaeLib.APIs.Drawing.text_ease_alpha_centered = function(text, x, y, rgb_colour, fade_in_time, hold_time, fade_out_time, easing, center_y)
    easing = easing or lerp
    new 'FaeLib.Task'(function (self, delta)
        self.data.color[4] = math.min(easing(self.data.color[4], 1, delta / fade_in_time), 1)
        love.graphics.setColor(self.data.color[1], self.data.color[2], self.data.color[3], self.data.color[4])
        FaeLib.APIs.Drawing.text_centered(text, self.data.pos.x, self.data.pos.y, center_y)
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
            FaeLib.APIs.Drawing.text_centered(text, self.data.pos.x, self.data.pos.y)
        end, false, fade_out_time
    )
end