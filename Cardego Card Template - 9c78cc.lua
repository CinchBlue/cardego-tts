CARD_ATTRIBUTES_ALPHA1 = {
  --'card_save_version',
  'card_name',
  'card_type',
  'card_desc',
  'card_combat',
  'card_id'
}

CARD_ATTRIBUTES_ALPHA2 = {
  'card_save_version',
  'card_id',
  'card_action',
  'card_speed',
  'card_name',
  'card_desc'
}

CARD_ATTRIBUTES = CARD_ATTRIBUTES_ALPHA1

SAVE_VERSIONS = {
  "ALPHA1",
  "ALPHA2",
  "ALPHA3"
}

CURRENT_SAVE_VERSION = "ALPHA3"


function onSave()
  return prepareSaveState()
end


function syncDataFromExternalTable(t)
  syncDataFromTable(t['t'])
end


function syncDataFromTable(t)
  storeAttrForThisObject('card_id', t['id'])
  storeAttrForThisObject('card_name', t['name'])
  storeAttrForThisObject('card_type', t['cardclass'])
  storeAttrForThisObject('card_cardclass', t['cardclass'])
  storeAttrForThisObject('card_desc', t['desc'])
  storeAttrForThisObject('card_combat', t['speed'] .. ' / ' .. t['action'])
  storeAttrForThisObject('card_speed', t['speed'])
  storeAttrForThisObject('card_action', t['action'])
  storeAttrForThisObject('card_image_url', t['image_url'])
  storeAttrForThisObject('card_save_version', CURRENT_SAVE_VERSION)
  syncAllAttrToUI()
  log('Success syncing id ' .. t['id'], 'DEBUG')
end


function prepareSaveState()
  local data_table = {}
  for _, attr in ipairs(CARD_ATTRIBUTES) do
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
  prepareSaveState()
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
  printToAll(string.format('%s reads card #%s "%s" (%s):\n"%s"\nSpeed/Action: %s',
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
    for _, attr in ipairs(CARD_ATTRIBUTES) do
      self.UI.setAttribute(attr .. '_text', 'text', self.getVar(attr))
      self.UI.setAttribute(attr, 'text', self.getVar(attr))
    end
    syncAllAttrToObjectMenu()
end


function handleCardLock()
  isReadOnly = self.getVar('isReadOnly')
  if isReadOnly then
    -- Turn card editable
    for _, attr in ipairs(CARD_ATTRIBUTES) do
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
    for _, attr in ipairs(CARD_ATTRIBUTES) do
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
  t = JSON.decode(payload.text)
  storeAttrForThisObject('card_id', t['id'])
  storeAttrForThisObject('card_name', t['name'])
  storeAttrForThisObject('card_type', t['cardclass'])
  storeAttrForThisObject('card_cardclass', t['cardclass'])
  storeAttrForThisObject('card_desc', t['desc'])
  storeAttrForThisObject('card_combat', t['speed'] .. ' / ' .. t['action'])
  storeAttrForThisObject('card_speed', t['speed'])
  storeAttrForThisObject('card_action', t['action'])
  storeAttrForThisObject('card_image_url', t['image_url'])
  storeAttrForThisObject('card_save_version', CURRENT_SAVE_VERSION)

  self.setCustomObject({
    face = 'localhost:8000/cards/' .. t['id'] .. '/image.png',
    back = "http://cloud-3.steamusercontent.com/ugc/1017193127284955248/A6F93DB541612951E19709C01B863B94BA79FC04/",
    width = 1,
    height = 1,
    number = 1
  })

  log('Success syncing id ' .. t['id'], 'DEBUG')
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