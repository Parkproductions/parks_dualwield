local function getGuidFromItemId(inventoryId, itemData, category, slotId)
    if not itemData then
        itemData = 0 -- Assign a default value or handle the case appropriately
    end
    local outItem = DataView.ArrayBuffer(8 * 13)
    local success = Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemData and itemData or 0, category, slotId, outItem:Buffer())
    return success and outItem or nil
end

local function getGuidFromSlot(inventoryId, itemData, slot)
    local outItem = DataView.ArrayBuffer(8 * 13)
    local success = Citizen.InvokeNative(0xBE012571B25F5ACA, inventoryId, itemData, slot, 1, outItem:Buffer())
    return success and outItem or nil
end

local function moveInventoryItem(inventoryId, old, new, slot)
    local outGUID = DataView.ArrayBuffer(8 * 13)
    if not slot then slot = 1 end
    local sHash = "SLOTID_WEAPON_"..tostring(slot)
    local success = Citizen.InvokeNative(0xDCCAA7C3BFD88862, inventoryId, old, new, GetHashKey(sHash), 1, outGUID:Buffer())
    return success and outGUID or nil
end

local equippedWeapons = {}
 
local function addWeapon(weapon, slot, id)
    if slot == 0 and id then
        if #equippedWeapons > 0 then
            slot = 1
        end
    end
    local weaponHash = GetHashKey(weapon)
    local sHash = "SLOTID_WEAPON_"..tostring(slot)
    local reason = GetHashKey("ADD_REASON_DEFAULT")
    local inventoryId = 1
    local slotHash = GetHashKey(sHash)
    local move = false
    
    --Now add it to the characters inventory
    local isValid = Citizen.InvokeNative(0x6D5D51B188333FD1, weaponHash, 0) --ItemdatabaseIsKeyValid
    if not isValid then
        print("Non valid weapon")
        return false
    end
    
    local characterItem = getGuidFromItemId(inventoryId, nil, GetHashKey("CHARACTER"), 0xA1212100) --return func_1367(joaat("CHARACTER"), func_2485(), -1591664384, bParam0);
    if not characterItem then
        print("no characterItem")
        return false
    end
    
    local weaponItem = getGuidFromItemId(inventoryId, characterItem:Buffer(), 923904168, -740156546) --return func_1367(923904168, func_1889(1), -740156546, 0);
    if not weaponItem then
        print("no weaponItem")
        return false
    end
    
    if slot == 1 and id then
        if #equippedWeapons > 0 then
            local newItemData = DataView.ArrayBuffer(8 * 13)
            local newGUID = moveInventoryItem(inventoryId, equippedWeapons[1].guid, weaponItem:Buffer())
            if not newGUID then
                print("can't move item")
                return false
            end
            slotHash = GetHashKey('SLOTID_WEAPON_0')
            slot = 0
            move = true
        else
            slotHash = GetHashKey('SLOTID_WEAPON_0')
            slot = 0
        end
    end
    
    local itemData = DataView.ArrayBuffer(8 * 13)
    print(inventoryId, json.encode(itemData), json.encode(weaponItem), weaponHash, slotHash, 1, reason)
    local isAdded = Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemData:Buffer(), weaponItem:Buffer(), weaponHash, slotHash, 1, reason) --Actually add the item now
    
    if not isAdded then 
        print("Not added")
        return false
    end
    
    local equipped = Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemData:Buffer(), true)
    if not equipped then
        print("no equip")
        return false
    end
    
    Citizen.InvokeNative(0x12FB95FE3D579238, PlayerPedId(), itemData:Buffer(), true, slot, false, false)
    if move then
        Citizen.InvokeNative(0x12FB95FE3D579238, PlayerPedId(), equippedWeapons[1].guid, true, 1, false, false)
    end
    if id then
        local nWeapon = {
            id = id,
            guid = itemData:Buffer(),
        }
        table.insert(equippedWeapons, nWeapon)
    end
    
    return true
end

local function DISQgetGuidFromItemId(inventoryId, itemData, category, slotId) 
    local outItem = DataView.ArrayBuffer(8 * 13)
 
    if not itemData then
        itemData = 0
    end
 
    local success = Citizen.InvokeNative("0x886DFD3E185C8A89", inventoryId, itemData, category, slotId, outItem:Buffer()) --InventoryGetGuidFromItemid
    if success then
        return outItem:Buffer() --Seems to not return anythign diff. May need to pull from native above
    else
        return nil
    end
end
 
local function addWardrobeInventoryItem(itemName, slotHash)
    local itemHash = GetHashKey(itemName)
    local addReason = GetHashKey("ADD_REASON_DEFAULT")
    local inventoryId = 1
 
    -- _ITEMDATABASE_IS_KEY_VALID
    local isValid = Citizen.InvokeNative("0x6D5D51B188333FD1", itemHash, 0) --ItemdatabaseIsKeyValid
    if not isValid then
        return false
    end
 
    local characterItem = DISQgetGuidFromItemId(inventoryId, nil, GetHashKey("CHARACTER"), 0xA1212100)
    if not characterItem then
        return false
    end
    print(characterItem)
    local wardrobeItem = DISQgetGuidFromItemId(inventoryId, characterItem, GetHashKey("WARDROBE"), 0x3DABBFA7)
    if not wardrobeItem then
        return false 
    end
 
    local itemData = DataView.ArrayBuffer(8 * 13)
 
    -- _INVENTORY_ADD_ITEM_WITH_GUID
    local isAdded = Citizen.InvokeNative("0xCB5D11F9508A928D", inventoryId, itemData:Buffer(), wardrobeItem, itemHash, slotHash, 1, addReason);
    if not isAdded then 
        return false
    end
 
    -- _INVENTORY_EQUIP_ITEM_WITH_GUID
    local equipped = Citizen.InvokeNative("0x734311E2852760D0", inventoryId, itemData:Buffer(), true);
    return equipped;
end
 
RegisterCommand("dual", function()
    --[[addWardrobeInventoryItem("CLOTHING_ITEM_M_OFFHAND_000_TINT_004", 0xF20B6B4A);
    addWardrobeInventoryItem("UPGRADE_OFFHAND_HOLSTER", 0x39E57B01);--]]

    addWeapon('WEAPON_SHOTGUN_SAWEDOFF', 0, 1)
    addWeapon('WEAPON_SHOTGUN_SAWEDOFF', 1, 2)
end)