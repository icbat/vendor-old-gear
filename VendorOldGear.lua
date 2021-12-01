local ITEM_LEVEL_CAP = 100
local TO_SELL_AT_ONCE = 12
local SHOW_OUTPUT = true

-- TODO take the config stuff and let it be configured somehow; simple options panel?
-- TODO if there are greys to sell, do nothing so we don't pollute the buyback screen?
-- TODO handle leveling? how to prevent it from doing the thing

local function IsOldGear(container, slot)
    local _, _, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID, isBound =
        GetContainerItemInfo(container, slot)

    if not itemID then
        return false
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

    if itemEquipLoc == "" then
        -- Attempts to pick out the old class tokens
        if bindType ~= 1 or itemQuality ~= 4 or itemSubType ~= "Junk" then
            return false
        end
    end

    return itemLevel < ITEM_LEVEL_CAP
end

local function FindOldGear()
    local oldGear = {}

    for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(container) do
            local oldLink = IsOldGear(container, slot)

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

local function SellItem(container, slot)
    if SHOW_OUTPUT then
        local _, _, _, _, _, _, itemLink = GetContainerItemInfo(container, slot)
        print("Selling: " .. itemLink)
    end
    PickupContainerItem(container, slot)
    SellCursorItem()
end

local function InsertKeystone()
    local toSell = FindOldGear()
    for _, v in pairs(toSell) do
        SellItem(v[1], v[2])
    end
end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")
f:SetScript("OnEvent", InsertKeystone)
f:RegisterEvent("MERCHANT_SHOW")
