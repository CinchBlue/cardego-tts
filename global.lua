--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

--[[
GLOBAL CONSTANTS

NOTE: GUIDs need to be adjusted to match "template objects" or "primary"
objects since the code refers to singleton objects by GUID.
--]]
DM_ZONE_GUID = "a35d72"
CARD_TEMPLATE_GUID = "9c78cc"


function onObjectEnterScriptingZone(zone_guid, obj)

    -- Handle turning objects invisible/uninteractable
    -- if they enter/exit the DM zone
    if (DM_ZONE_GUID == zone_guid.getGUID()) then
        obj.setInvisibleTo({
            "Blue", "Pink", "Green", "Yellow",
            "Orange", "White", "Teal", "Purple", "Red"
        })
    end
end


function onObjectLeaveScriptingZone(zone_guid, obj)
    -- Handle turning objects invisible/uninteractable
    -- if they enter/exit the DM zone
    if (DM_ZONE_GUID == zone_guid.getGUID()) then
        -- This overwrites the "hide-set", so this makes it hidden
        -- to no one.
        obj.setInvisibleTo({})
    end
end


--[[
Utility function to split a string on a sequence of characters.

Params:
- inputstr - The string to split.
- sep - The separation string to split on.

Returns:
A table of strings with the separators removed.
--]]
function splitstr (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end


--[[
Returns the JSON of the card template object.
--]]
function getCardTemplateJSON()
  return getObjectFromGUID(CARD_TEMPLATE_GUID).getJSON()
end


--[[
Handles the processing of admin commands.

NOTE: you must be player "Black" to trigger admin commands currently.
This is so that trolls and other disruptive users cannot just maliciously
run commands and possibly cause TTS to crash.

NOTE: Be careful with running commands that spawn too many cards. TTS
can perform web queries fairly cheaply, but spawning objects is a relatively
expensive operation once you start spawning more than 5 objects per second,
especially if they have scripts attached to them.
--]]
function onChat(message, player)
  -- Make sure that the chat commands only work with the GM/host.
  if player.color == 'Black' then
    -- Split the single line of chat by space by default.
    local args = splitstr(message)

    -- Treat the first space-delimited string as special, and assume it holds
    -- the command name.
    local command_name = args[1]
    table.remove(args, 1)

    --
    if string.find(command_name, '#get_card') or string.find(command_name, '#gc') == 1 then
      log("#get_card command triggered", 'DEBUG')
      command_card_id(args)
    elseif string.find(command_name, '#get_deck') or string.find(command_name, '#gd') == 1 then
      log("#get_deck command triggered", 'DEBUG')
      command_deck(args)
    elseif string.find(command_name, '#query_deck') or string.find(command_name, '#qd') == 1 then
      log("#query_deck command triggered", 'DEBUG')
      command_query_deck(args)
    end
  end
end


function command_card_id(args)
  for i, arg in ipairs(args) do
    local spawnParams = {
      json = getCardTemplateJSON(),
      position = {x=52, y=2, z=8-i},
      sound = true,
      snap_to_grid = true,
      callback_function = |obj| spawn_callback(obj, arg)
    }
    spawnObjectJSON(spawnParams)
  end
end

function command_deck(args)
  WebRequest.get("localhost:8000/decks/" .. args[1], function (payload)
    if payload.is_error then
      print('Error loading deck ' .. self.getVar('card_id'))
      return
    end
    decodedTable = JSON.decode(payload.text)

    for i, v in ipairs(decodedTable) do
      Wait.time(function()
        local cardData = v
        local spawnParams = {
          json = getCardTemplateJSON(),
          position = {x=52-(math.floor(i/20)), y=3, z=8-(i%20)},
          sound = true,
          snap_to_grid = true,
          callback_function = |obj| spawn_with_data_ready_callback(obj, cardData)
        }
        spawnObjectJSON(spawnParams)
      end, i/10)
    end
  end)
end


function command_query_deck(args)
  WebRequest.get("localhost:8000/search/decks/" .. args[1], function (payload)
    if payload.is_error then
      print('Error querying deck ' .. self.getVar('card_id'))
      return
    end
    decodedTable = JSON.decode(payload.text)

    local s = ''
    for i, v in ipairs(decodedTable) do
      s = s .. ' ' .. v['name']
    end
    printToColor(s, 'Black')
  end)
end


function spawn_with_data_ready_callback(object_spawned, cardData)
  object_spawned.setVar('card_id', cardData['id'])
  object_spawned.call('syncDataFromTable', cardData)
end


function spawn_callback(object_spawned, arg)
  object_spawned.setVar('card_id', arg)
  object_spawned.call('handleCardSync', {})
end


--[[
Utility fucntion to print a table with identation pretty-printing.
--]]
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end