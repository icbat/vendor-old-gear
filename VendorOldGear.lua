-- TODO leveling gear honks, needs a wider range to accept levels
-- TODO data broker display to preview what it would sell
-- DevTools_Dump(itemInfo)

local debug_logging_enabled = false
local function debug_log(...)
    if debug_logging_enabled == true then
        print(...)
    end
end

local function IsTrash(container, slot)
    local itemInfo = C_Container.GetContainerItemInfo(container, slot)

    if itemInfo == nil then
        return false
    end

    if itemInfo["hasNoValue"] then
        return false
    end

    return itemInfo["quality"] == 0
end

local function IsWhitelisted(container, slot)
    local itemInfo = C_Container.GetContainerItemInfo(container, slot)

    if itemInfo == nil then
        return false
    end

    if itemInfo["hasNoValue"] then
        return false
    end

    for i, whitelisted_id in ipairs(icbat_vog_options['item_ids_whitelist']) do
        if itemInfo["itemID"] == whitelisted_id then
            debug_log("Should sell, whitelisted", itemInfo["hyperlink"])
            return true
        end
    end

    return false
end

local function IsOldGear(container, slot)
    local itemInfo = C_Container.GetContainerItemInfo(container, slot)

    if itemInfo == nil then
        return false
    end

    for _, blacklisted_id in pairs(icbat_vog_options['item_ids_blacklist']) do
        if itemInfo["itemID"] == blacklisted_id then
            debug_log("Not selling, blacklisted not to sell", itemInfo["hyperlink"])
            return false
        end
    end

    if itemInfo["hasNoValue"] then
        debug_log("Not selling, flagged as no value", itemInfo["hyperlink"])
        return false
    end

    if not itemInfo["isBound"] then
        debug_log("Not selling, not currently soulbound", itemInfo["hyperlink"])
        return false
    end

    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc,
        itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemInfo["itemID"])

    local isInSet, whichSet = C_Container.GetContainerItemEquipmentSetInfo(container, slot)

    if isInSet then
        debug_log("Not selling, this is in an equipment set", itemInfo["hyperlink"])
        return false
    end

    if itemMinLevel < UnitLevel("player") then
        debug_log("??", itemInfo["hyperlink"]. itemMinLevel, UnitLevel("player"))
        return false
    end

    if itemSubType == "Fishing Poles" then
        debug_log("Not selling this Fishing Pole", itemInfo["hyperlink"])
        return false
    end

    if itemEquipLoc == "" then
        if itemSubType == "Artifact Relic" then
            debug_log("Should sell Legion artifact relics", itemInfo["hyperlink"])
            return true
        end

        -- Attempts to pick out the old class tokens
        if bindType ~= 1 or itemQuality ~= 4 or itemSubType ~= "Junk" then
            debug_log("Not selling class tokens", itemInfo["hyperlink"])
            return false
        end
    end

    if itemLevel >= icbat_vog_options['item_level_cap'] then
        debug_log("Not selling because it's lower than the defined item level in config", itemInfo["hyperlink"], icbat_vog_options['item_level_cap'])
        return false
    end

    debug_log("Should sell", itemInfo["hyperlink"])
    return true
end

local function FindTrash()
    local vendorTrash = {}

    for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(container) do
            if IsTrash(container, slot) then
                table.insert(vendorTrash, {container, slot})
            end
        end
    end

    return vendorTrash
end

local function FindWhitelist()
    local whitelist = {}

    for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(container) do
            if IsWhitelisted(container, slot) then
                table.insert(whitelist, {container, slot})
            end
        end
    end

    return whitelist
end

local function FindOldGear()
    local oldGear = {}

    for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(container) do
            if icbat_vog_options['to_sell_at_once'] >= 0 and table.getn(oldGear) >= icbat_vog_options['to_sell_at_once'] then
                break
            end

            if IsOldGear(container, slot) then
                table.insert(oldGear, {container, slot})
            end
        end
    end

    return oldGear
end

local function SellItem(container, slot, isDryRun)
    if UnitLevel("player") < GetMaxLevelForLatestExpansion() then
        if icbat_vog_options['show_output'] then
            local itemInfo = C_Container.GetContainerItemInfo(container, slot)
            print("Will not automatically sell 'old gear' below level", GetMaxLevelForLatestExpansion(), itemInfo["hyperlink"])
        end
        return
    end
    if icbat_vog_options['show_output'] then
        local itemInfo = C_Container.GetContainerItemInfo(container, slot)
        print("Selling: ", itemInfo["hyperlink"])
    end
    if isDryRun then
        return
    end
    C_Container.PickupContainerItem(container, slot)
    SellCursorItem()
end

local function SellOldGear()
    if icbat_vog_options['dryrun'] then
        print(
            "Dry Run! Not selling auto-detected items. Turn this off in Interface options when you're confident this addon won't sell anything you need!")
    end
    local vendorTrash = FindTrash()
    for _, v in pairs(vendorTrash) do
        SellItem(v[1], v[2], false)
    end

    local whitelisted = FindWhitelist()
    for _, v in pairs(whitelisted) do
        SellItem(v[1], v[2], false)
    end

    local toSell = FindOldGear()
    for _, v in pairs(toSell) do
        SellItem(v[1], v[2], icbat_vog_options['dryrun'])
    end
end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")
f:SetScript("OnEvent", SellOldGear)
f:RegisterEvent("MERCHANT_SHOW")
