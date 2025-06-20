assert(SMODS.load_file("init.lua", "faelib"))()
FaeLib.UI = FaeLib.UI or {}
FaeLib.UI.V = FaeLib.UI.V or {}

-- Balatro XY -> love XY
local function scaleXY(x, y)
    return {x=x*G.TILESCALE*G.TILESIZE, y=y*G.TILESCALE*G.TILESIZE}
end
-- Balatro XYWH -> love XYWH
local function scaleXYWH(x, y, w, h)
    local xy = scaleXY(x, y)
    local wh = scaleXY(w, h)
    return {x=xy.x, y=xy.y, w=wh.x, h=wh.y}
end
-- love XY -> Balatro XY
local function unScaleXY(x, y)
    return {x=x/G.TILESCALE/G.TILESIZE, y=y/G.TILESCALE/G.TILESIZE}
end
-- love XYWH -> Balatro XYWH
local function unScaleXYWH(x, y, w, h)
    local xy = unScaleXY(x, y)
    local wh = unScaleXY(w, h)
    return {x=xy.x, y=xy.y, w=wh.x, h=wh.y}
end
FaeLib.scaleXY = scaleXY
FaeLib.unScaleXY = unScaleXY
FaeLib.scaleXYWH = scaleXYWH
FaeLib.unScaleXYWH = unScaleXYWH

 
local function rectsIntersect(rect1, rect2)
    return rect1.x < rect2.x + rect2.w and
           rect1.x + rect1.w > rect2.x and
           rect1.y < rect2.y + rect2.h and
           rect1.y + rect1.h > rect2.y
end
function isPointInRect(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.w and
           y >= rect.y and y <= rect.y + rect.h
end
FaeLib.UI.SlidingCardArea = CardArea:extend()
G.FUNCS.__DO_NOTHING = function() end
function FaeLib.UI.SlidingCardArea:init(X, Y, W, H, config)
    self.container_size = config.container_size or {1,5}
    self.slider_size = config.slider_size or 0.2
    self.cards_per_page = config.cards_per_page or 5
    H = self.slider_size + H
    CardArea.init(self, X, Y, W, H, config)
    self.scroll_offset = 0
    self.bar_background_colour = self.bar_background_colour or G.C.BLACK
    self.bar_colour = self.bar_colour or G.C.RED
    self.background_colour = self.background_colour or HEX("171f26ff")
    self.card_padding= config.card_padding or 0.1
    self.__lf_sz=1
    self.slider_width = config.slider_width or 0.333
    self.children.scrollbar_hover = UIBox{
        definition = {n=G.UIT.R, config={}, nodes = {
			{n = G.UIT.C, config = {minw=W, minh=self.slider_size, colour = self.bar_background_colour, r=0.1, padding = 0.1,emboss=0.1}}
        }},
        config = {align="tm",
            colour = G.C.CLEAR,
            offset = {
                x=0,
                y=H
            },
            parent = self,
            major=self,
            focus_args = { snap_to = true },
            button = "__DO_NOTHING"
        }
    }
    self.children.scrollbar_bar = UIBox{
        definition = {n=G.UIT.R, config={}, nodes = {
			{n = G.UIT.C, config = {maxw=self.slider_width, minw=self.slider_width, minh=self.slider_size, colour = self.bar_colour, padding = 0.1, r=0.1,emboss=0.1}}
        }},
        config = {align="tl",
            colour = G.C.CLEAR,
            offset = {
                x=0,
                y=H
            },
            parent = self,
            major=self
        }
    }
    self.children.background = UIBox{
        definition = {n=G.UIT.R, config={}, nodes = {
			{n = G.UIT.C, config = {minw=W, minh=H-self.slider_size - 0.2, colour = self.background_colour, padding = 0.1, emboss=0.1}}
        }},
        config = {align="cm",
            colour = G.C.CLEAR,
            offset = {
                x=0,
                y=0.1
            },
            parent = self,
            major=self
        }
    }
    self.children.background_top = UIBox{
        definition = {n=G.UIT.R, config={}, nodes = {
			{n = G.UIT.C, config = {minw=W, minh=H-self.slider_size, colour = self.background_colour, padding = 0.1, r=0.1}}
        }},
        config = {align="cm",
            colour = G.C.CLEAR,
            offset = {
                x=0,
                y=-0.4
            },
            parent = self,
            major=self
        }
    }
    self.children.lt = UIBox{
        definition = {n=G.UIT.R, config={}, nodes = {
			{n=G.UIT.C, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'triggerleft', type = 'none', orientation = 'cr', scale = 0.7, offset = {x = 0.1, y = 0}}}, nodes = {}}
        }},
        config = {align="bl",
            colour = G.C.CLEAR,
            offset = {
                x=-15/20,
                y=-5/20
            },
            parent = self,
            major=self
        }
    }
    self.children.rt = UIBox{
        definition = {n=G.UIT.R, config={}, nodes = {
			{n=G.UIT.C, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'triggerright', type = 'none', orientation = 'cl', scale = 0.7, offset = {x = 0.1, y = 0}}}, nodes = {}}
        }},
        config = {align="br",
            colour = G.C.CLEAR,
            offset = {
                x=10/20,
                y=-5/20
            },
            parent = self,
            major=self
        }
    }
end

function FaeLib.UI.SlidingCardArea:align_cards()
    local t = 0.25
    self.scroll_offset = (math.min(1,math.max(0,self.scroll_offset)))
    local o = -self.scroll_offset
    for k, card in ipairs(self.cards) do
        if not card.states.drag.is then 
            card.T.r = (G.SETTINGS.reduced_motion and 0 or 1)*0.02*math.sin(2*G.TIMERS.REAL+card.T.x)
            local max_cards = math.max(#self.cards, self.config.temp_limit)
            card.T.x = (o * self.__lf_sz) + self.T.x + t
            local highlight_height = G.HIGHLIGHT_H
            if not card.highlighted then highlight_height = 0 end
            card.T.y = self.T.y + self.T.h/2 - card.T.h/2 - highlight_height + (G.SETTINGS.reduced_motion and 0 or 1)*0.03*math.sin(0.666*G.TIMERS.REAL+card.T.x) - self.slider_size - 0.1
            card.T.x = card.T.x + card.shadow_parrallax.x/30
        end
        t = t + card.T.w + self.card_padding
    end
    table.sort(self.cards, function (a, b) return a.T.x + a.T.w/2 < b.T.x + b.T.w/2 end)
    self.__lf_sz = t - (self.T.w/2)
end
function FaeLib.UI.SlidingCardArea:in_area(card)
   return rectsIntersect(self.VT, card.VT) 
end

FaeLib.UI.WrapUIBox = function(node, parent)
    local use_row = node.n and node.n == G.UIT.R and false or true
	local box = UIBox{
		definition = {
			n=G.UIT.R, config={colour=G.C.CLEAR},
			nodes={
				(node.is and node:is(Node)) and {n=G.UIT.O, config={colour=G.C.WHITE, object = node}} or node,
			}
		},
		config={type="cm",colour=G.C.CLEAR,
            parent = parent
		}
	}
	box.Translation = {x=0,y=0}
	return box
end

function FaeLib.UI.SlidingCardArea:draw()
    if not self.children then return end
    self.children.background_top:draw()
    self.children.background:draw()
    self.children.rt:draw()
    self.children.lt:draw()
	love.graphics.push()
    local roomtl = scaleXY(G.ROOM.T.x, G.ROOM.T.y)
    local mp = G.CURSOR.T
    local hovering_scrollbar = false
    for i, k in ipairs(G.CONTROLLER.collision_list) do
        if k == self.children.scrollbar_hover then
            hovering_scrollbar = true
            break
        end
    end
    for key, value in pairs(self.cards) do
        value.states.hover.can = self:in_area(value)
    end
    if G.CONTROLLER.held_buttons["triggerleft"] then
        self.scroll_offset = self.scroll_offset - 0.75 * love.timer.getDelta()
    end
    if G.CONTROLLER.held_buttons["triggerright"] then
        self.scroll_offset = self.scroll_offset + 0.75 * love.timer.getDelta()
    end
    self.scroll_offset = (math.min(1,math.max(0,self.scroll_offset)))
    if (self.mb1_held or (love.mouse.isDown(1) and hovering_scrollbar and G.CONTROLLER.cursor_collider == nil))  then
        if not self.mb1_held then
            play_sound('generic1', 0.9 + math.random()*0.1, 0.2)
        end
        self.mb1_held = true
        self.scroll_offset = FaeLib.lerp(self.scroll_offset, (( (mp.x - self.children.scrollbar_hover.T.x)-G.ROOM.T.x) / self.children.scrollbar_hover.T.w), love.timer.getDelta() * 12)
        self.scroll_offset = (math.min(1,math.max(0,self.scroll_offset)))
    end
    if self.mb1_held and not love.mouse.isDown(1) then
        self.mb1_held = false
    end
    if not self.states.visible then return end 
    if G.VIEWING_DECK and (self==G.deck or self==G.hand or self==G.play) then return end

    local state = G.TAROT_INTERRUPT or G.STATE

    self.children.scrollbar_hover:draw()
    love.graphics.push()
    love.graphics.translate(scaleXY(self.slider_width+(self.scroll_offset * (self.children.scrollbar_hover.T.w - self.slider_width)),0).x, 0)
    self.children.scrollbar_bar:draw()
    love.graphics.pop()
    -- love.graphics.rectangle( "fill", rect.x + (self.scroll_offset * (rect.w - slw)), rect.y+rect.h - slider_size, slw, slider_size)
    
    local t = scaleXYWH(self.T.x, self.T.y, self.T.w, self.T.h)
	love.graphics.setScissor(t.x+roomtl.x,t.y+roomtl.y-99999,t.w,t.h+999999)
    self.ARGS.invisible_area_types = self.ARGS.invisible_area_types or {discard=1, voucher=1, play=1, consumeable=1, title = 1, title_2 = 1}
    if self.ARGS.invisible_area_types[self.config.type] or
        (self.config.type == 'hand' and ({[G.STATES.SHOP]=1, [G.STATES.TAROT_PACK]=1, [G.STATES.SPECTRAL_PACK]=1, [G.STATES.STANDARD_PACK]=1,[G.STATES.BUFFOON_PACK]=1,[G.STATES.PLANET_PACK]=1, [G.STATES.ROUND_EVAL]=1, [G.STATES.BLIND_SELECT]=1})[state]) or
        (self.config.type == 'hand' and state == G.STATES.SMODS_BOOSTER_OPENED) or
        (self.config.type == 'deck' and self ~= G.deck) or
        (self.config.type == 'shop' and self ~= G.shop_vouchers) then
    else
        if not self.children.area_uibox then 
                local card_count = self ~= G.shop_vouchers and {n=G.UIT.R, config={align = self == G.jokers and 'cl' or self == G.hand and 'cm' or 'cr', padding = 0.03, no_fill = true}, nodes={
                    {n=G.UIT.B, config={w = 0.1,h=0.1}},
                    {n=G.UIT.T, config={ref_table = self.config, ref_value = 'card_count', scale = 0.3, colour = G.C.WHITE}},
                    {n=G.UIT.T, config={text = '/', scale = 0.3, colour = G.C.WHITE}},
                    {n=G.UIT.T, config={ref_table = self.config, ref_value = 'card_limit', scale = 0.3, colour = G.C.WHITE}},
                    {n=G.UIT.B, config={w = 0.1,h=0.1}}
                }} or nil

                self.children.area_uibox = UIBox{
                    definition = 
                        {n=G.UIT.ROOT, config = {align = 'cm', colour = G.C.CLEAR}, nodes={
                            {n=G.UIT.R, config={minw = self.T.w,minh = self.T.h,align = "cm", padding = 0.1, mid = true, r = 0.1, colour = self ~= G.shop_vouchers and {0,0,0,0.1} or nil, ref_table = self}, nodes={
                                self == G.shop_vouchers and 
                                {n=G.UIT.C, config={align = "cm", paddin = 0.1, func = 'shop_voucher_empty', visible = false}, nodes={
                                    {n=G.UIT.R, config={align = "cm"}, nodes={
                                        {n=G.UIT.T, config={text = 'DEFEAT', scale = 0.6, colour = G.C.WHITE}}
                                    }},
                                    {n=G.UIT.R, config={align = "cm"}, nodes={
                                        {n=G.UIT.T, config={text = 'BOSS BLIND', scale = 0.4, colour = G.C.WHITE}}
                                    }},
                                    {n=G.UIT.R, config={align = "cm"}, nodes={
                                        {n=G.UIT.T, config={text = 'TO RESTOCK', scale = 0.4, colour = G.C.WHITE}}
                                    }},
                                }} or nil,
                            }},
                            card_count
                        }},
                    config = { align = 'cm', offset = {x=0,y=0}, major = self, parent = self}
                }
            end
        self.children.area_uibox:draw()
    end

    self:draw_boundingrect()
    add_to_drawhash(self)
    self.ARGS.draw_layers = self.ARGS.draw_layers or self.config.draw_layers or {'shadow', 'card'}
    for k, v in ipairs(self.ARGS.draw_layers) do
        if self.config.type == 'deck' then 
            for i = #self.cards, 1, -1 do 
                if self.cards[i] ~= G.CONTROLLER.focused.target then
                    if i == 1 or i%(self.config.thin_draw or 9) == 0 or i == #self.cards or math.abs(self.cards[i].VT.x - self.T.x) > 1 or math.abs(self.cards[i].VT.y - self.T.y) > 1  then
                        if G.CONTROLLER.dragging.target ~= self.cards[i] and self:in_area(self.cards[i]) then self.cards[i]:draw(v) end
                    end
                end
            end
        end

        if self.config.type == 'joker' or self.config.type == 'consumeable' or self.config.type == 'shop' or self.config.type == 'title_2' then 
            for i = 1, #self.cards do 
                if self.cards[i] ~= G.CONTROLLER.focused.target then
                    if not self.cards[i].highlighted then
                        if G.CONTROLLER.dragging.target ~= self.cards[i] and self:in_area(self.cards[i]) then self.cards[i]:draw(v) end
                    end
                end
            end
            for i = 1, #self.cards do  
                if self.cards[i] ~= G.CONTROLLER.focused.target then
                    if self.cards[i].highlighted then
                        if G.CONTROLLER.dragging.target ~= self.cards[i] and self:in_area(self.cards[i]) then self.cards[i]:draw(v) end
                    end
                end
            end
        end

        if self.config.type == 'discard' then 
            for i = 1, #self.cards do 
                if self.cards[i] ~= G.CONTROLLER.focused.target then
                    if math.abs(self.cards[i].VT.x - self.T.x) > 1 then 
                        if G.CONTROLLER.dragging.target ~= self.cards[i] and self:in_area(self.cards[i]) then self.cards[i]:draw(v) end
                    end
                end
            end
        end

        if self.config.type == 'hand' or self.config.type == 'play' or self.config.type == 'title' or self.config.type == 'voucher' then 
            for i = 1, #self.cards do 
                if self.cards[i] ~= G.CONTROLLER.focused.target or self == G.hand then
                    if G.CONTROLLER.dragging.target ~= self.cards[i] and self:in_area(self.cards[i]) then self.cards[i]:draw(v) end
                end
            end
        end
    end

    if self == G.deck then
        if G.CONTROLLER.HID.controller and G.STATE == G.STATES.SELECTING_HAND and not self.children.peek_deck then
            self.children.peek_deck = UIBox{
                definition = 
                    {n=G.UIT.ROOT, config = {align = 'cm', padding = 0.1, r =0.1, colour = G.C.CLEAR}, nodes={
                        {n=G.UIT.R, config={align = "cm", r =0.1, colour = adjust_alpha(G.C.L_BLACK, 0.5),func = 'set_button_pip', focus_args = {button = 'triggerleft', orientation = 'bm', scale = 0.6, type = 'none'}}, nodes={
                            {n=G.UIT.R, config={align = "cm"}, nodes={
                                {n=G.UIT.T, config={text = 'PEEK', scale = 0.48, colour = G.C.WHITE, shadow = true}}
                            }},
                            {n=G.UIT.R, config={align = "cm"}, nodes={
                                {n=G.UIT.T, config={text = 'DECK', scale = 0.38, colour = G.C.WHITE, shadow = true}}
                            }},
                        }},
                    }},
                config = { align = 'cl', offset = {x=-0.5,y=0.1}, major = self, parent = self}
            }
            self.children.peek_deck.states.collide.can = false
        elseif (not G.CONTROLLER.HID.controller or G.STATE ~= G.STATES.SELECTING_HAND) and self.children.peek_deck then
            self.children.peek_deck:remove()
            self.children.peek_deck = nil
        end
        if not self.children.view_deck then 
            self.children.view_deck = UIBox{
                definition = 
                    {n=G.UIT.ROOT, config = {align = 'cm', padding = 0.1, r =0.1, colour = G.C.CLEAR}, nodes={
                        {n=G.UIT.R, config={align = "cm", padding = 0.05, r =0.1, colour = adjust_alpha(G.C.BLACK, 0.5),func = 'set_button_pip', focus_args = {button = 'triggerright', orientation = 'bm', scale = 0.6}, button = 'deck_info'}, nodes={
                            {n=G.UIT.R, config={align = "cm", maxw = 2}, nodes={
                                {n=G.UIT.T, config={text = localize('k_view'), scale = 0.48, colour = G.C.WHITE, shadow = true}}
                            }},
                            {n=G.UIT.R, config={align = "cm", maxw = 2}, nodes={
                                {n=G.UIT.T, config={text = localize('k_deck'), scale = 0.38, colour = G.C.WHITE, shadow = true}}
                            }},
                        }},
                    }},
                config = { align = 'cm', offset = {x=0,y=0}, major = self.cards[1] or self, parent = self}
            }
            self.children.view_deck.states.collide.can = false
        end
    if G.deck_preview or self.states.collide.is or (G.buttons and G.buttons.states.collide.is and G.CONTROLLER.HID.controller) then self.children.view_deck:draw() end
    if self.children.peek_deck then self.children.peek_deck:draw() end
    end
	love.graphics.pop()
	love.graphics.setScissor()
end




local fragmentSource = [[
    uniform float TILESCALE;
    uniform float TILESIZE;
    uniform vec2 STARTPOS;
    uniform vec2 SCISSOR_SIZE;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        if (screen_coords.x > (STARTPOS.x + SCISSOR_SIZE.x + 2) * TILESCALE * TILESIZE) 
            discard;
        if (screen_coords.x < STARTPOS.x * TILESCALE * TILESIZE)
            discard;
        return color;
    }
]]
local vertexSource = [[
  vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return transform_projection * vertex_position;
  }
]]

FaeLib.UI.V.BlindChoicesDitherShader = love.graphics.newShader(fragmentSource, vertexSource)
FaeLib.UI.V.BlindChoicesDitherShadersend_info = function()

    FaeLib.UI.V.BlindChoicesDitherShader:send("TILESCALE", G.TILESCALE)
    FaeLib.UI.V.BlindChoicesDitherShader:send("TILESIZE", G.TILESIZE)
    FaeLib.UI.V.BlindChoicesDitherShader:send("STARTPOS", {(G.ROOM.T.x + G.hand.T.x - (6.5/20)), 0})
    FaeLib.UI.V.BlindChoicesDitherShader:send("SCISSOR_SIZE", {(G.hand.T.w), 99999})
end
FaeLib.UI.V.WrapBlindChoicesIml = function(choice_obj)
    local olddraw = choice_obj.draw
    choice_obj.scroll_offset = 0
    choice_obj.draw = function(self)
        local num_blinds = #choice_obj.definition.nodes[1].nodes
        if num_blinds > 3 then
            local sx = FaeLib.Builtin.DeepCopyTable(G.hand.T)
            self.scroll_offset = math.min(1,math.max(0, self.scroll_offset))
            local w_per = self.T.w / num_blinds
            self.alignment.offset.x = (-self.scroll_offset) * (w_per * (num_blinds - 3))
            local ts = G.TILESCALE * G.TILESIZE
            love.graphics.setScissor((G.ROOM.T.x + G.hand.T.x - (6.5/20)) * ts, 0, (G.hand.T.w) * ts, 99999)
            olddraw(self)
            love.graphics.setScissor()
            if G.CONTROLLER.held_buttons["leftshoulder"] then
                self.scroll_offset = self.scroll_offset - 1.5 * (love.timer.getDelta() / (num_blinds - 3))
            end
            if G.CONTROLLER.held_buttons["rightshoulder"] then
                self.scroll_offset = self.scroll_offset + 1.5 * (love.timer.getDelta() / (num_blinds - 3))
            end
        else
            olddraw(self)
        end
    end
    return choice_obj
end



FaeLib.V.CurrentRunBlinds = {}
FaeLib.Builtin.GenBlindChoiceUI = function(p_blind, name, type)
    type = type or "Normal"
    local ret = nil
    local tyCol = type == "Boss" and mix_colours(G.C.BLACK, get_blind_main_colour(name), 0.8) or nil
    return G.GAME.round_resets.blind_states[name] ~= 'Hide' and UIBox{definition = {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={UIBox_dyn_container({create_UIBox_blind_choice(name)},false,get_blind_main_colour(name) or HEX("db7991"), tyCol)}}, config = {align="bmi", offset = {x=0,y=0}}} or nil
    
end
-- function create_UIBox_blind_select()
-- local blind_choices = {
    
--         {n=G.UIT.R, config={align = "cm"}, nodes={
--           {n=G.UIT.O, config={object = DynaText({string = localize('ph_choose_blind_1'), colours = {G.C.WHITE}, shadow = true, bump = true, scale = 0.6, pop_in = 0.5, maxw = 5}), id = 'prompt_dynatext1'}}
--         }},
--         {n=G.UIT.R, config={align = "cm"}, nodes={
--           {n=G.UIT.O, config={object = DynaText({string = localize('ph_choose_blind_2'), colours = {G.C.WHITE}, shadow = true, bump = true, scale = 0.7, pop_in = 0.5, maxw = 5, silent = true}), id = 'prompt_dynatext2'}}
--         }},
--         (G.GAME.used_vouchers["v_retcon"] or G.GAME.used_vouchers["v_directors_cut"]) and
--         UIBox_button({label = {localize('b_reroll_boss'), localize('$')..'10'}, button = "reroll_boss", func = 'reroll_boss_button'}) or nil
-- }
--   G.blind_prompt_box = UIBox{
--     definition =
--       {n=G.UIT.ROOT, config = {align = 'cm', colour = G.C.CLEAR, padding = 0.2}, nodes=blind_choices},
--     config = {align="cm", offset = {x=0,y=-15},major = G.HUD:get_UIE_by_ID('row_blind'), bond = 'Weak'}
--   }
--   G.E_MANAGER:add_event(Event({
--     trigger = 'immediate',
--     func = (function()
--         G.blind_prompt_box.alignment.offset.y = 0
--         return true
--     end)
--   }))
--   local blindResNodes = {
    
--   }
--   local width = G.hand.T.w
--   G.GAME.blind_on_deck = 
--     not (G.GAME.round_resets.blind_states.Small == 'Defeated' or G.GAME.round_resets.blind_states.Small == 'Skipped' or G.GAME.round_resets.blind_states.Small == 'Hide') and 'Small' or
--     not (G.GAME.round_resets.blind_states.Medium == 'Defeated' or G.GAME.round_resets.blind_states.Medium == 'Skipped'or G.GAME.round_resets.blind_states.Medium == 'Hide') and 'Big' or 
--     not (G.GAME.round_resets.blind_states.Big == 'Defeated' or G.GAME.round_resets.blind_states.Big == 'Skipped'or G.GAME.round_resets.blind_states.Big == 'Hide') and 'Big' or 
--     'Boss'
--   G.blind_select_opts = {}
--   G.blind_select_opts.small = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_small, "Small", "Normal")
--   G.blind_select_opts.big = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_big, "Big", "Normal")
--   G.blind_select_opts.boss = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_big, "Boss", "Boss")
--   G.blind_select_opts.medium = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_club, "Medium", "Boss")
--   G.blind_select_opts.medium2 = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_club, "Big", "Boss")
--   G.blind_select_opts.medium3 = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_club, "Big", "Boss")
--   G.blind_select_opts.medium4 = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_club, "Big", "Boss")
--   G.blind_select_opts.medium5 = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_club, "Big", "Boss")
--   G.blind_select_opts.medium6 = FaeLib.Builtin.GenBlindChoiceUI(G.P_BLINDS.bl_club, "Big", "Boss")

--   local blind_nodes = {
--         G.GAME.round_resets.blind_states['Small'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.small}} or nil,
--         G.GAME.round_resets.blind_states['Medium'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.medium}} or nil,
--         G.GAME.round_resets.blind_states['Medium2'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.medium2}} or nil,
--         G.GAME.round_resets.blind_states['Medium3'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.medium3}} or nil,
--         G.GAME.round_resets.blind_states['Medium4'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.medium4}} or nil,
--         G.GAME.round_resets.blind_states['Medium5'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.medium5}} or nil,
--         G.GAME.round_resets.blind_states['Medium6'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.medium6}} or nil,
--         G.GAME.round_resets.blind_states['Big'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.big}} or nil,
--         G.GAME.round_resets.blind_states['Boss'] ~= 'Hide' and {n=G.UIT.O, config={align = "cm", object = G.blind_select_opts.boss}} or nil,
--     }
--   local t = {n=G.UIT.ROOT, config = {align = 'cm',minw = width, maxw=width, colour = G.C.GREEN}, nodes={
--     {n=G.UIT.R, config={align = "cm", padding = 0.25,}, nodes=blind_nodes}
--   }}
--   return t
-- end

-- function create_UIBox_blind_choice(type, run_info)
--   if not G.GAME.blind_on_deck then
--     G.GAME.blind_on_deck = 'Small'
--   end
--   if not run_info then G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = 'Select' end

--   local disabled = false
--   type = type or 'Small'

--   local blind_choice = {
--     config = G.P_BLINDS[G.GAME.round_resets.blind_choices[type]] or {pos = {x=0,y=0}},
--   }

--   blind_choice.animation = AnimatedSprite(0,0, 1.4, 1.4, G.ANIMATION_ATLAS[blind_choice.config.atlas] or G.ANIMATION_ATLAS['blind_chips'],  blind_choice.config.pos)
--   blind_choice.animation:define_draw_steps({
--     {shader = 'dissolve', shadow_height = 0.05},
--     {shader = 'dissolve'}
--   })
--   local extras = nil
--   local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)

--   G.GAME.orbital_choices = G.GAME.orbital_choices or {}
--   G.GAME.orbital_choices[G.GAME.round_resets.ante] = G.GAME.orbital_choices[G.GAME.round_resets.ante] or {}

--   if not G.GAME.orbital_choices[G.GAME.round_resets.ante][type] then 
--     local _poker_hands = {}
--     for k, v in pairs(G.GAME.hands) do
--         if v.visible then _poker_hands[#_poker_hands+1] = k end
--     end

--     G.GAME.orbital_choices[G.GAME.round_resets.ante][type] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
--   end



--   if type ~= 'Boss' then
--     extras = create_UIBox_blind_tag(type, run_info)
--   elseif not run_info then
--     local dt1 = DynaText({string = {{string = localize('ph_up_ante_1'), colour = G.C.FILTER}}, colours = {G.C.BLACK}, scale = 0.55, silent = true, pop_delay = 4.5, shadow = true, bump = true, maxw = 3})
--     local dt2 = DynaText({string = {{string = localize('ph_up_ante_2'), colour = G.C.WHITE}},colours = {G.C.CHANCE}, scale = 0.35, silent = true, pop_delay = 4.5, shadow = true, maxw = 3})
--     local dt3 = DynaText({string = {{string = localize('ph_up_ante_3'), colour = G.C.WHITE}},colours = {G.C.CHANCE}, scale = 0.35, silent = true, pop_delay = 4.5, shadow = true, maxw = 3})
--     extras = 
--     {n=G.UIT.R, config={align = "cm"}, nodes={
--         {n=G.UIT.R, config={align = "cm", padding = 0.07, r = 0.1, colour = {0,0,0,0.12}, minw = 2.9}, nodes={
--           {n=G.UIT.R, config={align = "cm"}, nodes={
--             {n=G.UIT.O, config={object = dt1}},
--           }},
--           {n=G.UIT.R, config={align = "cm"}, nodes={
--             {n=G.UIT.O, config={object = dt2}},
--           }},
--           {n=G.UIT.R, config={align = "cm"}, nodes={
--             {n=G.UIT.O, config={object = dt3}},
--           }},
--         }},
--       }}
--   end
--   G.GAME.round_resets.blind_ante = G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante
--   local target = {type = 'raw_descriptions', key = blind_choice.config.key, set = 'Blind', vars = {}}
--   if blind_choice.config.name == 'The Ox' then
--          target.vars = {localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands')}
--   end
--   local obj = blind_choice.config
--   if obj.loc_vars and _G['type'](obj.loc_vars) == 'function' then
--       local res = obj:loc_vars() or {}
--       target.vars = res.vars or target.vars
--       target.key = res.key or target.key
--   end
--   local loc_target = localize(target)
--   local loc_name = localize{type = 'name_text', key = blind_choice.config.key, set = 'Blind'}
--   local text_table = loc_target
--   local blind_col = get_blind_main_colour(type)
--   local blind_amt = get_blind_amount(G.GAME.round_resets.blind_ante)*blind_choice.config.mult*G.GAME.starting_params.ante_scaling

--   local blind_state = G.GAME.round_resets.blind_states[type]
--   local _reward = true
--   if G.GAME.modifiers.no_blind_reward and G.GAME.modifiers.no_blind_reward[type] then _reward = nil end
--   if blind_state == 'Select' then blind_state = 'Current' end
--   local blind_desc_nodes = {}
--   for k, v in ipairs(text_table) do
--     blind_desc_nodes[#blind_desc_nodes+1] = {n=G.UIT.R, config={align = "cm", maxw = 2.8}, nodes={
--       {n=G.UIT.T, config={text = v or '-', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}}
--     }}
--   end
--   local run_info_colour = run_info and (blind_state == 'Defeated' and G.C.GREY or blind_state == 'Skipped' and G.C.BLUE or blind_state == 'Upcoming' and G.C.ORANGE or blind_state == 'Current' and G.C.RED or G.C.GOLD)
--   local t = 
--   {n=G.UIT.R, config={id = type, align = "tm", func = 'blind_choice_handler', minh = not run_info and 10 or nil, ref_table = {deck = nil, run_info = run_info}, r = 0.1, padding = 0.05}, nodes={

--     {n=G.UIT.R, config={align = "cm", colour = mix_colours(G.C.BLACK, G.C.L_BLACK, 0.5), r = 0.1, outline = 1, outline_colour = G.C.L_BLACK}, nodes={  
--       {n=G.UIT.R, config={align = "cm", padding = 0.2}, nodes={
--           not run_info and {n=G.UIT.R, config={id = 'select_blind_button', align = "cm", ref_table = blind_choice.config, colour = disabled and G.C.UI.BACKGROUND_INACTIVE or G.C.ORANGE, minh = 0.6, minw = 2.7, padding = 0.07, r = 0.1, shadow = true, hover = true, one_press = true, button = 'select_blind'}, nodes={
--             {n=G.UIT.T, config={ref_table = G.GAME.round_resets.loc_blind_states, ref_value = type, scale = 0.45, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT, shadow = not disabled}}
--           }} or 
--           {n=G.UIT.R, config={id = 'select_blind_button', align = "cm", ref_table = blind_choice.config, colour = run_info_colour, minh = 0.6, minw = 2.7, padding = 0.07, r = 0.1, emboss = 0.08}, nodes={
--             {n=G.UIT.T, config={text = localize(blind_state, 'blind_states'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
--           }}
--         }},
--         {n=G.UIT.R, config={id = 'blind_name',align = "cm", padding = 0.07}, nodes={
--           {n=G.UIT.R, config={align = "cm", r = 0.1, outline = 1, outline_colour = blind_col, colour = darken(blind_col, 0.3), minw = 2.9, emboss = 0.1, padding = 0.07, line_emboss = 1}, nodes={
--             {n=G.UIT.O, config={object = DynaText({string = loc_name, colours = {disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE}, shadow = not disabled, float = not disabled, y_offset = -4, scale = 0.45, maxw =2.8})}},
--           }},
--         }},
--         {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
--           {n=G.UIT.R, config={id = 'blind_desc', align = "cm", padding = 0.05}, nodes={
--             {n=G.UIT.R, config={align = "cm"}, nodes={
--               {n=G.UIT.R, config={align = "cm", minh = 1.5}, nodes={
--                 {n=G.UIT.O, config={object = blind_choice.animation}},
--               }},
--               text_table[1] and {n=G.UIT.R, config={align = "cm", minh = 0.7, padding = 0.05, minw = 2.9}, nodes = blind_desc_nodes} or nil,
--             }},
--             {n=G.UIT.R, config={align = "cm",r = 0.1, padding = 0.05, minw = 3.1, colour = G.C.BLACK, emboss = 0.05}, nodes={
--               {n=G.UIT.R, config={align = "cm", maxw = 3}, nodes={
--                 {n=G.UIT.T, config={text = localize('ph_blind_score_at_least'), scale = 0.3, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}}
--               }},
--               {n=G.UIT.R, config={align = "cm", minh = 0.6}, nodes={
--                 {n=G.UIT.O, config={w=0.5,h=0.5, colour = G.C.BLUE, object = stake_sprite, hover = true, can_collide = false}},
--                 {n=G.UIT.B, config={h=0.1,w=0.1}},
--                 {n=G.UIT.T, config={text = number_format(blind_amt), scale = score_number_scale(0.9, blind_amt), colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.RED, shadow =  not disabled}}
--               }},
--               _reward and {n=G.UIT.R, config={align = "cm"}, nodes={
--                 {n=G.UIT.T, config={text = localize('ph_blind_reward'), scale = 0.35, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}},
--                 {n=G.UIT.T, config={text = string.rep(localize("$"), blind_choice.config.dollars or 1)..'+', scale = 0.35, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.MONEY, shadow = not disabled}}
--               }} or nil,
--             }},
--           }},
--         }},
--       }},
--         {n=G.UIT.R, config={id = 'blind_extras', align = "cm"}, nodes={
--           extras,
--         }}
--     }}
--   return t
-- end
  