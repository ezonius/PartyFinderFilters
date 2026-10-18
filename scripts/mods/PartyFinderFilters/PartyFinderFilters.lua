local mod = get_mod("PartyFinderFilters")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")

-- Add this to ensure UIRenderer is globally available or use our local one correctly
if not _G.UIRenderer then
    _G.UIRenderer = UIRenderer
end

local CUSTOM_TAG_PREFIX = "lf_class_"
local CUSTOM_HAVOC_TAG_PREFIX = "lf_havoc_"
local CUSTOM_HAVOC_RANK_TAG_PREFIX = "lf_havoc_rank_"
local CUSTOM_BLOCKED_TAG_NAME = "lf_blocked"
local CUSTOM_ROOT_TAG_NAME = "lf_class_filter"
local CUSTOM_HAVOC_ROOT_TAG_NAME = "lf_havoc_filter"
local CUSTOM_HAVOC_RANK_ROOT_TAG_NAME = "lf_havoc_rank_filter"
local CUSTOM_FILTERS_ROOT_TAG_NAME = "lf_custom_filters"

local CLASS_LIST = {
    "veteran",
    "zealot",
    "psyker",
    "ogryn",
    "broker",
    "adamant",
    "cryptic",
}

local HAVOC_LIST = {
    "mutator_havoc_enemies_parasite_headshot",
    "mutator_havoc_rotten_armor",
    "mutator_havoc_tougher_skin",
    "mutator_havoc_enemies_corrupted",
    "mutator_encroaching_garden",
    "mutator_havoc_enraged",
    "mutator_bolstering_minions",
    "mutator_monster_spawner",
    "mutator_common_minions_on_fire",
}

local HAVOC_RANK_LIST = {
    "1_19",
    "20_29",
    "30_40",
}

local selected_classes = {}
local selected_havoc = {}
local selected_havoc_rank = {}
local filter_blocked_players = false
local injected_tags = {}
local update_timer = 0
local active_group_finder_view = nil

local function get_local_player_class()
    local local_player = Managers.player and Managers.player:local_player(1)
    if local_player then
        local profile = local_player:profile()
        if profile and profile.archetype then
            return profile.archetype.name
        end
    end
    return nil
end

local function is_custom_tag(tag_name)
    if not tag_name then return false end
    return string.sub(tag_name, 1, #CUSTOM_TAG_PREFIX) == CUSTOM_TAG_PREFIX
        or string.sub(tag_name, 1, #CUSTOM_HAVOC_TAG_PREFIX) == CUSTOM_HAVOC_TAG_PREFIX
        or string.sub(tag_name, 1, #CUSTOM_HAVOC_RANK_TAG_PREFIX) == CUSTOM_HAVOC_RANK_TAG_PREFIX
        or tag_name == CUSTOM_BLOCKED_TAG_NAME
        or tag_name == CUSTOM_ROOT_TAG_NAME
        or tag_name == CUSTOM_HAVOC_ROOT_TAG_NAME
        or tag_name == CUSTOM_HAVOC_RANK_ROOT_TAG_NAME
        or tag_name == CUSTOM_FILTERS_ROOT_TAG_NAME
end

local function get_class_from_tag_name(tag_name)
    if string.sub(tag_name, 1, #CUSTOM_TAG_PREFIX) == CUSTOM_TAG_PREFIX then
        return string.sub(tag_name, #CUSTOM_TAG_PREFIX + 1)
    end
    return nil
end

local function get_havoc_from_tag_name(tag_name)
    if string.sub(tag_name, 1, #CUSTOM_HAVOC_TAG_PREFIX) == CUSTOM_HAVOC_TAG_PREFIX then
        return string.sub(tag_name, #CUSTOM_HAVOC_TAG_PREFIX + 1)
    end
    return nil
end

local function get_havoc_rank_from_tag_name(tag_name)
    if string.sub(tag_name, 1, #CUSTOM_HAVOC_RANK_TAG_PREFIX) == CUSTOM_HAVOC_RANK_TAG_PREFIX then
        return string.sub(tag_name, #CUSTOM_HAVOC_RANK_TAG_PREFIX + 1)
    end
    return nil
end

local function create_custom_filters_root_tag()
    return {
        name = CUSTOM_FILTERS_ROOT_TAG_NAME,
        root_tag = true,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("custom_filters"),
        unlocks = { CUSTOM_ROOT_TAG_NAME, CUSTOM_HAVOC_ROOT_TAG_NAME, CUSTOM_HAVOC_RANK_ROOT_TAG_NAME, CUSTOM_BLOCKED_TAG_NAME },
        locked = false,
        mutually_exclusive = nil,
        parents = nil,
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_blocked_tag()
    return {
        name = CUSTOM_BLOCKED_TAG_NAME,
        root_tag = false,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("filter_blocked"),
        unlocks = nil,
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_FILTERS_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_class_root_tag()
    return {
        name = CUSTOM_ROOT_TAG_NAME,
        root_tag = true,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("filter_class"),
        unlocks = {},
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_FILTERS_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_havoc_root_tag()
    return {
        name = CUSTOM_HAVOC_ROOT_TAG_NAME,
        root_tag = true,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("filter_havoc"),
        unlocks = {},
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_FILTERS_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_havoc_rank_root_tag()
    return {
        name = CUSTOM_HAVOC_RANK_ROOT_TAG_NAME,
        root_tag = true,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("filter_havoc_rank"),
        unlocks = {},
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_FILTERS_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_class_tag(class_name)
    local child_tag_name = CUSTOM_TAG_PREFIX .. class_name
    return {
        name = child_tag_name,
        root_tag = false,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("class_" .. class_name),
        unlocks = nil,
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_havoc_tag(havoc_name)
    local child_tag_name = CUSTOM_HAVOC_TAG_PREFIX .. havoc_name
    return {
        name = child_tag_name,
        root_tag = false,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize(havoc_name),
        unlocks = nil,
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_HAVOC_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function create_havoc_rank_tag(rank_name)
    local child_tag_name = CUSTOM_HAVOC_RANK_TAG_PREFIX .. rank_name
    return {
        name = child_tag_name,
        root_tag = false,
        ui_category = "custom_filters",
        widget_type = "tag_default",
        text = mod:localize("havoc_rank_" .. rank_name),
        unlocks = nil,
        locked = false,
        mutually_exclusive = nil,
        parents = { CUSTOM_HAVOC_RANK_ROOT_TAG_NAME },
        level_requirement = 0,
        access_requirement = nil,
        difficulty_requirement = nil,
        display_mode = nil,
        header = nil,
        background_texture = nil,
        difficulty = nil,
    }
end

local function group_has_filtered_class(group_data, social_service)
    if not group_data or not group_data.members then return false end

    local members = group_data.members
    for i = 1, #members do
        local account_id = members[i].account_id
        if account_id and social_service then
            local player_info = social_service:get_player_info_by_account_id(account_id)
            if player_info then
                local profile = player_info:profile()
                if profile and profile.archetype then
                    local class_name = string.lower(profile.archetype.name)
                    if selected_classes[class_name] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function group_has_filtered_havoc(group_data)
    if not group_data or not group_data.metadata or not group_data.metadata.havoc_circumstances then return false end

    local circumstances = group_data.metadata.havoc_circumstances
    for i = 1, #circumstances do
        local circumstance = circumstances[i]
        if selected_havoc[circumstance] then
            return true
        end
    end
    return false
end

local function group_has_filtered_havoc_rank(group_data)
    if not group_data or not group_data.metadata then return true end

    local rank = tonumber(group_data.metadata.havoc_order_rank)
    if not rank then return true end

    if selected_havoc_rank["30_40"] then
        if rank >= 30 and rank <= 40 then
            return false
        end
    end

    return true
end

local function group_has_blocked_player(group_data, social_service)
    if not group_data or not group_data.members then return false end

    local members = group_data.members
    for i = 1, #members do
        local account_id = members[i].account_id
        if account_id and social_service then
            local player_info = social_service:get_player_info_by_account_id(account_id)
            if player_info and player_info:is_blocked() then
                return true
            end
        end
    end
    return false
end

local function filter_groups_by_custom_filters(groups)
    if not groups or #groups == 0 then return false end

    local has_class_selection = false
    for _, _ in pairs(selected_classes) do
        has_class_selection = true
        break
    end

    local has_havoc_selection = false
    for _, _ in pairs(selected_havoc) do
        has_havoc_selection = true
        break
    end

    local has_havoc_rank_selection = false
    for _, _ in pairs(selected_havoc_rank) do
        has_havoc_rank_selection = true
        break
    end

    if not has_class_selection and not has_havoc_selection and not has_havoc_rank_selection and not filter_blocked_players then return false end

    local social_service = Managers.data_service and Managers.data_service.social
    local needs_rebuild = false
    for i = #groups, 1, -1 do
        local group = groups[i]
        local filtered = false

        if filter_blocked_players and social_service then
            if group_has_blocked_player(group, social_service) then
                filtered = true
            end
        end

        if not filtered and has_class_selection and social_service then
            if group_has_filtered_class(group, social_service) then
                filtered = true
            end
        end

        if not filtered and has_havoc_selection then
            if group_has_filtered_havoc(group) then
                filtered = true
            end
        end

        if not filtered and has_havoc_rank_selection then
            if group_has_filtered_havoc_rank(group) then
                filtered = true
            end
        end

        if filtered then
            table.remove(groups, i)
            needs_rebuild = true
        end
    end

    return needs_rebuild
end

mod:hook("ViewElementGrid", "draw", function(func, self, dt, t, ui_renderer, input_service, render_settings)
    local widgets = self._widgets
    if widgets then
        for i = #widgets, 1, -1 do
            if widgets[i] == nil then
                table.remove(widgets, i)
            end
        end
    end
    local grid_widgets = self._grid_widgets
    if grid_widgets then
        for i = #grid_widgets, 1, -1 do
            if grid_widgets[i] == nil then
                table.remove(grid_widgets, i)
            end
        end
    end

    local widgets_by_name = self._widgets_by_name
    if not widgets_by_name or not widgets_by_name.grid_background or not widgets_by_name.grid_interaction then
        return
    end

    return func(self, dt, t, ui_renderer, input_service, render_settings)
end)

mod:hook("ViewElementGrid", "_draw_grid", function(func, self, dt, t, ui_renderer, input_service, render_settings)
    local grid = self._grid
    if not grid then
        return
    end

    local widgets_by_name = self._widgets_by_name
    if not widgets_by_name or not widgets_by_name.grid_interaction then
        return
    end

    local widgets = self._grid_widgets
    if widgets then
        for i = #widgets, 1, -1 do
            if widgets[i] == nil then
                table.remove(widgets, i)
            end
        end
    end

    local interaction_widget = widgets_by_name.grid_interaction
    local hotspot = interaction_widget.content.hotspot
    local is_grid_hovered = not self._using_cursor_navigation or (hotspot and hotspot.is_hover) or false
    is_grid_hovered = is_grid_hovered and not self._input_disabled

    local ui_resource_renderer = self._ui_resource_renderer
    local ui_scenegraph = self._ui_scenegraph
    local ui_grid_renderer = self._ui_grid_renderer
    local widget_renderer = ui_resource_renderer
    local no_resource_rendering = self._no_resource_rendering

    if no_resource_rendering then
        ui_grid_renderer = ui_renderer
        widget_renderer = ui_renderer
    end

    if not no_resource_rendering then
        local base_render_pass = ui_resource_renderer.base_render_pass
        local render_target = ui_resource_renderer.render_target

        UIRenderer.add_render_pass(ui_grid_renderer, 0, base_render_pass, true, render_target)
        UIRenderer.add_render_pass(ui_grid_renderer, 1, "to_screen", false)
    end

    UIRenderer.begin_pass(widget_renderer, ui_scenegraph, input_service, dt, render_settings)

    if self._resource_renderer_background then
        UIWidget.draw(self._widgets_by_name.grid_background, widget_renderer)
    end

    for i = 1, #widgets do
        local widget = widgets[i]
        if widget then
            local content = widget.content
            if content then
                local visible = content.visible
                local previous_visibility_state = content.visible_last_frame

                if visible or previous_visibility_state ~= visible then
                    local hotspot = content.hotspot

                    if hotspot then
                        hotspot.force_disabled = not is_grid_hovered
                    end

                    UIWidget.draw(widget, widget_renderer)
                end
            end
        end
    end

    UIRenderer.end_pass(widget_renderer)
end)

mod:hook_safe("GroupFinderView", "_on_fetching_tags_complete", function(self)
    active_group_finder_view = self

    -- Clean up any existing custom tags from the tags list to prevent duplicates
    local tags = self._tags
    for i = #tags, 1, -1 do
        if is_custom_tag(tags[i].name) then
            table.remove(tags, i)
        end
    end

    injected_tags = {}

    local custom_filters_root = create_custom_filters_root_tag()
    local class_root = create_class_root_tag()
    local havoc_root = create_havoc_root_tag()
    local havoc_rank_root = create_havoc_rank_root_tag()

    local class_tag_names = {}
    for _, class_name in ipairs(CLASS_LIST) do
        local child_tag = create_class_tag(class_name)
        injected_tags[child_tag.name] = child_tag
        class_tag_names[#class_tag_names + 1] = child_tag.name
        self._tags[#self._tags + 1] = child_tag
    end

    class_root.unlocks = class_tag_names
    injected_tags[class_root.name] = class_root
    self._tags[#self._tags + 1] = class_root

    local havoc_tag_names = {}
    for _, havoc_name in ipairs(HAVOC_LIST) do
        local child_tag = create_havoc_tag(havoc_name)
        injected_tags[child_tag.name] = child_tag
        havoc_tag_names[#havoc_tag_names + 1] = child_tag.name
        self._tags[#self._tags + 1] = child_tag
    end

    havoc_root.unlocks = havoc_tag_names
    injected_tags[havoc_root.name] = havoc_root
    self._tags[#self._tags + 1] = havoc_root

    local havoc_rank_tag_names = {}
    for _, rank_name in ipairs(HAVOC_RANK_LIST) do
        local child_tag = create_havoc_rank_tag(rank_name)
        injected_tags[child_tag.name] = child_tag
        havoc_rank_tag_names[#havoc_rank_tag_names + 1] = child_tag.name
        self._tags[#self._tags + 1] = child_tag
    end

    havoc_rank_root.unlocks = havoc_rank_tag_names
    injected_tags[havoc_rank_root.name] = havoc_rank_root
    self._tags[#self._tags + 1] = havoc_rank_root

    local blocked_tag = create_blocked_tag()
    injected_tags[blocked_tag.name] = blocked_tag
    self._tags[#self._tags + 1] = blocked_tag

    injected_tags[custom_filters_root.name] = custom_filters_root
    tags[#tags + 1] = custom_filters_root

    local visited_tag_pages = self._visited_tag_pages
    if visited_tag_pages and visited_tag_pages[1] then
        local first_page = visited_tag_pages[1]
        local found = false
        for i = 1, #first_page do
            if first_page[i].name == CUSTOM_FILTERS_ROOT_TAG_NAME then
                first_page[i] = custom_filters_root
                found = true
                break
            end
        end
        if not found then
            first_page[#first_page + 1] = custom_filters_root
        end
    end

    if mod:get("auto_check_class") then
        local user_class = get_local_player_class()
        if user_class then
            local user_class_lower = string.lower(user_class)
            -- Clear all classes in CLASS_LIST before applying the current one
            for _, class_name in ipairs(CLASS_LIST) do
                selected_classes[class_name] = nil
            end

            selected_classes[user_class_lower] = true
        end
    else
        for _, class_name in ipairs(CLASS_LIST) do
            if mod:get("default_exclude_" .. class_name) then
                selected_classes[class_name] = true
            else
                selected_classes[class_name] = nil
            end
        end
    end

    for _, havoc_name in ipairs(HAVOC_LIST) do
        if mod:get("default_exclude_" .. havoc_name) then
            selected_havoc[havoc_name] = true
        else
            selected_havoc[havoc_name] = nil
        end
    end

    for _, rank_name in ipairs(HAVOC_RANK_LIST) do
        if mod:get("default_exclude_havoc_rank_" .. rank_name) then
            selected_havoc_rank[rank_name] = true
        else
            selected_havoc_rank[rank_name] = nil
        end
    end

    filter_blocked_players = mod:get("default_exclude_blocked")

    self:_update_tag_grid()
    self:_update_tag_navigation_buttons_status()
end)

mod:hook_safe("GroupFinderView", "on_exit", function(self)
    active_group_finder_view = nil
    injected_tags = {}
end)

mod:hook("GroupFinderView", "_can_select_tag", function(func, self, tag, _ignore_tag_name)
    if tag and is_custom_tag(tag.name) then
        if tag.root_tag then
            return false
        end
        return true
    end
    return func(self, tag, _ignore_tag_name)
end)

mod:hook("GroupFinderView", "_cb_on_list_tag_pressed", function(func, self, element)
    if not element or not element.tag then
        return func(self, element)
    end

    local tag = element.tag
    local tag_name = tag.name

    if not is_custom_tag(tag_name) then
        return func(self, element)
    end

    if tag_name == CUSTOM_FILTERS_ROOT_TAG_NAME or tag_name == CUSTOM_ROOT_TAG_NAME or tag_name == CUSTOM_HAVOC_ROOT_TAG_NAME or tag_name == CUSTOM_HAVOC_RANK_ROOT_TAG_NAME then
        self:_handle_next_filter_button_options(tag)
        return
    end

    if tag_name == CUSTOM_BLOCKED_TAG_NAME then
        filter_blocked_players = not filter_blocked_players
        self:_update_tag_widgets()
        self:_reset_search()
        return
    end

    local rank_name = get_havoc_rank_from_tag_name(tag_name)
    if rank_name then
        if selected_havoc_rank[rank_name] then
            selected_havoc_rank[rank_name] = nil
        else
            selected_havoc_rank[rank_name] = true
        end

        self:_update_tag_widgets()
        self:_reset_search()
        return
    end

    local havoc_name = get_havoc_from_tag_name(tag_name)
    if havoc_name then
        if selected_havoc[havoc_name] then
            selected_havoc[havoc_name] = nil
        else
            selected_havoc[havoc_name] = true
        end

        self:_update_tag_widgets()
        self:_reset_search()
        return
    end

    local class_name = get_class_from_tag_name(tag_name)
    if class_name then
        if selected_classes[class_name] then
            selected_classes[class_name] = nil
        else
            selected_classes[class_name] = true
        end

        self:_update_tag_widgets()
        self:_reset_search()
        return
    end

    return func(self, element)
end)

mod:hook_safe("GroupFinderView", "_update_tag_widgets", function(self, clear_slot_widgets)
    local tags_grid = self._tags_grid
    if not tags_grid then return end

    local grid_widgets = tags_grid:widgets()
    if not grid_widgets then return end

    for i = 1, #grid_widgets do
        local grid_widget = grid_widgets[i]
        if grid_widget then
            local content = grid_widget.content
            local widget_element = content.element

            if widget_element and widget_element.tag then
                local tag = widget_element.tag
                local tag_name = tag.name

                if is_custom_tag(tag_name) and not tag.root_tag then
                    local rank_name = get_havoc_rank_from_tag_name(tag_name)
                    if rank_name then
                        content.checked = selected_havoc_rank[rank_name] == true
                    else
                        local havoc_name = get_havoc_from_tag_name(tag_name)
                        if havoc_name then
                            content.checked = selected_havoc[havoc_name] == true
                        else
                            local class_name = get_class_from_tag_name(tag_name)
                            if class_name then
                                content.checked = selected_classes[class_name] == true
                            else
                                if tag_name == CUSTOM_BLOCKED_TAG_NAME then
                                    content.checked = filter_blocked_players == true
                                end
                            end
                        end
                    end
                end

                if tag_name == CUSTOM_ROOT_TAG_NAME or tag_name == CUSTOM_HAVOC_ROOT_TAG_NAME or tag_name == CUSTOM_HAVOC_RANK_ROOT_TAG_NAME or tag_name == CUSTOM_FILTERS_ROOT_TAG_NAME then
                    local count = 0
                    for _, _ in pairs(selected_classes) do
                        count = count + 1
                    end
                    for _, _ in pairs(selected_havoc) do
                        count = count + 1
                    end
                    for _, _ in pairs(selected_havoc_rank) do
                        count = count + 1
                    end
                    if filter_blocked_players then
                        count = count + 1
                    end

                    local base_text = ""
                    if tag_name == CUSTOM_ROOT_TAG_NAME then
                        base_text = mod:localize("filter_class")
                        count = 0
                        for _, _ in pairs(selected_classes) do count = count + 1 end
                    elseif tag_name == CUSTOM_HAVOC_ROOT_TAG_NAME then
                        base_text = mod:localize("filter_havoc")
                        count = 0
                        for _, _ in pairs(selected_havoc) do count = count + 1 end
                    elseif tag_name == CUSTOM_HAVOC_RANK_ROOT_TAG_NAME then
                        base_text = mod:localize("filter_havoc_rank")
                        count = 0
                        for _, _ in pairs(selected_havoc_rank) do count = count + 1 end
                    else
                        base_text = mod:localize("custom_filters")
                    end

                    if count > 0 then
                        content.text = base_text .. " (" .. tostring(count) .. ")"
                    else
                        content.text = base_text
                    end
                end
            end
        end
    end
end)

mod:hook("GroupFinderView", "_start_advertisements_stream", function(func, self)
    local removed_tags = {}
    local selected_tags = self._selected_tags

    for i = #selected_tags, 1, -1 do
        if is_custom_tag(selected_tags[i].name) then
            removed_tags[#removed_tags + 1] = table.remove(selected_tags, i)
        end
    end

    local result = func(self)

    for i = 1, #removed_tags do
        selected_tags[#selected_tags + 1] = removed_tags[i]
    end

    return result
end)

mod:hook("GroupFinderView", "_populate_group_grid", function(func, self, groups, ...)
    filter_groups_by_custom_filters(groups)
    return func(self, groups, ...)
end)

mod:hook_safe("GroupFinderView", "_update_group_grid", function(self)
    if self._groups then
        local needs_rebuild = filter_groups_by_custom_filters(self._groups)
        if needs_rebuild then
            self:_populate_group_grid(self._groups)
        end
    end
end)

mod:hook_safe("GroupFinderView", "update", function(self, dt, t, input_service)
    if self._state == "browsing" and self._groups then
        update_timer = update_timer + dt
        if update_timer > 0.5 then
            update_timer = 0
            local needs_rebuild = filter_groups_by_custom_filters(self._groups)
            if needs_rebuild then
                self:_populate_group_grid(self._groups)
            end
        end
    end
end)

mod:hook_safe("GroupFinderView", "cb_on_clear_pressed", function(self)
    selected_classes = {}
    selected_havoc = {}
    selected_havoc_rank = {}
    filter_blocked_players = false
end)

mod:hook("GroupFinderView", "_get_page_descripion_by_category", function(func, self, category_name)
    if category_name == "custom_filters" then
        return mod:localize("custom_filters_description")
    end
    return func(self, category_name)
end)
