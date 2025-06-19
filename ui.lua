assert(SMODS.load_file("init.lua", "faelib"))()
FaeLib.UI = FaeLib.UI or {}

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