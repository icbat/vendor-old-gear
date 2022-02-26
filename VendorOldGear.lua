-- TODO leveling gear honks, needs a wider range to accept levels
-- TODO data broker display to preview what it would sell
local function IsTrash(container, slot)
    local _, _, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound =
        GetContainerItemInfo(container, slot)

    if not itemID then
        return false
    end

    if noValue then
        return false
    end

    return quality == 0
end

local function IsWhitelisted(container, slot)
    local _, _, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound =
        GetContainerItemInfo(container, slot)

    if not itemID then
        return false
    end

    if noValue then
        return false
    end

    for i, whitelisted_id in ipairs(icbat_vog_options['item_ids_whitelist']) do
        if itemID == whitelisted_id then
            return true
        end
    end

    return false
end

local function IsOldGear(container, slot)
    local _, _, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound =
        GetContainerItemInfo(container, slot)

    if not itemID then
        return false
    end

    for _, blacklisted_id in pairs(icbat_vog_options['item_ids_blacklist']) do
        if itemID == blacklisted_id then
            return false
        end
    end

    if noValue then
        return false
    end

    if not isBound then
        return false
    end

    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc,
        itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent = GetItemInfo(itemID)

    local isInSet, whichSet = GetContainerItemEquipmentSetInfo(container, slot)

    if isInSet then
        return false
    end

    if itemMinLevel < UnitLevel("unit") then
        return false
    end

    if itemSubType == "Fishing Poles" then
        return false
    end

    if itemEquipLoc == "" then
        if itemSubType == "Artifact Relic" then
            return true
        end

        -- Attempts to pick out the old class tokens
        if bindType ~= 1 or itemQuality ~= 4 or itemSubType ~= "Junk" then
            return false
        end
    end

    if itemLevel >= icbat_vog_options['item_level_cap'] then
        return false
    end

    return true
end

local function FindTrash()
    local vendorTrash = {}

    for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(container) do
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
        for slot = 1, GetContainerNumSlots(container) do
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
        for slot = 1, GetContainerNumSlots(container) do
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
    if icbat_vog_options['show_output'] then
        local _, _, _, _, _, _, itemLink = GetContainerItemInfo(container, slot)
        print("Selling: " .. itemLink)
    end
    if isDryRun then
        return
    end
    PickupContainerItem(container, slot)
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
