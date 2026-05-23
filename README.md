<div align="center">
  <img alt="Logo" src="https://github.com/Ketei/nexus_forge/blob/main/logo.svg" width="300"/>
  <h1 align="center"> Nexus Forge </h1>
  <p>A game toolset plugin for Godot</p>
</div>

**Nexus Forge** is a data-driven, headless game data manager for Godot 4.4+. Built entirely in GDScript, it provides node-based visual editors for managing your game's core data—dialogue, stats, items, and quests—without forcing any specific UI on your project. You build the front-end; Nexus Forge handles the backend.

**Nexus Forge editor component is modular** and through Godot's Project Settings you can selectively enable or disable individual modules. The plugin will only load the specific tools you need, keeping the editor free of clutter.

> [!IMPORTANT]
> **Alpha State:** The plugin is functional, but APIs, class names, and GUI layouts will likely undergo breaking changes before the Beta release. Use this for testing, evaluation, or as a bold choice for an early-stage project. Bugs are expected.
> 
> *Context: This began as an internal studio tool, so it includes a few specific static helper classes tailored for my personal workflow.*


> [!WARNING]
> **No Undo/Redo yet:** Nexus Forge does not currently implement an Undo/Redo system. Actions taken in the editor cannot be reversed via `Ctrl+Z`.

## Core Systems

Nexus Forge provides dedicated editors to structure your game's content:

* **Dialogue Editor:** A GraphEdit-based tool for branching conversations featuring context-aware string formatting.
* **Global State:** A blackboard for data storage and managing global variables.
* **Character & Species Data:** Complex character sheets with custom stats, skills, and traits. Includes a robust Species/Sub-species inheritance system.
* **Items & Economy:** Define items with custom categories, flags, and rarities. Build single or multi-currency economies.
* **Crafting & Quests:** Construct multi-stage quests and define complex crafting recipes.

<img alt="Dialog Example" src="https://github.com/user-attachments/assets/c7198887-cb6c-4981-9123-75b088626780" />
<img alt="Quest Example" src="https://github.com/user-attachments/assets/17ec2fc0-06ea-4515-8a8a-f9bffedbf5fa" />




## Standalone Utility Classes

Beyond the visual editors, the plugin includes several computer science data structures that can be used independently in your code:

* **Caching:** A Least Recently Used (LRU) Cache implementation.
* **Advanced Data Structures:** A Random Weighted Pool for probability and BitFlags for efficient boolean states.
* **Low-Level Helpers:** Fast UUID (v4) generation and bitwise operations.

## Compatibility

* **Engine:** Godot Engine 4.4+ (Strictly required due to reliance on Typed Dictionaries).
* **Resolution:** The editor GUI is optimized for 1920x1080. Smaller resolutions are supported but will trigger scrollbars.

## Documentation

* **Built-in (F1):** All custom classes include manually written documentation accessible directly inside the Godot editor's F1 help menu.
* **GitHub Wiki:** Setup instructions and guides are available on the [Wiki](https://github.com/Ketei/nexus-forge/wiki). 
*(Note: The wiki was initially AI-assisted but manually reviewed. A full rewrite is planned for the Beta release once the API stabilizes).*

## Roadmap
Features that are planned to be implemented in the future:
### Alpha:
- [ ] **Core:** Skip instantiating singleton modules based on editor modules enabled
- [x] **Discourse:** Use your own scene to test dialogs
- [ ] **Depot(Items):** Allow for name & description to be formatted using Blackboard's variables on settings.
- [ ] **Odyssey(Quests):** Allow for title & description to be formatted using Blackboard's variables on settings.
- [ ] Publish on Godot's Asset Library/Asset Store

### Beta & Beyond
- [ ] **Core:** UndoRedo for all modules
- [ ] **Discourse:** Import/Export CSV files for localization
- [ ] Github Wiki: Rewrite the Wiki and include examples using screenshots/gifs

_And maybe more!_
