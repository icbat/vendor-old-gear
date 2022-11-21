if icbat_vog_options == nil then
    icbat_vog_options = {}
end

icbat_vog_options['item_ids_blacklist'] = icbat_vog_options['item_ids_blacklist'] or {75274 -- Zen Alchemist Stone
}
icbat_vog_options['item_ids_whitelist'] = icbat_vog_options['item_ids_whitelist'] or {}

if icbat_vog_per_char_options == nil then
    icbat_vog_per_char_options = {}
end

icbat_vog_per_char_options['dryrun'] = icbat_vog_per_char_options['dryrun'] or true
icbat_vog_per_char_options['show_output'] = icbat_vog_per_char_options['show_output'] or true
icbat_vog_per_char_options['to_sell_at_once'] = icbat_vog_per_char_options['to_sell_at_once'] or 12
icbat_vog_per_char_options['item_level_cap'] = icbat_vog_per_char_options['item_level_cap'] or 100
