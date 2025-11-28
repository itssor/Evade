# Evade.GG

![Version](https://img.shields.io/badge/version-1.5-blue) ![Status](https://img.shields.io/badge/status-working-green) ![Lua](https://img.shields.io/badge/language-Luau-orange)

**Evade** is a modular, high-performance script execution environment for Roblox. It utilizes a centralized loader to detect the active Place ID and inject optimized game-specific modules on runtime. Built on the Obsidian UI framework.

## Installation

Execute the following script in your executor (Solara, Wave, Synapse Z, etc.):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/milkisbetter/Evade/refs/heads/main/Evade.GG.luau"))()
```

**Default Keybind:** `RightShift`

---

## Supported Modules

The loader automatically detects the game. If the game is not supported, it defaults to the **Universal** module.

### 🌐 Universal (Fallback)
*   **Combat:** Silent/Camera/Mouse Aimbot, FOV Circle, Sticky Aim.
*   **Visuals:** Sense ESP (Box, Name, Health, Tracers).
*   **Movement:** LinearVelocity Flight, CFrame Speed, Noclip, Infinite Jump.

### 🔫 Arsenal
*   **Hitbox Manipulation:** Visuals-safe expansion (HeadHB).
*   **Weapon Mods:** No Recoil, No Spread, Rapid Fire, Infinite Ammo.
*   **Visuals:** Rainbow Gun Chams.

### 🔪 Murder Mystery 2
*   **Role ESP:** Detects Murderer/Sheriff via inventory scanning.
*   **Rage:** "Kill All" loop (Teleport behind + Stab).
*   **Farming:** Auto-Gun Grabber, Coin ESP.

### 🛡️ Five Nights TD
*   **Macro Engine:** Record and replay unit placements.
*   **Priority System:** Sort placement order (1-6) for optimal farming.
*   **Auto-Rejoin:** Automatically re-executes script upon match teleport.

---

## Credits
*   **UI:** Obsidian (Deividcomsono fork)
*   **ESP:** Sense (Sirius)
*   **Core Logic:** MilkIsBetter
