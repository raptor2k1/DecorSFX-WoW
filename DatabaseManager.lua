-- Code largely generated via prompt engineering using a combination of Google Gemini and ChatGPT.
-- Generated Code and comments reviewed, debugged, and edited by Raptor2k1.
-- Last update: 8/4/2026
-- Description: Boots up the backend DB for DecorSFX.

-- Establish the shared global framework namespace for the addon
DecorSFXAddon = {}

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "DecorSFX" then
        -- Initialize persistent SFX object storage if needed
        if not DecorSFXDB then
            DecorSFXDB = {}
        end
        
        -- Expose the SFX object DB to other files
        DecorSFXAddon.DB = DecorSFXDB
        
        -- Print instructions for console commands / how to open UI to the console
        print("|cFF00FF00[Decor SFX]|r Use /dsfx or /decorsfx to configure SFX assignments for interactive housing decor. Database manager loaded and initialized.")
    end
end)
