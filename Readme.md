# DecorSFX

**DecorSFX** is a lightweight "just-because-it's-fun" addon designed to spice up the soundscape of World of Warcraft player housing. Because of how it is built, it also works with any identifiable, interactive world-prop objects outside of housing (such as NPCs or mailboxes). It allows you to assign custom, immersive (or silly) sound effects to these world objects using your personal audio files. Google Gemini (and ChatGPT during editing/review) prompt-based engineering was heavily used to rapidly develop this addon. This started as a personal weekend project to make a way to play a couple, specific hard-coded sound effects and grew into something more scalable that I thought other folks might get some use out of too. 

### Key Features
* **One-Click Item Capture:** Click "Add New Object" and right-click any interactive prop to instantly add it to your soundboard directory list.
* **Simple UI Layout:** Type `/dsfx`, `/decorsfx`, or click the native Add-On Compartment icon near your minimap to toggle the management dashboard.
* **Easy Editing:** Left-click any tracked item row to open a scrollable, alphabetically sorted selector panel. Your most recent addition in the current session will be highlighted in green for easy tracking.
* **Zero Input Interruption:** Calibrated so camera mouse-look panning won't accidentally trigger your custom sound effects.
* **Basic Audio Spam Protection:** A brief cooldown safety net protects your ears from redundant, hardware double-clicking macro glitches (though if you rapidly trigger a dozen long audio files back-to-back, don't blame me if it gets loud!).

### ⚠️ Known Issues / Engine Limitations
Due to how the game engine handles scenery decoration objects, you may experience the following behavioral quirks:
* **Out-of-Range Triggers:** Sounds will trigger outside of standard interact range. The addon functions by scanning the tooltips of elements you are hovering over, irrespective of player distance. (No reliable engine method exists to calculate absolute player-to-housing-prop distance vectors).
* **Spam Clicking Audio Drop/Doubling:** Rapid clicking in succession may lead to successive sounds being omitted or a file playing multiple times on a single interact. A brief delay is built-in to prevent audio stacking from getting too severe, and you can adjust this cooldown interval at the bottom of `InteractionPlayer.lua`.
* **Decor is More Like a... Guideline:** Since WoW cannot track interactive scenery props the way it tracks NPCs, this addon relies entirely on world-hover tooltip strings. Consequently, it will also play sounds for anything with a right-click tooltip interaction (NPCs, nodes, mailboxes, etc.). While built specifically to make housing levers and gears make fun noises, you can technically use it on anything identifiable. If you really wanted to, you could even theoretically do something super mature, like assign fart noises to play when right-clicking your friends, though that might make click-cast raid healing interesting. (If you ever discover an API method to isolate *just* housing decor objects within melee interact range, I'm open to suggestions!).
* **Does not work when UI is Hidden:** If you hide the UI (like if you're hiding it to take screenshots, etc.), it won't play SFX, since this addon relies on reading visible tooltips to work.  

### 🛠️ How to Setup Custom Audio Files
This addon includes third-party libraries:
- CallbackHandler-1.0 (BSD 3-Clause License)
- LibStub (MIT License)
- LibSharedMedia-3.0 (LGPL v2.1)  
DecorSFX uses the **LibSharedMedia** addon framework to read your audio tracks. If you have any audio SFX files registered to LibSharedMedia through any other addons, they should show up as options in DecorSFX.  
**WARNING:** If you do not install a SharedMedia audio pack or generate your own using SharedMedia's batch script, your SFX selection list will be **empty**.

* **Custom SFX - HIGHLY RECOMMENDED:** Install the standalone **SharedMedia** addon. This way you can run the addon's `MyMedia.bat` script to add any custom sound effects you want to add to your game. If you have any SFX that you want to add that aren't in .ogg format, I'd recommend using a free program like Audacity to export your desired sound clips as an .ogg format copy, so they can be used in-game. Once you have some .ogg files you'd like to add, go through the following steps.  

1. Navigate to your game files directory at: `_retail_\Interface\AddOns\SharedMedia_MyMedia\sound\`
2. Drop your custom `.ogg` format sound files directly inside that folder.
3. Double-click the **`MyMedia.bat`** compiler script inside the parent `SharedMedia_MyMedia` folder to register your new sounds.
4. **Completely close and restart World of Warcraft** (the game client cannot discover new physical file assets on a simple `/reload`).
5. Log in, open the menu via DecorSFX slash commands or the minimap compartment, add an object, and select your custom sound file straight out of the selection list!
