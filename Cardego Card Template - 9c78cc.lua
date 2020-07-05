card_attributes = {'card_name', 'card_type', 'card_desc', 'card_combat', 'card_id'}


function onSave()
  return prepareSaveState()
end


function syncDataFromExternalTable(t)
  syncDataFromTable(t['t'])
end

function syncDataFromTable(t)
  storeAttrForThisObject('card_id', t['id'])
  storeAttrForThisObject('card_name', t['name'])
  storeAttrForThisObject('card_type', t['cardtype'])
  storeAttrForThisObject('card_desc', t['desc'])
  storeAttrForThisObject('card_combat', t['cost'])
  syncAllAttrToUI()
  log('Success syncing id ' .. t['id'], 'DEBUG')
end

function prepareSaveState()
  local data_table = {}
  for _, attr in ipairs(card_attributes) do
    data_table[attr] = self.getVar(attr)
  end
  save_state = JSON.encode(data_table)
  --print('save_state: ' .. save_state)
  return save_state
end


function onDrop(player_color)
    syncAllAttrToUI()
end


function onPickUp(player_color)
    syncAllAttrToUI()
end


function updateSave()
  self.script_save = prepareSaveState()
end


function onLoad(save_state)
  local data_table = (JSON.decode(save_state) or {})
  if type(data_table) == 'table' then
    for k, v in pairs(data_table) do
      storeAttrForThisObject(k, v)
    end
    log(data_table, self.getGUID(), 'DEBUG')
  else
    log(string.format('Save data for %s not found', self.getGUID()), self.getGUID(), 'DEBUG')
  end
  syncAllAttrToUI()
  self.setVar('isReadOnly', true)
end


function handleCardReadAloud(player, value, id)
  printToAll(string.format('%s reads card #%s "%s" (%s):\n"%s"\nCost: %s',
  tostring(player.color),
  tostring(self.getVar('card_id')),
  tostring(self.getVar('card_name')),
  tostring(self.getVar('card_type')),
  tostring(self.getVar('card_desc')),
  tostring(self.getVar('card_combat'))),
  lightenColor(stringColorToRGB(player.color), 0.65))
end


function handleCardAttributeUpdate(player, value, id)
  storeAttrForThisObject(id, value)
  syncAllAttrToObjectMenu()
end


function storeAttrForThisObject(id, value)
  self.setVar(id, value)
end


function syncAllAttrToObjectMenu()
  self.setDescription(self.getVar('card_combat') or '')
  self.setName(self.getVar('card_name') or '')
end


function syncAllAttrToUI()
    for _, attr in ipairs(card_attributes) do
      self.UI.setAttribute(attr .. '_text', 'text', self.getVar(attr))
      self.UI.setAttribute(attr, 'text', self.getVar(attr))
    end
    syncAllAttrToObjectMenu()
end


function handleCardLock()
  isReadOnly = self.getVar('isReadOnly')
  if isReadOnly then
    -- Turn card editable
    for _, attr in ipairs(card_attributes) do
      --print(attr .. ' ' .. self.getVar(attr))
      self.UI.setAttribute(attr, 'active', "True")
      self.UI.setAttribute(attr, 'text', self.getVar(attr))
      self.UI.setAttribute(attr .. '_text', 'active', "False")
    end
    self.UI.setAttribute('button_sync', 'active', 'True')
    self.UI.setAttribute('card_id', 'active', 'True')
    self.UI.setAttribute('card_id', 'text', self.getVar(attr))
  else
    -- Sync edits
    for _, attr in ipairs(card_attributes) do
      --print(attr .. ' ' .. self.getVar(attr))
      self.UI.setAttribute(attr, 'text', self.getVar(attr))
      self.UI.setAttribute(attr, 'active', "False")
      self.UI.setAttribute(attr .. '_text', 'active', "True")
    end
    self.UI.setAttribute('button_sync', 'active', 'False')
    self.UI.setAttribute('card_id', 'active', 'False')
    self.UI.setAttribute('card_id', 'text', self.getVar(attr))
  end
  self.setVar('isReadOnly', not isReadOnly)
  syncAllAttrToUI()
end


function lightenColor(given_color, factor)
  local r, g, b = given_color.r, given_color.g, given_color.b
  local compl_r, compl_g, compl_b = 1-r, 1-g, 1-b
  compl_r, compl_g, compl_b = compl_r*factor, compl_g*factor, compl_b*factor
  return color(r+compl_r, g+compl_g, b+compl_g)
end


function requestCardDataSync(id)
  WebRequest.get('localhost:8000/cards/' .. id, function(a) handleCardData(a) end)
end


function handleCardSync()
  requestedId = self.getVar('card_id')
  requestCardDataSync(requestedId)
end

function handleCardData(payload)
  if payload.is_error then
    print('Error loading id ' .. self.getVar('card_id'))
    return
  end
  decodedTable = JSON.decode(payload.text)
  storeAttrForThisObject('card_id', decodedTable['id'])
  storeAttrForThisObject('card_name', decodedTable['name'])
  storeAttrForThisObject('card_type', decodedTable['cardtype'])
  storeAttrForThisObject('card_desc', decodedTable['desc'])
  storeAttrForThisObject('card_combat', decodedTable['cost'])
  log('Success syncing id ' .. decodedTable['id'], 'DEBUG')
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