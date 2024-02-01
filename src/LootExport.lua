local ROLL_STATES = {
    [0] = "NeedMainSpec",
    [1] = "NeedOffSpec",
    [2] = "Transmog",
    [3] = "Greed",
    [4] = "NoRoll",
    [5] = "Pass"
}

local function ShowLootExportClipboard(text)
    if not LootExportClipboard then
        local f = CreateFrame("Frame", "LootExportClipboard", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER")
        f:SetSize(600, 500)

        f:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 3, right = 3, top = 5, bottom = 3 }
        })
        f:SetBackdropColor(0.1,0.1,0.1,0.5)
        f:SetBackdropBorderColor(0.4,0.4,0.4)

        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)

        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "LootExportClipboardScrollFrame", LootExportClipboard, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 8, 0)
        sf:SetPoint("RIGHT", -28, 0)
        sf:SetPoint("TOP", 0, -8)
        sf:SetPoint("BOTTOM", LootExportClipboardButton, "TOP", 0, 0)

        -- EditBox
        local eb = CreateFrame("EditBox", "LootExportClipboardEditBox", LootExportClipboardScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
    end

    if text then
        LootExportClipboardEditBox:SetText(text)
    end

    LootExportClipboard:Show()
    LootExportClipboardEditBox:HighlightText()
    LootExportClipboardEditBox:SetFocus()
end

local function ShowLootExport(all)
    local str = {}
    local warn = false

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
            table.insert(str, drop.itemHyperlink .. "\t" .. drop.itemHyperlink:gsub('\124','\124\124')) -- better way to print item info? wowhead link?
            for _, roll in ipairs(drop.rollInfos) do
                if roll.state == 4 then
                    warn = true
                else
                    local rollstr = ""
                    if (roll.roll) then
                        rollstr = " " .. tostring(roll.roll)
                    end

                    table.insert(str, "\t" .. roll.playerName .. " (" .. ROLL_STATES[roll.state] .. rollstr .. ")")
                end
            end
            table.insert(str, "\n")
        end

        if not all then break end
        table.insert(str, "\n")
    end

    if warn then table.insert(str, 1, "ROLL STILL IN PROGRESS\n\n") end
    ShowLootExportClipboard(table.concat(str))
end

SLASH_LOOTEXPORT1 = "/lootexport"
SLASH_LOOTEXPORT2 = "/le"
SlashCmdList.LOOTEXPORT = function(msg)
    ShowLootExport(msg == "all") -- use buttons for 1 vs all?
end