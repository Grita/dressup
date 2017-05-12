SD_DRESSUP_LOADED = false
SD_DRESSUP_RES_LIMIT = 5;

function SD_DRESSUP_ON_INIT(addon, frame)
  local frame = ui.GetFrame('inventory')
  local equipgroup = GET_CHILD(frame, 'equip', 'ui::CGroupBox')
  local shihouette = GET_CHILD(equipgroup, 'shihouette', "ui::CPicture");

  shihouette:EnableHitTest(1);
  shihouette:EnableChangeMouseCursor(1)
  shihouette:SetTextTooltip('Dressup');
  shihouette:SetEventScript(ui.LBUTTONUP, 'SD_DRESSUP_PROMPT');
  
  if SD_DRESSUP_LOADED then
    return
  end
  
  _G['SD_DRESSUP_SLI_OLD'] = SLI;
  _G['SLI'] = SD_DRESSUP_SLI;
  _G['SD_DRESSUP_ON_CHAT_OLD'] = ui.Chat
  
  ui.Chat = SD_DRESSUP_ON_CHAT
  
  SD_DRESSUP_LOADED = true
  
  ui.SysMsg('-> sd_dressup')
end

function SD_DRESSUP_ON_CHAT(args)
  SD_DRESSUP_ON_CHAT_OLD(args)
  
  args = args:gsub('^/[rwpysg] ', '')
  
  if string.sub(args, 1, 9) == '/dressup ' then
    SD_DRESSUP_APPLY(args:gsub('/dressup ', ''))
  end
  
  local f = GET_CHATFRAME();
  f:GetChild('mainchat'):ShowWindow(0);
  f:ShowWindow(0);
  ui.CloseFrame("chat_emoticon");
end

function SD_DRESSUP_SLI(props, clsid)
  if keyboard.IsPressed(KEY_CTRL) == 1 then
    local obj = GetClassByType('Item', clsid);
    
    if obj ~= nil and obj.ItemType == 'Equip' then
      SD_DRESSUP_APPLY(clsid);
    end
    
    return
  end
  
  _G['SD_DRESSUP_SLI_OLD'](props, clsid);
end

function SD_DRESSUP_LOOKUP(value)
  local clsList, count = GetClassList('Item');
    
  local obj = nil;
  local res = {};
  
  value = string.lower(value);
  
  for i = 0, count - 1 do
    if #res > SD_DRESSUP_RES_LIMIT then
      break
    end
    
    obj = GetClassByIndexFromList(clsList, i);
    
    if obj.ItemType == 'Equip' and string.find(string.lower(dictionary.ReplaceDicIDInCompStr(obj.Name)), value) ~= nil then
      res[#res + 1] = obj;
    end
  end
  
  if #res == 0 then
    return nil
  end
  
  if #res == 1 then
    return res[1];
  end
  
  return res;
end

function SD_DRESSUP_ITEM_LINK(obj)
  local imgtag = string.format("{img %s %d %d}", GET_ITEM_ICON_IMAGE(obj), 32, 32);
  
  return string.format("{a SLI nullval %d}{#0000FF}%s%s{/}{/}{/}", obj.ClassID, imgtag, obj.Name);
end

function SD_DRESSUP_PRINT_RESULTS(res)
  local str = 'Too many results. Showing the first ' .. SD_DRESSUP_RES_LIMIT .. '.';
  
  for i, obj in ipairs(res) do
    str = str .. "{nl}" .. SD_DRESSUP_ITEM_LINK(obj);
  end
  
  CHAT_SYSTEM(str);
end

function SD_DRESSUP_APPLY(value)
  local obj = nil;
  
  if value == '' then
    return
  end
  
  if string.match(value, '^[0-9]+$') then
    obj = GetClassByType('Item', tonumber(value));
  else
    obj = GetClass('Item', value);
    
    if obj == nil or obj.ItemType ~= 'Equip' then
      obj = SD_DRESSUP_LOOKUP(value);
    end
  end
  
  if obj == nil then
    ui.SysMsg('Nothing found.');
    return;
  elseif type(obj) == 'table' then
    SD_DRESSUP_PRINT_RESULTS(obj);
    return;
  elseif obj.ItemType ~= 'Equip' then
    ui.SysMsg('Invalid item.');
    return;
  end
  
  local slot = 'ES_' .. obj.DefaultEqpSlot;
  
  if slot == 'ES_LENS' then
    slot = 'ES_LAST'
  end
  
  GetMyActor():GetSystem():ChangeEquipApperance(_G[slot], obj.ClassID);
end

function SD_DRESSUP_PROMPT()
  INPUT_STRING_BOX_CB(nil, 'Item name, ClassName or ClassID', 'SD_DRESSUP_APPLY', '', nil, 0, 512);
end
