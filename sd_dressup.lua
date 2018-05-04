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
    args = args:gsub('/dressup ', '');
    SD_DRESSUP_APPLY(args)
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
      SD_DRESSUP_APPLY(clsid, props);
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

function SD_DRESSUP_PRINT_COLORS(clsid, res)
  local tbl = {};
  
  for k, v in pairs(res) do
    k = string.format("{a SD_DRESSUP_APPLY %d:%s}{#0000FF}%s{/}{/}", clsid, k, k);
    table.insert(tbl, k);
  end
  
  CHAT_SYSTEM('Available colors are:{nl}' .. table.concat(tbl, ', '));
end

function SD_DRESSUP_APPLY(value, args)
  local obj = nil;
  
  if value == '' then
    return
  end
  
  if type(args) ~= 'string' then
    local argIdx = string.find(value, '#');
    
    if argIdx then
      args = string.sub(value, argIdx + 1);
      value = string.sub(value, 0, argIdx - 1);
    end
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
  
  if obj.ClassType == 'Hair' then
    SD_DRESSUP_APPLY_HAIR(obj, args);
  else
    local slot = obj.DefaultEqpSlot;
    
    if obj.DefaultEqpSlot == 'RH LH' then
      slot = 'RH';
    end
    
    slot = item.GetEquipSpotNum(slot);
    
    GetMyActor():GetSystem():ChangeEquipApperance(slot, obj.ClassID);
  end
end

function SD_DRESSUP_PRINT_COLORS(clsid, res)
  local str = '';
  local tlen, wlen = 0, 0;
  
  for k, v in pairs(res) do
    wlen = string.len(k);
    tlen = tlen + wlen;
    
    k = string.format("{a SLI %s %d}{#FFFFFF}%s{/}{/}", k, clsid, k);
    
    str = str .. ', ';
    
    if tlen > 25 then
      str = str .. '{nl}';
      tlen = wlen;
    end
    
    str = str .. k;
  end
  
  str = string.sub(str, 3);
  
  CHAT_SYSTEM('Available colors are:{nl}' .. str);
end

function SD_DRESSUP_APPLY_HAIR(obj, arg)
  local name = obj.StringArg;
  
  local curIdx = item.GetHeadIndex();
  local curColor;
  
  local clsList = imcIES.GetClassList('HairType');
  local genderNode = clsList:GetClass(GetMyPCObject().Gender);
  local typeNodes = genderNode:GetSubClassList();
  local count = typeNodes:Count();
  
  local itemList = {};
  
  local defaultIdx;
  
  for i = 0, count - 1 do
    local node = typeNodes:GetByIndex(i);
    
    local nodeIdx = imcIES.GetINT(node, 'Index');
    local nodeName = imcIES.GetString(node, 'EngName');
    local nodeColor = string.lower(imcIES.GetString(node, 'ColorE'));
    
    if nodeName == name then
      itemList[nodeColor] = nodeIdx;
      
      if defaultIdx == nil then
        defaultIdx = nodeIdx;
      end
    end
    
    if nodeIdx == curIdx then
      curColor = imcIES.GetString(node, 'ColorE');
    end
  end
  
  if defaultIdx == nil then
    ui.SysMsg('Nothing found.');
    return;
  end
  
  local color;
  
  if type(arg) == 'string' and arg ~= '' then
    color = string.lower(arg);
  else
    color = curColor;
    SD_DRESSUP_PRINT_COLORS(obj.ClassID, itemList);
  end
  
  local idx = itemList[color];
  
  if idx == nil then
    idx = defaultIdx;
  end
  
  item.ChangeHeadAppearance(idx);
end

function SD_DRESSUP_PROMPT()
  INPUT_STRING_BOX_CB(nil, 'Item name, ClassName or ClassID', 'SD_DRESSUP_APPLY', '', nil, nil, 512);
end
