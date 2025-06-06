# FaeLib - Balatro Modding Utility

### Requires Steamodded

General Utilities:
- Minecraft-Style Tags
- Colour Management
- Hover-Tooltip Management
- InfoQueue Tooltip Management
- Events
- Card Buttons (buy, sell)
- Godot-Style Tweening
- Card Movement


# Colour Management
Allows definitions of translation colours through a similar API as the language files.
Example:
```lua
-- MyMod/faelib/colours.lua
return {
    some_colour = "db7991",
    some_other_colour = {
        1,0,1,1
    }
}
```
Colours can be defined either through HEX(...), a list, or a string (implicit HEX(...) call)

# Tag Management
Provides a Minecraft-like Tag implementation.

Example:
```lua
MyTag = FaeLib.CreateOrGetTag("mo_mod:my_tag_key") -- also can use [new 'FaeLib.Tag<ObjectType>'("my_mod:my_tag_key")], but this will warn you for it!
-- FaeLib.CreateOrGetTag can also take a 2nd optional parameter for the Template type. 
MyTag:add("some_id")
local something_returned_from_smods = {
    key = "some_other_id",
    ...
}
MyTag:add(something_returned_from_smods) -- SMODS compatible. The ID can either be "key" or "id"
MyTag:add("#namespace:tag_key") -- Nested tag keys (see: [Minecraft Wiki's Tag Json Format](https://minecraft.wiki/w/Tag))
...

MyTag:contains("some_other_id") -- -> true
MyTag:contains(something_returned_from_smods) -- -> true
MyTag:contains(something_else_returned_from_smods) -- -> false
MyTag:contains("some_id_that_doesnt_exist") -- -> false
MyTag:contains("#namespace:some_tag_key") -- -> Only true if the tag key is present.

```
Alternatively, you can define tags either in Lua or JSON with files placed in `faelib/tags/my_tag_name` 

Note: Tags without a "namespace" key in their data will default to `balatro` as the namespace!
```json
// JSON:
[
    "namespace:some_key"
]
// Or, if you want a different namespace than "balatro" (default)
{
    "values" :[
        "namespace:some_key"
    ],
    "namespace":"some_namespace"
}
```
```lua
-- Lua
return {
    "namespace:some_key"
}

-- Or, if you want a different namespace than "balatro" (default)

return {
    namespace = "some_namespace"
    values = {
        "namespace:some_key"
    }
}
```


### Builtin Tags
```lua
FaeLib.Tags.Blinds -- When using SMODS to create a new Blind, it will automatically be put in this tag.
FaeLib.Tags.BossBlinds
FaeLib.Tags.FinalBlinds
FaeLib.Tags.ForagerCards -- Card-Subtype that generates cards at end of blind
FaeLib.Tags.FoodCards
```


### Hover-Tooltips and InfoQueue Tooltips
The Hover-Tooltip and InfoQueue tooltips use the same registration function.
For hovering, see the [SMODS Text Styling Wiki page](https://github.com/Steamodded/smods/wiki/Text-Styling#text-hover-tooltip-modifier-t)
For the InfoQueue tooltip, use the following:
```lua
MyTooltip =  new 'FaeLib.Tooltip' (
    "my_translation_id",
    "Title",
    {"Text1", "Text2"}
)

...
info_queue[#info_queue+1] = MyTooltip
...


-- translation file
{ some_key = "Hover Tooltip {T:my_translation_id}" }
```

### Events
I'm not sure how to explain this, it's similar to how FabricMC does its' event handling.

Events can be given a function to invoke using `:register(func, order)`

The lower the order of the callback is, the sooner it'll run.

The order of the callbacks only update when using `:register(...)`

A custom event can be defined as follows:
```lua
newEventHandler = new 'FaeLib.AbstractEventHandler' ()

-- Adding an event processor
newEventHandler:register(function ()
    ...
end, 0)
...
-- somewhere, where you want all event processors to be invoked from:
newEventHandler:invoke(...) -- This will invoke all registered event processors in the event handler
...
```

Builtin Events: (working list)
```lua
FaeLib.Builtin.Events.ConsumableUsed -> (card)
FaeLib.Builtin.Events.BlindStarted -> (blind)
FaeLib.Builtin.Events.BlindCompleted -> (blind)

FaeLib.Builtin.Events.RenderPre -> ()
FaeLib.Builtin.Events.RenderPost -> ()

FaeLib.Builtin.Events.MousePressed -> (x, y, is_touch)
FaeLib.Builtin.Events.MouseReleased -> (x, y, is_touch)
FaeLib.Builtin.Events.MouseMoved -> (x, y, dx, dy, is_touch)
```

### Card Buttons
Description TBC
Adds a button above the card
```lua
new 'FaeLib.CardButton'("my_button_key", "button_alignment_butitsbrokenandidkhowtofixit", function (self, card)
    -- Button Pressed
	new 'FaeLib.FrameTask'(function ()
        -- Some processing. This is run the next frame, and it helps with varios effects not working when a button is pressed.
        -- I'm not sure why, but juice_up never works from this? Ah well
	end)
end, G.C.GOLD, -- Button Colour
function (self, card)
    -- Button Visible
	return some_visibility_check
end)
```

### Tweening
Tweens a variable through time automatically
```lua
local table = {
    var1 = 0
    var2 = 0
}
local tweener = new 'FaeLib.Tweener' (
    {"var1", "var2"}, -- Variable names to process. Can either be an array of names, or a single name.
    table,
    2, -- Duration
    smoothstep, -- Easing function
    {var1 = 0, var2 = 0}, -- Start values
    {var1 = 1, var2 = 1}, -- End value

    -- Optional Paramaters

    true, -- Run automatically (True by default)
    function (completion_state) -- Completion states
        if completion_state == "DELAY_STARTED" then
            ... -- delaying from then_wait
        end
        if completion_state == "DELAY_COMPLETE" and delay_ended and not self.completed_once then
            ... -- delay finished
        end
    end,
    function (table, name, value) -- Post-Set function
    end,
    true -- Upon completion, remove this tweener. Will be ignored if there's another tweener after this!
)
```
Constructor:
`new "FaeLib.Tweener"(name, table, duration, easing, from, to, autorun, on_complete, on_set, destroy_when_complete)`

Member Functions:

`FaeLib.Tweener:set(name, value)` Function used to set the property to the table

`FaeLib.Tweener:and_reverse()` Appends a new reversed tweener from the current one. (ie, reversed.start = current.end, reversed.end = current.start)

`FaeLib.Tweener:then_wait(duration, waiting_function)` After this tweener is completed, wait a specified duration before proceeding to the next tweener

`FaeLib.Tweener:and_then(tweener: FaeLib.Tweener)` Appends a new tweener to run after this tweener is complete



### Tasks and Task Chains
A Task is used to run a function the next frame, or run a function every frame. These can be chained together similarly to Tweeners, and how Balatro's G_EVENT manager works.

Example:
```lua
new 'FaeLib.Task'(
    function (self, frame_delta) -- Processing function
    ...
    end, 
    true, -- Repeat forever
    1, -- Duration (Will repeat as long as this is not zero)
    function() -- Stop repeating and destroy if true
        return should_stop_repeating
    end,
    true, -- auto-start the chain
)
```

Task Chains can be created using FaeLib.Task:and_then(...), and will append to the end of the "chain"
A "chain" is ran in the order it's added, and will wait some duration before going to the next chain, if specified.

- Unlike Tweeners, the current link while "delaying" will execute its' main task function.

*Internally, these work like Linked Lists.*

`FaeLib.Task:with_data(data) -> FaeLib.Task (head)` Assigns data to this task, and all tasks in the chain.

`FaeLib.Task:with_delay(delay) -> FaeLib.Task (head)` Assigns the delay before the next chain will be executed

`FaeLib.Task:and_then(func, repeating, duration, [should_stop_repeating], [delay_before_starting]) -> FaeLib.Task (head)` Appends a new task "link" to the end of the task chain
- If a task "link" is repeating, it will wait until should_stop_repeating returns true to execute the next link in the chain.



`FaeLib.Task:with_duration(duration) -> FaeLib.Task (head)` Changes the duration this chain will be running for.
- You can bypass the error for repeating using this. Though, the duration will still go down while it's running.

### Card Movement
Allows moving a card to an arbitrary point on the screen over time
```lua

new 'FaeLib.CardMovement'(
    card_to_move,
    target_x,
    target_y,
    0.25, -- Duration
    1, -- Delay before returning to original position
    function(moving_card) -- Started
    end,
    function (moving_card) -- Completed
    end,
    function (moving_card) -- While Moving
    end,
)
```





## Additional Utilities

### Versioning
Versions can either be defined using a Class or a Table.
```lua
version = new "VersionDef"("0.0.0")
version = VersionDef("0.0.0")
version = {major = 0, minor = 0, patch = 0}
version = VersionDef({0, 0, 0})
```

For Version comparison, it must either be created using VersionDef or a class instance. 
`version_1_0_0 > version_1_1_0`

### Classes
Classes are a simplified version of SMODS' GameObject, using [Lua-Class](https://github.com/lodsdev/lua-class/tree/main)

While the main library is still the same, some additions have been made:

#### Metatable Methods
Metatable methods can be defined for classes with the following:

`tostring(self)`

`lt(self, other)` | `less(self,other)`

`le(self, other)` | `lessequals(self,other)`

`gt(self, other)` | `greater(self,other)`

`ge(self, other)` | `greaterequals(self,other)`

`equals(self, other)`


### Rendering Utilities


`FaeLib.APIs.Drawing.text_centered(text, x, y, rads, scx, scy, kx, ky, y_align)` 
- Modification of love.graphics.print to print text centered upon (x, y). Optionally align the height as well.

`FaeLib.APIs.Drawing.text_ease_alpha(text, x, y, rgb_colour, fade_in_time, hold_time, fade_out_time, easing)`
- Uses love.graphics.print to draw text that fades in, holds, and fades out over time. Optionally, change easing function (x,y,time)

`FaeLib.APIs.Drawing.text_ease_alpha_centered(text, x, y, rgb_colour, fade_in_time, hold_time, fade_out_time, easing, center_y)`
- Variant of `text_ease_alpha` that draws centered. See FaeLib.APIs.Drawing.text_centered


Currently, text_ease_alpha, text_ease_alpha_centered do not respect rotation, scale, or shearing. You'll need to use LOVE's matrix transforms for this.
\* will be changed in the future


### Templates
Template arguments can be supplied when creating and defining classes.
Note: they're just syntax sugar used to differentiate classes further.

`class "class_name" : template "t1, t2"`

`new class_name() -> errors: no templates provided`

`new class_name<something>() -> errors, template count mismatch`

`new class_name<something, something_else>() -> succeeds`

`new class_name<something, something_else, something_more>() -> errors, template count mismatch`

### Final Classes
Classes can be defined as `final()` to block the `extends` operation. Can't be applied to interfaces

### Extended Tooltips
Extended tooltips can be toggled with F3, which shows various info about modded assets


### Added LOVE API functions
Mouse Button pressed

Returns whether the mouse was pressed this frame
- `love.mouse.was_pressed(button) -> bool`
- `FaeLib.Mouse.was_pressed(button) -> bool`

Mouse Button released

Returns whether the mouse was released this frame
- `love.mouse.was_released(button) -> bool`
- `FaeLib.Mouse.was_released(button) -> bool`