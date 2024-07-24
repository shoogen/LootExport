local ROLL_STATES = {
    [0] = "NeedMainSpec",
    [1] = "NeedOffSpec",
    [2] = "Transmog",
    [3] = "Greed",
    [4] = "NoRoll",
    [5] = "Pass"
}

local addon = {}
local mode_all = false
local mode_format = "spreadsheet"

function addon:BuildLootString(all, format)
    local str = {}
    local warn = false
    local delimiter = "\t"
    local link = true

    if format == "chat" then
        delimiter = " "
        link = false
    end

    local encounters = C_LootHistory.GetAllEncounterInfos()
    --DevTools_Dump(encounters)

    for _, encounter in ipairs(encounters) do
        local _, _, _, difficulty = GetInstanceInfo()
        local stamp = date("%b %d %H:%M", time() - GetTime() + (encounter.startTime / 1000))
        local boss = encounter.encounterName .. " - " .. (difficulty or "?") .. " (" .. stamp .. ")\n"
        table.insert(str, boss)

        local drops = C_LootHistory.GetSortedDropsForEncounter(encounter.encounterID)
        --DevTools_Dump(drops)

        for _, drop in ipairs(drops) do
            table.insert(str, drop.itemHyperlink)
            if link then
                table.insert(str, delimiter .. drop.itemHyperlink:gsub('\124','\124\124')) -- better way to print item info? wowhead link?
            end
            for _, roll in ipairs(drop.rollInfos) do
                if roll.state == 4 then
                    warn = true
                else
                    local rollstr = ""
                    if roll.roll then
                        rollstr = " " .. tostring(roll.roll)
                    end

                    table.insert(str, delimiter .. roll.playerName .. " (" .. ROLL_STATES[roll.state] .. rollstr .. ")")
                end
            end
            table.insert(str, "\n")
        end

        if not all then break end
        table.insert(str, "\n")
    end

    return table.concat(str), warn
end

function addon:ShowLootExportClipboard(text, warn)
    if not LootExportClipboard then
        local f = CreateFrame("Frame", "LootExportClipboard", UIParent, "PortraitFrameTemplate")
        f:SetPoint("CENTER")
        f:SetSize(600, 500)

        f:SetTitle("Loot Export")
        f:SetPortraitToAsset("Interface\\Icons\\inv_misc_coin_17")

        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)

        f.TitleContainer:EnableMouse(true)
        f.TitleContainer:SetScript("OnMouseDown", function() f:StartMoving() end)
        f.TitleContainer:SetScript("OnMouseUp", function()
            f:StopMovingOrSizing()
        end)

        -- Resizable
        f:SetResizable(true)
        f:SetResizeBounds(300, 200, 2000, 2000)

        f.resizeButton = CreateFrame("Button", nil, f)
        f.resizeButton:SetPoint("BOTTOMRIGHT", -6, 7)
        f.resizeButton:SetSize(16, 16)
        f.resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        f.resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        f.resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        f.resizeButton:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
        f.resizeButton:SetScript("OnMouseUp", function()
            f:StopMovingOrSizing()
        end)

        -- Context Menu
        f.menu = CreateFrame("Frame", nil, f, "UIDropDownMenuTemplate")

        -- Header Text
        f.header = f:CreateFontString(nil, "OVERLAY", "GameTooltipText")
        f.header:SetPoint("LEFT", f, "TOPLEFT", 60, -38)

        -- Buttons
        f.bossButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.bossButton:SetSize(80, 22)
        f.bossButton:SetText("Bosses")
        f.bossButton:SetPoint("RIGHT", f, "TOPRIGHT", -96, -38)
        f.bossButton:SetScript("OnClick", function()
            UIDropDownMenu_Initialize(f.menu, function(frame, level, menuList)
                UIDropDownMenu_AddButton({ text = "Last Boss", arg1 = false, func = addon.ModeBoss })
                UIDropDownMenu_AddButton({ text = "All Bosses", arg1 = true, func = addon.ModeBoss })
            end, "MENU")
            ToggleDropDownMenu(1, nil, f.menu, f.bossButton, 0, 0)
        end)

        f.formatButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.formatButton:SetSize(80, 22)
        f.formatButton:SetText("Format")
        f.formatButton:SetPoint("RIGHT", f, "TOPRIGHT", -8, -38)
        f.formatButton:SetScript("OnClick", function()
            UIDropDownMenu_Initialize(f.menu, function(frame, level, menuList)
                UIDropDownMenu_AddButton({ text = "Spreadsheet", arg1 = "spreadsheet", func = addon.ModeFormat })
                UIDropDownMenu_AddButton({ text = "Discord", arg1 = "chat", func = addon.ModeFormat })
            end, "MENU")
            ToggleDropDownMenu(1, nil, f.menu, f.formatButton, 0, 0)
        end)

        -- Scroll Frame
        f.scrollFrame = CreateFrame("ScrollFrame", nil, f, "ScrollFrameTemplate")
        f.scrollFrame:SetPoint("TOPLEFT", 16, -60)
        f.scrollFrame:SetPoint("BOTTOMRIGHT", -27, 24)

        -- EditBox
        local eb = CreateFrame("EditBox", "LootExportClipboardEditBox", f)
        eb:SetWidth(f.scrollFrame:GetWidth())
        eb:SetMultiLine(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        f.scrollFrame:SetScrollChild(eb)
        f.scrollFrame:SetScript("OnSizeChanged", function()
            eb:SetWidth(f.scrollFrame:GetWidth())
        end)
    end

    if text then
        LootExportClipboardEditBox:SetText(text)
    end

    if warn then
        LootExportClipboard.header:SetText("WARNING: ROLL STILL IN PROGRESS")
    else
        LootExportClipboard.header:SetText("")
    end

    LootExportClipboard:Show()
    LootExportClipboardEditBox:HighlightText()
    LootExportClipboardEditBox:SetFocus()
end

function addon:ModeBoss(all)
    mode_all = all
    addon:ShowLootExport()
end

function addon:ModeFormat(format)
    mode_format = format
    addon:ShowLootExport()
end

function addon:ShowLootExport()
    local text, warn = addon:BuildLootString(mode_all, mode_format)
    addon:ShowLootExportClipboard(text, warn)
end

SLASH_LOOTEXPORT1 = "/lootexport"
SLASH_LOOTEXPORT2 = "/le"
SlashCmdList.LOOTEXPORT = function(msg)
    addon:ShowLootExport() -- use buttons for 1 vs all?
end