
--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    --[[ print('onLoad!') --]]
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
    --[[ print('onUpdate loop!') --]]
end

function onObjectEnterScriptingZone(zone_guid, obj)
    if (zone_guid.getGUID() == "a35d72") then

        obj.setInvisibleTo({
            "Blue", "Pink", "Green", "Yellow",
            "Orange", "White", "Teal", "Purple", "Red"
        })
    end

end


function onObjectLeaveScriptingZone(zone_guid, obj)
    if (zone_guid.getGUID() == "a35d72") then

        obj.setInvisibleTo({})
    end

end


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


function getCardTemplateJSON()
  return getObjectFromGUID('9c78cc').getJSON()
end

function onChat(message, player)
  if player.color == 'Black' then
    local args = splitstr(message)
    local command_name = args[1]
    table.remove(args, 1)
    if string.find(command_name, '#cards_id') or string.find(command_name, '#ci') == 1 then
      log("#cards_id command triggered", 'DEBUG')
      command_card_id(args)
    elseif string.find(command_name, '#cs') or string.find(command_name, '#cs') == 1 then
      log("#card_set command triggered", 'DEBUG')
      command_card_set(args)
    elseif string.find(command_name, '#qcs') or string.find(command_name, '#query_card_set') == 1 then
      log("#query_card_set command triggered", 'DEBUG')
      command_query_card_set(args)
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

function command_card_set(args)
  WebRequest.get("localhost:8000/user_set/" .. args[1], function (payload)
    if payload.is_error then
      print('Error loading user set ' .. self.getVar('card_id'))
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


function command_query_card_set(args)
  WebRequest.get("localhost:8000/search/user_set/" .. args[1], function (payload)
    if payload.is_error then
      print('Error querying user set ' .. self.getVar('card_id'))
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