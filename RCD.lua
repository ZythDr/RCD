-- RCD: Rapid Conjured Depositor for WoW 3.3.5 (Ascension/WotLK)
-- Automates the guild bank deposit exploit for conjured items.

local RCD = CreateFrame("Frame", "RCDFrame", UIParent)
RCD:Hide()

local addonName = "|cff00ff00RCD|r"
local timer = 0

-- States
local STATE_IDLE = 0
local STATE_SEARCH_TRASH = 1
local STATE_DEPOSIT = 2
local STATE_WAIT_BANK = 3
local STATE_LIFT = 4
local STATE_SWAP = 5

local state = STATE_IDLE
local conjQueue = {}
local currentTask = nil
local waitTries = 0
local startTime = 0

-- Utility: Print to chat
local function Print(msg)
    local f = DEFAULT_CHAT_FRAME or ChatFrame1
    if f then f:AddMessage(addonName .. ": " .. (msg or "nil")) end
end

-- Utility: Resolve Item ID to Name
local function ResolveItemName(input)
    local id = tonumber(input)
    if id then
        local name = GetItemInfo(id)
        if name then return name end
    end
    return input
end

-- Utility: Scan tooltips to check if an item is Conjured
local tooltipScanner = CreateFrame("GameTooltip", "RCDTooltipScanner", nil, "GameTooltipTemplate")
tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function IsItemConjured(bag, slot)
    tooltipScanner:ClearLines()
    tooltipScanner:SetBagItem(bag, slot)
    for i = 1, tooltipScanner:NumLines() do
        local text = _G["RCDTooltipScannerTextLeft" .. i]:GetText()
        if text and text:find("Conjured") then return true end
    end
    return false
end

-- Utility: Check if item matches filter
local function MatchesFilter(link, list, selected, defaultConjuredCheck)
    if not list or #list == 0 then return defaultConjuredCheck end
    
    local name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(link)
    local id = link:match("item:(%d+)")
    
    if selected == "any" then
        for _, filter in ipairs(list) do
            local filterLower = filter:lower()
            if (name and name:lower() == filterLower) or (id == filter) then
                return true
            end
        end
        return defaultConjuredCheck
    else
        local filterLower = selected:lower()
        if (name and name:lower() == filterLower) or (id == selected) then
            return true
        end
    end
    return false
end

-- Utility: Find ONE trash item matching ph_list
local function FindTrashItem()
    local list = RCD_Config.ph_list or {}
    local selected = RCD_Config.ph_selected or "any"
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, _, _, _, _, _, _, _, _, itemPrice = GetItemInfo(link)
                local isConj = IsItemConjured(bag, slot)
                if MatchesFilter(link, list, selected, not isConj and itemPrice and itemPrice > 0 and itemPrice < 1000) then
                    return { bag = bag, slot = slot, link = link }
                end
            end
        end
    end
    return nil
end

-- Utility: Find ALL conjured items matching swap_list
local function BuildConjQueue()
    local list = RCD_Config.swap_list or {}
    local selected = RCD_Config.swap_selected or "any"
    local queue = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                if MatchesFilter(link, list, selected, IsItemConjured(bag, slot)) then
                    table.insert(queue, { bag = bag, slot = slot, link = link })
                end
            end
        end
    end
    return queue
end

-- Utility: Find empty bank slot
local function FindEmptyBankSlot()
    local tab = GetCurrentGuildBankTab()
    for slot = 1, 98 do
        local _, _, locked = GetGuildBankItemInfo(tab, slot)
        local link = GetGuildBankItemLink(tab, slot)
        if not link and not locked then return tab, slot end
    end
    return nil
end

-- Main OnUpdate Loop
RCD:SetScript("OnUpdate", function(self, elapsed)
    local interval = RCD_Config and RCD_Config.delay or 0.1
    timer = timer + elapsed
    if timer < interval then return end
    timer = 0

    if state == STATE_IDLE then
        if #conjQueue > 0 then
            state = STATE_SEARCH_TRASH
            waitTries = 0
        else
            if RCD_Config.continuous then
                conjQueue = BuildConjQueue()
            else
                local duration = GetTime() - startTime
                Print(string.format("Process complete. Took %.2f seconds.", duration))
                self:Hide()
                if RCDTab then PanelTemplates_DeselectTab(RCDTab) end
            end
        end
    elseif state == STATE_SEARCH_TRASH then
        local trash = FindTrashItem()
        if trash then
            local tab, slot = FindEmptyBankSlot()
            if slot then
                currentTask = {
                    conj = table.remove(conjQueue, 1),
                    trash = trash,
                    tab = tab,
                    slot = slot
                }
                state = STATE_DEPOSIT
            else
                Print("Bank full.")
                StopProcess()
            end
        else
            waitTries = waitTries + 1
            if waitTries > 60 then
                Print("Placeholder not found.")
                StopProcess()
            end
        end
    elseif state == STATE_DEPOSIT then
        if CursorHasItem() then ClearCursor() end
        UseContainerItem(currentTask.trash.bag, currentTask.trash.slot)
        state = STATE_WAIT_BANK
        waitTries = 0
    elseif state == STATE_WAIT_BANK then
        local link = GetGuildBankItemLink(currentTask.tab, currentTask.slot)
        if link then
            state = STATE_LIFT
        else
            waitTries = waitTries + 1
            if waitTries > 30 then state = STATE_IDLE end
        end
    elseif state == STATE_LIFT then
        PickupGuildBankItem(currentTask.tab, currentTask.slot)
        state = STATE_SWAP
    elseif state == STATE_SWAP then
        PickupContainerItem(currentTask.conj.bag, currentTask.conj.slot)
        PickupGuildBankItem(currentTask.tab, currentTask.slot)
        if CursorHasItem() then
            PickupContainerItem(currentTask.trash.bag, currentTask.trash.slot)
        end
        state = STATE_IDLE
    end
end)

-- UI: Control logic
function StartProcess()
    if RCD:IsVisible() then return end
    if not GuildBankFrame or not GuildBankFrame:IsVisible() then
        Print("Open Guild Bank first.")
        return
    end
    conjQueue = BuildConjQueue()
    if #conjQueue == 0 and not RCD_Config.continuous then
        Print("No items found. Check settings.")
        if RCDTab then PanelTemplates_DeselectTab(RCDTab) end
        return
    end
    Print("Starting automation. " .. (RCD_Config.continuous and "(Continuous Mode)" or ""))
    startTime = GetTime()
    state = STATE_IDLE
    RCD:Show()
    if RCDTab then PanelTemplates_SelectTab(RCDTab) end
end

function StopProcess()
    if not RCD:IsVisible() then return end
    RCD:Hide()
    state = STATE_IDLE
    conjQueue = {}
    if CursorHasItem() then ClearCursor() end
    Print("Stopped.")
    if RCDTab then PanelTemplates_DeselectTab(RCDTab) end
end

-- UI: Static Popups
StaticPopupDialogs["RCD_ADD_PH"] = {
    text = "Add Placeholder Name or Item ID:",
    button1 = "Add", button2 = "Cancel", hasEditBox = true,
    OnAccept = function(self)
        local val = self.editBox:GetText()
        if val ~= "" then 
            local resolved = ResolveItemName(val)
            table.insert(RCD_Config.ph_list, resolved)
            Print("Added: "..resolved) 
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["RCD_ADD_SWAP"] = {
    text = "Add Swap Target Name or Item ID:",
    button1 = "Add", button2 = "Cancel", hasEditBox = true,
    OnAccept = function(self)
        local val = self.editBox:GetText()
        if val ~= "" then 
            local resolved = ResolveItemName(val)
            table.insert(RCD_Config.swap_list, resolved)
            Print("Added: "..resolved) 
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["RCD_SET_DELAY"] = {
    text = "Enter Delay in ms (min 10):",
    button1 = "Set", button2 = "Cancel", hasEditBox = true,
    OnAccept = function(self)
        local ms = tonumber(self.editBox:GetText())
        if ms and ms >= 10 then
            RCD_Config.delay = ms / 1000
            Print("Delay set to: " .. ms .. "ms")
        else
            Print("Invalid delay value.")
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- UI: Dropdown Menu
local menuFrame = CreateFrame("Frame", "RCDDropDownMenu", UIParent, "UIDropDownMenuTemplate")

local function MenuInitialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    
    if level == 1 then
        info.isTitle = true
        info.text = "RCD Options"
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = "Continuous"
        info.hasArrow = true
        info.value = "CONTINUOUS"
        info.func = function() 
            RCD_Config.continuous = not RCD_Config.continuous 
            UIDropDownMenu_Refresh(menuFrame)
        end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = "Placeholder"
        info.hasArrow = true
        info.value = "PH"
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = "Swap Target"
        info.hasArrow = true
        info.value = "SWAP"
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = "Delay"
        info.hasArrow = true
        info.value = "DELAY"
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
    elseif level == 2 then
        local parentValue = UIDROPDOWNMENU_MENU_VALUE
        if parentValue == "CONTINUOUS" then
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cff00ff00Enabled|r"
            info.func = function() RCD_Config.continuous = true; UIDropDownMenu_Refresh(menuFrame) end
            info.checked = RCD_Config.continuous
            UIDropDownMenu_AddButton(info, level)
            
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffff0000Disabled|r"
            info.func = function() RCD_Config.continuous = false; UIDropDownMenu_Refresh(menuFrame) end
            info.checked = not RCD_Config.continuous
            UIDropDownMenu_AddButton(info, level)

        elseif parentValue == "PH" then
            info = UIDropDownMenu_CreateInfo()
            info.text = "Any"
            info.func = function() RCD_Config.ph_selected = "any" end
            info.checked = (RCD_Config.ph_selected == "any")
            UIDropDownMenu_AddButton(info, level)
            
            for i, v in ipairs(RCD_Config.ph_list) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.func = function() RCD_Config.ph_selected = v end
                info.checked = (RCD_Config.ph_selected == v)
                info.hasArrow = true
                info.value = {type="PH_REMOVE", index=i, name=v}
                UIDropDownMenu_AddButton(info, level)
            end
            
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffffff00Add New|r"
            info.func = function() StaticPopup_Show("RCD_ADD_PH") end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
        elseif parentValue == "SWAP" then
            info = UIDropDownMenu_CreateInfo()
            info.text = "Any"
            info.func = function() RCD_Config.swap_selected = "any" end
            info.checked = (RCD_Config.swap_selected == "any")
            UIDropDownMenu_AddButton(info, level)
            
            for i, v in ipairs(RCD_Config.swap_list) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.func = function() RCD_Config.swap_selected = v end
                info.checked = (RCD_Config.swap_selected == v)
                info.hasArrow = true
                info.value = {type="SWAP_REMOVE", index=i, name=v}
                UIDropDownMenu_AddButton(info, level)
            end
            
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffffff00Add New|r"
            info.func = function() StaticPopup_Show("RCD_ADD_SWAP") end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
        elseif parentValue == "DELAY" then
            local options = {25, 50, 100, 200}
            for _, v in ipairs(options) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v .. " ms"
                info.func = function() RCD_Config.delay = v / 1000; Print("Delay: "..v.."ms") end
                info.checked = (RCD_Config.delay * 1000 == v)
                UIDropDownMenu_AddButton(info, level)
            end
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffffff00Custom|r"
            info.func = function() StaticPopup_Show("RCD_SET_DELAY") end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    elseif level == 3 then
        local val = UIDROPDOWNMENU_MENU_VALUE
        if val.type == "PH_REMOVE" then
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffff0000Remove "..val.name.."|r"
            info.func = function() 
                table.remove(RCD_Config.ph_list, val.index)
                if RCD_Config.ph_selected == val.name then RCD_Config.ph_selected = "any" end
                CloseDropDownMenus()
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        elseif val.type == "SWAP_REMOVE" then
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cffff0000Remove "..val.name.."|r"
            info.func = function() 
                table.remove(RCD_Config.swap_list, val.index)
                if RCD_Config.swap_selected == val.name then RCD_Config.swap_selected = "any" end
                CloseDropDownMenus()
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

-- UI: Create Bottom Tab
local function CreateRCDTab()
    if RCDTab then return end

    local tab = CreateFrame("Button", "RCDTab", GuildBankFrame, "CharacterFrameTabButtonTemplate")
    tab:SetText("RCD")
    -- Anchor to the bottom right
    tab:SetPoint("TOPRIGHT", GuildBankFrame, "BOTTOMRIGHT", -6, 10)
    
    tab:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            UIDropDownMenu_Initialize(menuFrame, MenuInitialize, "MENU")
            ToggleDropDownMenu(1, nil, menuFrame, self, 0, 0)
        else
            if RCD:IsVisible() then StopProcess() else StartProcess() end
        end
    end)
    tab:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    tab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Rapid Conjured Depositor", 1, 1, 1)
        GameTooltip:AddLine("Left-click to start/stop automation.", 0, 1, 0)
        GameTooltip:AddLine(" ")
        
        local ph_sel = RCD_Config.ph_selected
        if ph_sel == "any" then ph_sel = "Any" end
        
        local sw_sel = RCD_Config.swap_selected
        if sw_sel == "any" then sw_sel = "Any" end
        
        local dl = (RCD_Config.delay * 1000) .. "ms"
        
        GameTooltip:AddDoubleLine("Placeholder:", ph_sel, 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("Swap Target:", sw_sel, 1, 0.82, 0, 1, 1, 1)
        GameTooltip:AddDoubleLine("Delay:", dl, 1, 0.82, 0, 1, 1, 1)
        
        local cont_text = RCD_Config.continuous and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"
        GameTooltip:AddDoubleLine("Continuous Mode:", cont_text, 1, 0.82, 0, 1, 1, 1)
        
        if RCD_Config.continuous then
            if RCD:IsVisible() and #conjQueue == 0 then
                GameTooltip:AddLine("Waiting for more items...", 1, 1, 0)
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Right-click for options.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", GameTooltip_Hide)

    RCDTab = tab
    PanelTemplates_TabResize(tab, 0)
    PanelTemplates_DeselectTab(tab)

    if ElvUI then
        local E = unpack(ElvUI)
        local S = E:GetModule("Skins")
        if S and S.HandleTab then S:HandleTab(tab) end
    end
end

RCD:RegisterEvent("GUILDBANKFRAME_OPENED")
RCD:RegisterEvent("GUILDBANKFRAME_CLOSED")
RCD:RegisterEvent("ADDON_LOADED")
RCD:SetScript("OnEvent", function(self, event, arg1)
    if event == "GUILDBANKFRAME_OPENED" then
        CreateRCDTab()
        RCDTab:Show()
    elseif event == "GUILDBANKFRAME_CLOSED" then
        StopProcess()
    elseif event == "ADDON_LOADED" and arg1 == "RCD" then
        -- Universal Initialization
        if not RCD_Config then RCD_Config = {} end
        if RCD_Config.delay == nil then RCD_Config.delay = 0.1 end
        if RCD_Config.continuous == nil then RCD_Config.continuous = false end
        if RCD_Config.ph_list == nil then RCD_Config.ph_list = {} end
        if RCD_Config.swap_list == nil then RCD_Config.swap_list = {} end
        if RCD_Config.ph_selected == nil then RCD_Config.ph_selected = "any" end
        if RCD_Config.swap_selected == nil then RCD_Config.swap_selected = "any" end

        -- Migrate local configs to account-wide if they exist
        if RCD_LocalConfig then
            if RCD_LocalConfig.ph_list then
                for _, v in ipairs(RCD_LocalConfig.ph_list) do
                    local found = false
                    for _, ov in ipairs(RCD_Config.ph_list) do if ov == v then found = true end end
                    if not found then table.insert(RCD_Config.ph_list, v) end
                end
            end
            if RCD_LocalConfig.swap_list then
                for _, v in ipairs(RCD_LocalConfig.swap_list) do
                    local found = false
                    for _, ov in ipairs(RCD_Config.swap_list) do if ov == v then found = true end end
                    if not found then table.insert(RCD_Config.swap_list, v) end
                end
            end
            -- Clear local config after migration
            RCD_LocalConfig = nil
        end
    end
end)

SLASH_RCD1 = "/rcd"
SlashCmdList["RCD"] = function(msg)
    local cmd = msg:match("^(%S*)")
    cmd = cmd and cmd:lower() or ""
    if cmd == "start" then StartProcess()
    elseif cmd == "stop" then StopProcess()
    else Print("Use the RCD tab on the Guild Bank for settings.") end
end

Print("RCD v3.7 Loaded. Account-wide settings and ID resolution enabled!")
