--- STEAMODDED HEADER
--- MOD_NAME: FaeLib
--- MOD_ID: faelib
--- MOD_AUTHOR: [feintha]
--- MOD_DESCRIPTION: Common utility functions for modding Balatro.
--- PRIORITY: -9999
--- 
--- 
----------------------------------------------
------------MOD CODE -------------------------

assert(SMODS.load_file("blind_utils.lua"))()
assert(SMODS.load_file("init.lua", "faelib"))()
assert(SMODS.load_file("core/enums.lua", "faelib"))()
assert(SMODS.load_file("extensions/debugplus.lua"))()


FaeLib.Builtin.ButtonVisibilityFuncs = FaeLib.Builtin.ButtonVisibilityFuncs or {}
local CACHED_LOCALIZATION_COLORS = {}
local lc = loc_colour
local CardButtons = {}

FaeLib.DebugState = FaeLib.Enums.DebugState.Enabled
local unknown_tbl = {key = "unknown"}
FaeLib.APIs.Debugging = {
    SetDebugState = function (state) end
}

FaeLib.AdditionalTooltips = false

local faelibloc = init_localization
function init_localization()
    faelibloc()
    print("FAELIB - Initializing localization utilities")
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
        print("Loaded buildin FaeLib colours")
        
    end
    for key, value in pairs(SMODS.Mods) do
        if key == "Lovely" or key == "Balatro" or key == "faelib" or not value.can_load then
            goto skip
        end
        local colours = (SMODS.load_file("faelib/colours.lua", value.id) or function()end)()
        if colours then
            print("Loaded colours for mod: " .. value.id)
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
        print("Error: ref_table is nil in faelib_button_proxy")
        return
    end
    if tbl and tbl.button then
        local card = tbl.card
        print("Running action for button: " .. tbl.button_id)
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
        if (self.delay_after and self.delay_after > 0) then
            self.delay_after = self.delay_after - dt
            if (self.do_while and type(self.do_while) == "function") then
                self:do_while(table)
            end
            if self.delay_after > 0 then
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
        self.delay_after = delay or 0
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
class 'FaeLib.FrameTask' {
    constructor = function(self, func, repeating, duration, should_stop_repeating)
        if not func or type(func) ~= "function" then
            error("FrameTask requires a function as an argument")
        end
        if repeating and (duration) then
            if duration > 0 then
                error("FrameTask cannot be repeating and have a duration.")
            end
        end
        self.duration = duration or 0
        self.func = func
        self.index = #FaeLib.V.FrameTasks + 1
        self.repeating = repeating or false
        self.should_stop_repeating = should_stop_repeating or function () return false end
        FaeLib.V.FrameTasks[self.index] = self
    end
}
interface 'FaeLib.IBaseEvent' { 'callback' }
interface 'FaeLib.IBaseEventHandler' { 'register', 'get_callbacks' }
class 'FaeLib.AbstractEvent' : implements 'FaeLib.IBaseEvent' {
    constructor = function(self, callback)
        self.callback = callback
    end,
    callback = function (self, ...)end
}
class 'FaeLib.AbstractEventHandler' : implements 'FaeLib.IBaseEventHandler' {
    constructor = function(self)
        self._callbacks = {}
    end,
    register = function(self, callback)
        if type(callback) ~= "function" then
            error("Callback must be a function")
        end
        self._callbacks[#self._callbacks + 1] = new 'FaeLib.AbstractEvent'(callback)
    end,
    invoke = function(self, ...)
        for _, callback in ipairs(self._callbacks) do
            if callback and callback.callback then
                callback:callback(unpack(arg))
            end
        end
    end,
    get_callbacks = function(self)
        return self._callbacks
    end,
}

function FaeLib.render()
    local dt= love.timer.getDelta()
    for _, task in ipairs(FaeLib.V.FrameTasks) do
        if task.func then
            task.func(dt)
            if task.duration > 0 then
                task.duration = task.duration - dt
                goto continue
            end
            if task.repeating and task.should_stop_repeating() then
                FaeLib.V.FrameTasks[task.index] = nil
            elseif not task.repeating or task.duration <= 0 then
                FaeLib.V.FrameTasks[task.index] = nil
            end
        end
        ::continue::
    end
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
                    print("Adding button: " .. key)
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
                        print("Removing button: " .. key)
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
local genui = SMODS.Center.generate_ui
SMODS.Center.generate_ui = function (self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
    local ui_result = genui(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
    
    local ignore_genui_task = false
    if (FaeLib.AdditionalTooltips) then
        if not card then
            card = self:create_fake_card()
        end
        local ability = card.ability or unknown_tbl
        local edition = card.edition or unknown_tbl
        local seal = card.seal or unknown_tbl

        info_queue[#info_queue+1] = {set = "Other", key = "faelib_extended_info_tooltip", vars = {self.key or "unknown", self.set or "unknown", ability.key, edition.key, seal.key}}
    end
    return ui_result
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
FaeLib.Builtin.Events.CardRemoved = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.ConsumableUsed = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindStarted = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindSkipped = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindCompleted = new 'FaeLib.AbstractEventHandler' ()
FaeLib.Builtin.Events.BlindFailed = new 'FaeLib.AbstractEventHandler' ()

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
        "seal:\"#5#\""
    }
)

FaeLib.Tags.Blinds = new 'FaeLib.Tag<Blind>'("balatro:blinds")
FaeLib.Tags.BossBlinds = new 'FaeLib.Tag<Blind>'("balatro:boss_blinds")
FaeLib.Tags.FinalBlinds = new 'FaeLib.Tag<Blind>'("balatro:final_blinds")

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

