-- Code largely generated via prompt engineering using a combination of Google Gemini and ChatGPT.
-- Generated Code and comments reviewed, debugged, and edited by Raptor2k1.
-- Last update: 8/4/2026
-- Description: Handles the configuration and SFX assignment UI for DecorSFX.

-- Fetch LibSharedMedia safely to handle our audio selection choices
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Create Global Namespace reference for UI windows
DecorSFXAddon.UI = {}

-- Initiate References to the main UI windows plus a cache of all available SharedMedia sound names.
local mainFrame = nil
local selectionPanel = nil
local mainScrollChild = nil 
local cachedSharedMediaSounds = {}

----------------------------------------------------------------------------------------------------
-- Build a cached list of every registered SharedMedia sound.
----------------------------------------------------------------------------------------------------
local function LoadSharedMediaCache()
    cachedSharedMediaSounds = {}
    local availableSounds = LSM and LSM:List("sound") or {}
    for _, soundName in ipairs(availableSounds) do
        table.insert(cachedSharedMediaSounds, soundName)
    end
    table.sort(cachedSharedMediaSounds)
end

----------------------------------------------------------------------------------------------------
-- Open SFX Selection Panel (with integrated live input filtering for SFX file name search)
----------------------------------------------------------------------------------------------------
local function RefreshSelectionDrawer(itemName, filterText)
    if not selectionPanel then return end
    
    selectionPanel.scrollChild:Hide()
    
    -- Clear any previous sound buttons/lines from the SFX selection panel
    for _, child in ipairs({selectionPanel.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Initiate variable to track how many entries passed the filter (for position/sizing of scroll area).
    local visibleCount = 0

    -- Create one button/line for each sound that matches the current search filter.
    for i = 1, #cachedSharedMediaSounds do
        local soundKey = cachedSharedMediaSounds[i]
        
        -- Apply a case-insensitive substring search when a filter is entered.
        local matchesFilter = true
        if filterText and filterText ~= "" then
            if not string.find(string.lower(soundKey), string.lower(filterText), 1, true) then
                matchesFilter = false
            end
        end
        
        -- Populate the SFX selection panel with each match
        if matchesFilter then
            visibleCount = visibleCount + 1
            
            local btn = CreateFrame("Button", nil, selectionPanel.scrollChild, "BackdropTemplate")
            btn:SetSize(220, 24)
            btn:SetPoint("TOPLEFT", selectionPanel.scrollChild, "TOPLEFT", 5, -(visibleCount - 1) * 26)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            btn:SetBackdropColor(0.12, 0.12, 0.12, 0.8)
            
            local btnText = btn:CreateFontString(nil, "OVERLAY")
            btnText:SetFontObject("GameFontHighlightSmall")
            btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
            btnText:SetText(soundKey)
            
            local high = btn:CreateTexture()
            high:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            high:SetBlendMode("ADD")
            high:SetAllPoints(btn)
            btn:SetHighlightTexture(high)
            
            btn:SetScript("OnClick", function()
                local activeDatabase = _G["DecorSFXDB"] or {}
                activeDatabase[itemName] = soundKey
                
                -- Truncate long sound names to avoid overlapping text issues.
                if selectionPanel.soundTextTarget then
                    local finalDisplayName = soundKey
                    if string.len(finalDisplayName) > 22 then
                        finalDisplayName = string.sub(finalDisplayName, 1, 19) .. "..."
                    end
                    selectionPanel.soundTextTarget:SetText(finalDisplayName)
                end
                
                -- Play selected SFX (to confirm audio is what was expected)
                -- Prefer the registered SharedMedia path, with a direct addon path as a fallback.
                local soundPath = LSM and LSM:Fetch("sound", soundKey)
                if soundPath then
                    PlaySoundFile(soundPath, "Master")
                else
                    PlaySoundFile("Interface\\AddOns\\SharedMedia_MyMedia\\sound\\" .. soundKey .. ".ogg", "Master")
                end
                
                -- Print the assignment update to the console
                print("|cFF00FF00[Decor SFX]|r Updated |cFF00FFFF" .. itemName .. "|r -> |cFFFFD100" .. soundKey .. "|r")
                selectionPanel:Hide()
            end)
        end
    end
    
    selectionPanel.scrollChild:SetSize(220, visibleCount * 26)
    selectionPanel.scrollBar:SetMinMaxValues(1, math.max(1, (visibleCount * 26) - 230))
    selectionPanel.scrollBar:SetValue(1)
    
    selectionPanel.scrollChild:Show()
end

-- Make the refresh function available so the search box can rebuild the list as text changes.
DecorSFXAddon.UI.RefreshSelectionDrawer = RefreshSelectionDrawer

local function OpenAudioSelectionPanel(itemName, soundTextComponent)
    if not selectionPanel then return end
    
    selectionPanel.TitleText:SetText("Assign SFX to: " .. itemName)
    selectionPanel.soundTextTarget = soundTextComponent 
    
    if selectionPanel.SearchBox then
        selectionPanel.SearchBox:SetText("")
        if selectionPanel.SearchBox.Instructions then
            selectionPanel.SearchBox.Instructions:SetAlpha(0.6)
        end
    end
    
    RefreshSelectionDrawer(itemName, "")
    selectionPanel:Show()
end

----------------------------------------------------------------------------------------------------
-- Rebuild list of tracked objects for main window
----------------------------------------------------------------------------------------------------
local function DrawActiveDatabaseRows()
    if not mainFrame or not mainScrollChild then return end
    
    for _, child in ipairs({mainScrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local activeDatabase = _G["DecorSFXDB"] or {}
    
    -- Copy the database keys into a sortable list so objects are always displayed alphabetically.
    local sortedItemNames = {}
    for itemName in pairs(activeDatabase) do
        table.insert(sortedItemNames, itemName)
    end
    table.sort(sortedItemNames) 

    local rowCount = 0
    for index = 1, #sortedItemNames do
        rowCount = rowCount + 1
        local itemName = sortedItemNames[index]
        local soundName = activeDatabase[itemName]
        
        -- Create one clickable row for each tracked object.
        local row = CreateFrame("Button", nil, mainScrollChild, "BackdropTemplate")
        row:SetSize(315, 32)
        row:SetPoint("TOPLEFT", mainScrollChild, "TOPLEFT", 5, -(rowCount - 1) * 36)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        
        -- Highlight the most recently captured object in green so that it's easy to find.
        if DecorSFXAddon.lastCapturedItem == itemName then
            row:SetBackdropColor(0.1, 0.25, 0.1, 0.95)   
            row:SetBackdropBorderColor(0.2, 1.0, 0.2, 1) 
        else
            row:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            row:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end

        -- Truncate long object names to avoid text overlap/overflow
        local finalItemName = itemName
        if string.len(finalItemName) > 24 then
            finalItemName = string.sub(finalItemName, 1, 21) .. "..."
        end

        local nameText = row:CreateFontString(nil, "OVERLAY")
        nameText:SetFontObject("GameFontNormal")
        nameText:SetPoint("LEFT", row, "LEFT", 12, 0)
        nameText:SetText(finalItemName)

        local soundText = row:CreateFontString(nil, "OVERLAY")
        soundText:SetFontObject("GameFontHighlightSmall")
        soundText:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        
        if soundName and soundName ~= "" then
            local finalDisplayName = soundName
            if string.len(finalDisplayName) > 22 then
                finalDisplayName = string.sub(finalDisplayName, 1, 19) .. "..."
            end
            soundText:SetText(finalDisplayName)
        else
            soundText:SetText("|cFF888888[None]|r")
        end

        local highlight = row:CreateTexture()
        highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints(row)
        row:SetHighlightTexture(highlight)

        -- Left-click to assign a sound, right-click to open mute/delete options menu.
        row:RegisterForClicks("RightButtonUp", "LeftButtonUp")
        row:SetScript("OnClick", function(_, button)

            -- Left click to open the SFX-assignment panel
            if button == "LeftButton" then
                if DecorSFXAddon.lastCapturedItem == itemName then
                    DecorSFXAddon.lastCapturedItem = nil
                    row:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
                    row:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                end
                if selectionPanel:IsShown() then selectionPanel:Hide() end
                OpenAudioSelectionPanel(itemName, soundText)
            
            -- Right-click actions menu for clearing or removing this object.
            elseif button == "RightButton" then
                MenuUtil.CreateContextMenu(row, function(owner, rootDescription)
                    rootDescription:CreateTitle("Manage: " .. itemName)
                    rootDescription:CreateButton("|cFFFF8888Clear Assigned Sound|r", function()
                        activeDatabase[itemName] = ""
                        soundText:SetText("|cFF888888[None]|r")
                        print("|cFF00FF00[Decor SFX]|r Cleared assigned sound track for: |cFF00FFFF" .. itemName .. "|r")
                    end)
                    
                    rootDescription:CreateButton("|cFFFF3333Delete This Object|r", function()
                        if DecorSFXAddon.lastCapturedItem == itemName then DecorSFXAddon.lastCapturedItem = nil end
                        
                        -- Close the selection panel if the object currently being edited is deleted.
                        if selectionPanel and selectionPanel:IsShown() and selectionPanel.TitleText then
                            local currentDrawerTitle = selectionPanel.TitleText:GetText() or ""
                            if string.find(currentDrawerTitle, itemName, 1, true) then
                                selectionPanel:Hide()
                            end
                        end
                        
                        activeDatabase[itemName] = nil
                        DrawActiveDatabaseRows()
                    end)
                end)
            end
        end)
    end
    
    local mainContentHeight = rowCount * 36
    mainScrollChild:SetSize(325, math.max(330, mainContentHeight))
    
    local mainMaxScroll = math.max(1, mainContentHeight - 310)
    mainFrame.scrollBar:SetMinMaxValues(1, mainMaxScroll)
    mainFrame.scrollBar:SetValue(1)
end

-- Helper used by other modules to refresh the main list when data changes.
DecorSFXAddon.UI.UpdateList = function()
    if mainFrame and mainFrame:IsShown() then DrawActiveDatabaseRows() end
end

----------------------------------------------------------------------------------------------------
-- Build UI Windows
----------------------------------------------------------------------------------------------------
local function BuildUIWindow()
    if mainFrame then return end

    -- Main Window Setup
    mainFrame = CreateFrame("Frame", "DecorSFXMainWindow", UIParent, "BackdropTemplate")
    mainFrame:SetSize(380, 450)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:Hide()
    
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })

    -- Main Window Labels
    mainFrame.TitleText = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.TitleText:SetFontObject("GameFontNormalLarge")
    mainFrame.TitleText:SetPoint("TOP", mainFrame, "TOP", 0, -16)
    mainFrame.TitleText:SetText("Decor SFX Home Directory")
    
    -- Main Window Controls
    mainFrame.SubtitleText = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.SubtitleText:SetFontObject("GameFontDisableSmall")
    mainFrame.SubtitleText:SetPoint("TOP", mainFrame, "TOP", 0, -36)
    mainFrame.SubtitleText:SetText("Left-Click to Assign SFX | Right-Click to Clear/Delete")

    -- Close button (top right corner 'X')
    mainFrame.CloseButton = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
    mainFrame.CloseButton:SetSize(26, 26)
    mainFrame.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -16, -16)
    mainFrame.CloseButton:SetFrameLevel(mainFrame:GetFrameLevel() + 10)
    mainFrame.CloseButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    mainFrame.CloseButton:SetBackdropColor(0.4, 0.1, 0.1, 0.8)
    mainFrame.CloseButton:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)

    local closeText = mainFrame.CloseButton:CreateFontString(nil, "OVERLAY")
    closeText:SetFontObject("GameFontNormal")
    closeText:SetPoint("CENTER", mainFrame.CloseButton, "CENTER", 1, 0)
    closeText:SetTextColor(1, 1, 1, 1)
    closeText:SetText("X")
    
    mainFrame.CloseButton:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.1, 0.1, 1) self:SetBackdropBorderColor(1, 0.3, 0.3, 1) end)
    mainFrame.CloseButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0.4, 0.1, 0.1, 0.8) self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) end)
    mainFrame.CloseButton:SetScript("OnClick", function() mainFrame:Hide() if selectionPanel then selectionPanel:Hide() end end)
    
    -- Main Object List.
    local mainScrollFrame = CreateFrame("ScrollFrame", nil, mainFrame)
    mainScrollFrame:SetSize(325, 330)
    mainScrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -55)
    
    mainScrollChild = CreateFrame("Frame", nil, mainScrollFrame)
    mainScrollChild:SetSize(325, 330)
    mainScrollChild:SetPoint("TOPLEFT", mainScrollFrame, "TOPLEFT", 0, 0)
    mainScrollFrame:SetScrollChild(mainScrollChild)
    
    -- Custom scrollbar for UI window.
    mainFrame.scrollBar = CreateFrame("Slider", nil, mainFrame, "BackdropTemplate")
    mainFrame.scrollBar:SetPoint("TOPLEFT", mainScrollFrame, "TOPRIGHT", 8, -6)
    mainFrame.scrollBar:SetPoint("BOTTOMLEFT", mainScrollFrame, "BOTTOMRIGHT", 8, 6)
    mainFrame.scrollBar:SetWidth(6)
    mainFrame.scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    mainFrame.scrollBar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)
    
    local mainThumb = mainFrame.scrollBar:CreateTexture()
    mainThumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    mainThumb:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    mainThumb:SetSize(6, 30)
    mainFrame.scrollBar:SetThumbTexture(mainThumb)
    mainFrame.scrollBar:SetScript("OnValueChanged", function(_, val) mainScrollFrame:SetVerticalScroll(val) end)
    
    mainScrollFrame:EnableMouseWheel(true)
    mainScrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local curr = mainFrame.scrollBar:GetValue()
        mainFrame.scrollBar:SetValue(curr - (delta * 18))
    end)

    -- SFX Assignment Panel.
    selectionPanel = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    selectionPanel:SetSize(260, 340)
    selectionPanel:SetPoint("LEFT", mainFrame, "RIGHT", -4, -15)
    selectionPanel:SetFrameStrata("DIALOG")
    selectionPanel:Hide()
    selectionPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    selectionPanel.TitleText = selectionPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectionPanel.TitleText:SetPoint("TOPLEFT", 14, -14)
    selectionPanel.TitleText:SetWidth(200)

    -- Close button for the SFX selection panel.
    selectionPanel.CloseButton = CreateFrame("Button", nil, selectionPanel, "BackdropTemplate")
    selectionPanel.CloseButton:SetSize(22, 22)
    selectionPanel.CloseButton:SetPoint("TOPRIGHT", selectionPanel, "TOPRIGHT", -12, -12)
    selectionPanel.CloseButton:SetFrameLevel(selectionPanel:GetFrameLevel() + 10)
    selectionPanel.CloseButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 14, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    selectionPanel.CloseButton:SetBackdropColor(0.4, 0.1, 0.1, 0.8)
    selectionPanel.CloseButton:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)

    local selCloseText = selectionPanel.CloseButton:CreateFontString(nil, "OVERLAY")
    selCloseText:SetFontObject("GameFontNormalSmall")
    selCloseText:SetPoint("CENTER", selectionPanel.CloseButton, "CENTER", 1, 0)
    selCloseText:SetTextColor(1, 1, 1, 1)
    selCloseText:SetText("X")
    
    selectionPanel.CloseButton:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.1, 0.1, 1) self:SetBackdropBorderColor(1, 0.3, 0.3, 1) end)
    selectionPanel.CloseButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0.4, 0.1, 0.1, 0.8) self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) end)
    selectionPanel.CloseButton:SetScript("OnClick", function() selectionPanel:Hide() end)

    -- SFX Search and Scrolling.
    selectionPanel.SearchBox = CreateFrame("EditBox", nil, selectionPanel, "SearchBoxTemplate")
    selectionPanel.SearchBox:SetSize(230, 20)
    selectionPanel.SearchBox:SetPoint("TOPLEFT", 14, -40)
    selectionPanel.SearchBox:SetAutoFocus(false)
    selectionPanel.SearchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            if self.Instructions then self.Instructions:SetAlpha(0) end
        else
            if self.Instructions then self.Instructions:SetAlpha(0.6) end
        end
        local currentItem = string.match(selectionPanel.TitleText:GetText(), "Assign SFX to: (.+)$")
        if currentItem and DecorSFXAddon.UI.RefreshSelectionDrawer then
            DecorSFXAddon.UI.RefreshSelectionDrawer(currentItem, text)
        end
    end)
    
    local sf = CreateFrame("ScrollFrame", nil, selectionPanel)
    sf:SetSize(220, 240)
    sf:SetPoint("TOPLEFT", 12, -70)
    
    selectionPanel.scrollChild = CreateFrame("Frame", nil, sf)
    selectionPanel.scrollChild:SetSize(220, 240)
    sf:SetScrollChild(selectionPanel.scrollChild)
    
    -- Scrollbar for SFX Selection Panel
    selectionPanel.scrollBar = CreateFrame("Slider", nil, selectionPanel, "BackdropTemplate")
    selectionPanel.scrollBar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 8, -6)
    selectionPanel.scrollBar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 8, 6)
    selectionPanel.scrollBar:SetWidth(6)
    selectionPanel.scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    selectionPanel.scrollBar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)
    
    local popThumb = selectionPanel.scrollBar:CreateTexture()
    popThumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    popThumb:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    popThumb:SetSize(6, 30)
    selectionPanel.scrollBar:SetThumbTexture(popThumb)
    selectionPanel.scrollBar:SetScript("OnValueChanged", function(_, val) sf:SetVerticalScroll(val) end)
    
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(_, delta)
        local curr = selectionPanel.scrollBar:GetValue()
        selectionPanel.scrollBar:SetValue(curr - (delta * 14))
    end)

    -- Object Capture Mode Controls
    mainFrame.AddButton = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
    mainFrame.AddButton:SetSize(160, 30)
    mainFrame.AddButton:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 18)
    mainFrame.AddButton:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
    mainFrame.AddButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    mainFrame.AddButton:SetBackdropColor(0.4, 0.1, 0.1, 0.8)
    mainFrame.AddButton:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)

    local addBtnText = mainFrame.AddButton:CreateFontString(nil, "OVERLAY")
    addBtnText:SetFontObject("GameFontHighlight")
    addBtnText:SetPoint("CENTER", mainFrame.AddButton, "CENTER", 0, 0)
    addBtnText:SetText("Add New Object")

    mainFrame.AddButton:SetScript("OnEnter", function(self) self:SetBackdropColor(0.7, 0.1, 0.1, 1) self:SetBackdropBorderColor(1, 0.3, 0.3, 1) end)
    mainFrame.AddButton:SetScript("OnLeave", function(self) self:SetBackdropColor(0.4, 0.1, 0.1, 0.8) self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1) end)
    
    -- Toggle capture mode. Tooltip scanner handles registering the next right-clicked object.
    mainFrame.AddButton:SetScript("OnClick", function(self)
        DecorSFXAddon.isCapturing = not DecorSFXAddon.isCapturing
        if DecorSFXAddon.isCapturing then
            print("|cFF00FF00[Decor SFX]|r Radar armed! Move your cursor over an item and simply |cFFFFD100Right-Click|r it to register.")
        else
            print("|cFF00FF00[Decor SFX]|r Capture mode canceled.")
        end
    end)

    mainFrame.AddButton:SetScript("OnUpdate", function(self)
        if DecorSFXAddon.isCapturing then
            if addBtnText:GetText() ~= "|cFFFFD100Scanning...|r" then addBtnText:SetText("|cFFFFD100Scanning...|r") end
        else
            if addBtnText:GetText() ~= "Add New Object" then addBtnText:SetText("Add New Object") end
        end
    end)
end

----------------------------------------------------------------------------------------------------
-- Initialize UI and cache available sounds at login
----------------------------------------------------------------------------------------------------
local initLoaderFrame = CreateFrame("Frame")
initLoaderFrame:RegisterEvent("PLAYER_LOGIN")
initLoaderFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        LoadSharedMediaCache()
        BuildUIWindow()
    end
end)

----------------------------------------------------------------------------------------------------
-- Display/hide main window
----------------------------------------------------------------------------------------------------
local function ToggleAddonUI()
    BuildUIWindow()
    if mainFrame:IsShown() then
        mainFrame:Hide()
        if selectionPanel then selectionPanel:Hide() end
    else
        mainFrame:Show()
        LoadSharedMediaCache()
        DrawActiveDatabaseRows()
    end
end
DecorSFXAddon.UI.Toggle = ToggleAddonUI

----------------------------------------------------------------------------------------------------
-- Register handlers for addon compartment button by the minimap
----------------------------------------------------------------------------------------------------
_G["DecorSFX_OnCompartmentClick"] = function()
    ToggleAddonUI()
end

_G["DecorSFX_OnCompartmentEnter"] = function(addonName, menuButton)
    GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFF00FF00Decor SFX|r")
    GameTooltip:AddLine("Click to open your custom player housing audio settings directory panel.", 1, 1, 1)
    GameTooltip:Show()
end

_G["DecorSFX_OnCompartmentLeave"] = function()
    GameTooltip:Hide()
end

----------------------------------------------------------------------------------------------------
-- Register console commands to toggle UI on/off
----------------------------------------------------------------------------------------------------
SLASH_DECORSFX1 = "/dsfx"
SLASH_DECORSFX2 = "/decorsfx"
SlashCmdList["DECORSFX"] = function() 
    ToggleAddonUI() 
end
