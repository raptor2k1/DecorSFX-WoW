-- THE HANDSHAKE FIX: Guarantee the global namespace exists in memory before using it
if not DecorSFXAddon then
    DecorSFXAddon = {}
end

-- Fetch LibSharedMedia safely from the addon registry
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- Continuous focus state tracker
local currentHoveredItemName = nil

-- PER-SOUND ANTI-SPAM CLOCK
local audioCooldowns = {}

-- 1. SAFE TOOLTIP SCANNER
local lastTooltipText = nil

local function UpdateHoveredItem()
    local tooltipTextFrame = _G["GameTooltipTextLeft1"]

    if not tooltipTextFrame then
        currentHoveredItemName = nil
        return
    end

    local success, itemName = pcall(function()
        return tooltipTextFrame:GetText()
    end)

    if not success or not itemName then
        currentHoveredItemName = nil
        return
    end

    -- Secret strings can pass type() but cannot be inspected.
    -- Attempt to make a safe copy/validation.
    local safe, length = pcall(function()
        return string.len(itemName)
    end)

    if safe and length > 0 then
        currentHoveredItemName = itemName
    else
        currentHoveredItemName = nil
    end
end


GameTooltip:HookScript("OnUpdate", function(self)
    UpdateHoveredItem()
end)

GameTooltip:HookScript("OnHide", function()
    currentHoveredItemName = nil
end)

-- 2. DYNAMIC ONE-CLICK CAPTURE ENGINE WITH COOLDOWN GATEKEEPING
local clickStartTime = 0
WorldFrame:HookScript("OnMouseDown", function(_, button)
    if button == "RightButton" then
        clickStartTime = GetTime()
    end
end)

WorldFrame:HookScript("OnMouseUp", function(_, button)
    if button == "RightButton" then
        local holdDuration = GetTime() - clickStartTime
        
        -- Use your calibrated 0.15s interaction threshold
        if holdDuration <= 0.15 then
            local activeDatabase = _G["DecorSFXDB"] or {}
            
            -- STATE A: CAPTURE MODE ACTIVATED
            if DecorSFXAddon.isCapturing then
                if currentHoveredItemName then
                    if not activeDatabase[currentHoveredItemName] then
                        activeDatabase[currentHoveredItemName] = "" 
                    end
                    
                    print("|cFF00FF00[Decor SFX]|r Successfully captured new target: |cFF00FFFF" .. currentHoveredItemName .. "|r")
                    PlaySound(840, "Master") 
                    
                    -- THE SECURE HOOK: Save the name safely into our verified global tracker slot
                    DecorSFXAddon.lastCapturedItem = currentHoveredItemName
                    
                    DecorSFXAddon.isCapturing = false
                    
                    if DecorSFXAddon.UI and DecorSFXAddon.UI.UpdateList then
                        DecorSFXAddon.UI.UpdateList()
                    end
                end
                
            -- STATE B: PASSIVE AUDIO PLAYBACK MODE (Per-Sound Cooldown Gated)
            else
                if type(currentHoveredItemName) == "string" and activeDatabase[currentHoveredItemName] then
                    local savedSoundName = activeDatabase[currentHoveredItemName]
                    
                    if savedSoundName ~= "" then
                        local currentTime = GetTime()
                        
                        -- Get this specific item's cooldown expiration time.
                        -- If it has never played before, default to 0.
                        local cooldownExpiration = audioCooldowns[currentHoveredItemName] or 0
                        
                        -- Only block this specific item's sound.
                        if currentTime >= cooldownExpiration then
                            local soundPath = LSM and LSM:Fetch("sound", savedSoundName)
                            
                            if soundPath then
                                PlaySoundFile(soundPath, "Master")
                            else
                                PlaySoundFile(
                                    "Interface\\AddOns\\SharedMedia_MyMedia\\sound\\" ..
                                    savedSoundName .. ".ogg",
                                    "Master"
                                )
                            end
                            
                            -- Start a separate 2.5-second cooldown for this item.
                            audioCooldowns[currentHoveredItemName] = currentTime + 2.5
                        end
                    end
                end
            end
        end
    end
end)
