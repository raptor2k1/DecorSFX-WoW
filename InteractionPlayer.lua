-- Code largely generated via prompt engineering using a combination of Google Gemini and ChatGPT.
-- Generated Code and comments reviewed, debugged, and edited by Raptor2k1.
-- Last update: 8/4/2026
-- Description: Handles player right click interactions for DecorSFX by using tooltip queries.

-- Initiate the addon namespace if it doesn't exist yet
if not DecorSFXAddon then
    DecorSFXAddon = {}
end

-- Fetch LibSharedMedia from the addon registry
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Initiate variable to track the current focus object
local currentHoveredItemName = nil

-- Initiate object to store item SFX cooldowns for associated objects
local audioCooldowns = {}

----------------------------------------------------------------
-- Tooltip Scanner
----------------------------------------------------------------

-- Update focus item based on current object tooltip
local function UpdateHoveredItem()
    local tooltipTextFrame = _G["GameTooltipTextLeft1"]

    -- Handle no tooltip frame (such as when UI is hidden)
    if not tooltipTextFrame then
        currentHoveredItemName = nil
        return
    end

    -- Return the tooltip text of the current hovered object
    local success, itemName = pcall(function()
        return tooltipTextFrame:GetText()
    end)

    -- Handle null case
    if not success or not itemName then
        currentHoveredItemName = nil
        return
    end
 
    -- Update the hovered item name as long as it's safe / not secret
    local safe, length = pcall(function()
        return string.len(itemName)
    end)

    if safe and length > 0 then
        currentHoveredItemName = itemName
    else
        currentHoveredItemName = nil
    end
end

-- Refresh the current target tooltip on every update (if possible)
GameTooltip:HookScript("OnUpdate", function(self)
    UpdateHoveredItem()
end)

GameTooltip:HookScript("OnHide", function()
    currentHoveredItemName = nil
end)

----------------------------------------------------------------
-- Click Functions and SFX Playback Cooldown Management
----------------------------------------------------------------

-- Reset the SFX activation click cooldown timer
local clickStartTime = 0

-- Right click press - snapshot current time for cooldown tracking reference
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if button == "RightButton" then
        clickStartTime = GetTime()
    end
end)

-- Right click release - execute core functions (playing SFX / storing object to play list of objects)
WorldFrame:HookScript("OnMouseUp", function(_, button)
    if button == "RightButton" then

        -- Offset time to factor in how long right click was held down
        local holdDuration = GetTime() - clickStartTime
        
        -- Capture object to play list or play SFX if click is quick (i.e. not held / mouse look)
        if holdDuration <= 0.15 then
            local activeDatabase = _G["DecorSFXDB"] or {}
            
            -- STATE A: CAPTURE MODE (Capture/Store Object to list so a SFX can be assigned in the UI)
            if DecorSFXAddon.isCapturing then
                if currentHoveredItemName then
                    if not activeDatabase[currentHoveredItemName] then
                        activeDatabase[currentHoveredItemName] = "" 
                    end
                    
                    print("|cFF00FF00[Decor SFX]|r Successfully captured new target: |cFF00FFFF" .. currentHoveredItemName .. "|r")
                    PlaySound(840, "Master") 
                    
                    -- Save the name safely into global tracker slot
                    DecorSFXAddon.lastCapturedItem = currentHoveredItemName
                    
                    -- Clear the capture mode state once done
                    DecorSFXAddon.isCapturing = false
                    
                    -- Update the list with captured results, if possible
                    if DecorSFXAddon.UI and DecorSFXAddon.UI.UpdateList then
                        DecorSFXAddon.UI.UpdateList()
                    end
                end
                
            -- STATE B: SFX PLAYBACK
            else
                -- Play SFX if there's a match for the item in the stored object database
                if type(currentHoveredItemName) == "string" and activeDatabase[currentHoveredItemName] then
                    local savedSoundName = activeDatabase[currentHoveredItemName]
                    
                    if savedSoundName ~= "" then
                        local currentTime = GetTime()
                        
                        -- Get this specific item's cooldown expiration time, default to 0 if never played.
                        local cooldownExpiration = audioCooldowns[currentHoveredItemName] or 0
                        
                        -- Block this specific item's sound if it was played too recently
                        if currentTime >= cooldownExpiration then
                            local soundPath = LSM and LSM:Fetch("sound", savedSoundName)
                            
                            -- Validate and play the SFX
                            if soundPath then
                                PlaySoundFile(soundPath, "Master")
                            else
                                PlaySoundFile(
                                    "Interface\\AddOns\\SharedMedia_MyMedia\\sound\\" ..
                                    savedSoundName .. ".ogg",
                                    "Master"
                                )
                            end
                            
                            -- Start a 2.5-second cooldown for the played item.
                            audioCooldowns[currentHoveredItemName] = currentTime + 2.5
                        end
                    end
                end
            end
        end
    end
end)
