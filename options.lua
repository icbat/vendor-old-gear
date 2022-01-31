local ADDON, namespace = ...

local function build_list_options(list_name, list)
    local table = {
        add_new = {
            name = "Add to " .. list_name,
            type = "input",
            order = 1,
            set = function(info, val)
                local item_id = GetItemInfoInstant(val)
                if item_id then
                    table.insert(list, item_id)
                end
            end
        },
        divider = {
            order = 2,
            type = "header",
            name = "Remove from " .. list_name
        }
    }

    for i, item_id in ipairs(list) do
        local display = "" .. item_id

        local _name, link, _qual, _icon = GetItemInfo(item_id)
        if link ~= nil then
            display = link
        end

        table["" .. item_id] = {
            order = i + 2,
            name = display,
            type = 'execute',
            func = function()
                list[i] = nil
            end
        }
    end
    return table
end

local function build_options()
    return {
        type = "group",
        args = {
            general_options = {
                order = 1,
                name = "General Options",
                type = "header"
            },
            show_output = {
                order = 2,
                name = "Show Output",
                desc = "Prints out the names of everything we're selling to the chat window",
                type = "toggle",
                set = function(info, val)
                    icbat_vog_options['show_output'] = val
                end,
                get = function(info)
                    return icbat_vog_options['show_output']
                end
            },
            automatic_selling = {
                order = 50,
                name = "Automated Selling Options",
                type = "header"
            },
            dryrun = {
                order = 51,
                name = "Dry Run",
                desc = "If enabled, this will NOT sell anything we detect via rules. Trash and any whitelisted items will still be sold.",
                type = "toggle",
                set = function(info, val)
                    icbat_vog_options['dryrun'] = val
                end,
                get = function(info)
                    return icbat_vog_options['dryrun']
                end
            },
            to_sell_at_once = {
                order = 52,
                name = "To Sell at Once",
                desc = "How many items should we automatically sell at once. Defaults to 12, which is a full page of buyback. Set to 0 to remove the limit and sell everything. These will always be after trash and whitelisted items.",
                type = "range",
                min = 0,
                max = 12,
                set = function(info, val)
                    icbat_vog_options['to_sell_at_once'] = val
                end,
                get = function(info)
                    return icbat_vog_options['to_sell_at_once']
                end
            },
            item_level_cap = {
                order = 53,
                name = "Minimum Item Level to keep",
                desc = "Soundbound gear above this number won't be sold (unless whitelisted).",
                type = "range",
                min = 0,
                max = 999,
                set = function(info, val)
                    icbat_vog_options['item_level_cap'] = val
                end,
                get = function(info)
                    return icbat_vog_options['item_level_cap']
                end
            },
            blacklist = {
                order = 40,
                name = "Never Sell",
                type = "group",
                args = build_list_options("blacklist", icbat_vog_options['item_ids_blacklist'])
            },
            whitelist = {
                order = 30,
                name = "Always Sell",
                type = "group",
                args = build_list_options("whitelist", icbat_vog_options['item_ids_whitelist'])
            }
        }
    }
end

local AceConfig = LibStub("AceConfig-3.0")
AceConfig:RegisterOptionsTable("Vendor Old Gear", build_options)
namespace.options_panel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Vendor Old Gear", "Vendor Old Gear")
