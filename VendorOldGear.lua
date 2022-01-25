local ITEM_LEVEL_CAP = 100
local TO_SELL_AT_ONCE = 12
local SHOW_OUTPUT = true
local DRY_RUN = true
local BLACKLISTED_ITEM_IDS = {75274 -- Zen Alchemist Stone
}

-- TODO take the config stuff and let it be configured somehow; simple options panel?
-- TODO leveling gear honks, needs a wider range to accept levels

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

local function IsOldGear(container, slot)
    local _, _, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound =
        GetContainerItemInfo(container, slot)

    if not itemID then
        return false
    end

    for _, blacklisted_id in pairs(BLACKLISTED_ITEM_IDS) do
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

    if itemEquipLoc == "" then
        -- Attempts to pick out the old class tokens
        if bindType ~= 1 or itemQuality ~= 4 or itemSubType ~= "Junk" then
            return false
        end
    end

    if itemLevel > ITEM_LEVEL_CAP then
        return false
    end

    print(itemID)

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

local function FindOldGear()
    local oldGear = {}

    for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(container) do
            if TO_SELL_AT_ONCE >= 0 and table.getn(oldGear) >= TO_SELL_AT_ONCE then
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
    if SHOW_OUTPUT then
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
    if DRY_RUN then
        print("Dry Run! This addon is still in development, it won't sell anything yet!")
    end
    local vendorTrash = FindTrash()
    for _, v in pairs(vendorTrash) do
        SellItem(v[1], v[2], false)
    end

    local toSell = FindOldGear()
    for _, v in pairs(toSell) do
        SellItem(v[1], v[2], DRY_RUN)
    end
end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")
f:SetScript("OnEvent", SellOldGear)
f:RegisterEvent("MERCHANT_SHOW")
