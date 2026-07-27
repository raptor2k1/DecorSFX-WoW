-- Establish the shared global framework namespace
DecorSFXAddon = {}

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "DecorSFX" then
        -- Initialize persistent storage if it doesn't exist
        if not DecorSFXDB then
            DecorSFXDB = {}
        end
        
        -- Seed your original items using their plain-text SharedMedia asset keys
        if not DecorSFXDB["Chaotic Void Maw"] then
            DecorSFXDB["Chaotic Void Maw"] = "ChronosphereSFX"
        end
        if not DecorSFXDB["Sticky Lever"] then
            DecorSFXDB["Sticky Lever"] = "ChronosphereStart"
        end
        
        -- LINK THE INTERFACE PATH: Expose the DB to our other files securely
        DecorSFXAddon.DB = DecorSFXDB
        
        print("|cFF00FF00[Decor SFX]|r Use /dsfx or /decorsfx to configure SFX assignments for interactive housing decor. Database manager loaded and initialized.")
    end
end)
