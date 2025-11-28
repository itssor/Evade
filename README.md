# Evade.GG

![Version](https://img.shields.io/badge/version-1.8-blue) ![Status](https://img.shields.io/badge/status-working-green) ![Lua](https://img.shields.io/badge/language-Luau-orange)

**Evade** is a modular, high-performance script execution environment for Roblox. It utilizes a centralized loader to detect the active Place ID and inject optimized game-specific modules on runtime. Built on the Obsidian UI framework.

## Installation

Execute the following script in your executor (Solara, Wave, Synapse Z, etc.):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/itssor/Evade/refs/heads/main/Evade.GG.luau"))()
```

**Default Keybind:** `RightShift`

---

## 🎮 Supported Modules

The loader automatically detects the game. If the game is not supported, it defaults to the **Universal** module.

### 🌐 Universal (Fallback)
*   **Combat:** Silent/Camera/Mouse Aimbot, FOV Circle, Sticky Aim.
*   **Visuals:** Sense ESP (Box, Name, Health, Tracers).
*   **Movement:** LinearVelocity Flight, CFrame Speed, Noclip, Infinite Jump.

### 🔫 Combat Games
*   **Arsenal:** Visuals-safe Hitbox Expander, No Recoil, Rapid Fire, Rainbow Gun.
*   **The Strongest Battlegrounds:** Auto-Block (Animation Reading), No Ragdoll, Speed, Player ESP.
*   **Blade Ball:** Auto-Parry (Velocity/Distance Calculation), Spam Mode, Ball ESP.

### 👁️ Horror Games
*   **Doors:** Entity Prediction, Door/Item/Key ESP, Speed Bypass, Auto-Interact.
*   **Pressure:** Entity Radar (Angler/Pandemonium), Locker ESP, Keycard ESP, No Blindness.

### 🔪 Strategy & Mystery
*   **Murder Mystery 2:** Role ESP (Inventory Scan), Kill All (Teleport), Auto-Gun.
*   **Five Nights TD:** Smart Macro (Record/Replay), Priority Placement System, Auto-Rejoin.

---

## Credits
*   **UI:** Obsidian (Deividcomsono fork)
*   **ESP:** Sense (Sirius)
*   **Core Logic:** Itssor
