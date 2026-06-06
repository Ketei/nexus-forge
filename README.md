<div align="center">
  <img alt="Logo" src="/logo.svg" width="300"/>
  <h1 align="center"> Nexus Forge </h1>
  <p>A headless modular toolset plugin for Godot</p>
</div>

<div align="center">
  <a href="https://godotengine.org/download/" target="_blank" style="text-decoration:none"><img alt="Godot Badge" src="https://img.shields.io/badge/Godot-4.4+-478CBF?logo=godotengine&logoColor=white"/></a>
  <img alt="GDScript Badge" src="https://img.shields.io/badge/Language-GDScript-blue"/>
  <img alt="Alpha Status Badge" src="https://img.shields.io/badge/Status-Alpha-red"/>
  <img alt="MIT License Badge" src="https://img.shields.io/badge/License-MIT-green"/>
</div>

> [!IMPORTANT]
> **Alpha State:** The plugin is functional, but APIs, class names and GUI layouts will likely undergo breaking changes before the Beta release. Use this for testing, evaluation, or as a bold choice for an early-stage project. Expect bugs.
> 
> This began as a personal tool, so it includes a few specific static helper classes tailored for my own workflow.

> [!WARNING]
> **No Undo/Redo yet:** Nexus Forge does not currently implement an Undo/Redo system. Actions taken in the editor cannot be reversed via `Ctrl+Z`.

## Contents

- [About](#about)
- [Installation](#installation)
  - [Compatibilty](#compatibility)
  - [Reserved Classes](#reserved-classes)
  - [Installation Steps](#installation-steps)
- [Features](#features)
  - [Utility Classes](#static-utility-classes)
- [Documentation](#documentation)
- [Roadmap](#roadmap)

## About
**Nexus Forge** is a headless game data manager for Godot 4.4+. It provides visual editors for managing your game's data, dialogue, stats, items and quests without forcing any specific UI on your project.

**Nexus Forge editor component is modular.** Through Godot's Project Settings you can selectively enable or disable individual modules. The plugin will only load the specific tools you need, keeping the editor clutter-free.

## Installation
### Compatibility

* **Engine:** Godot Engine 4.4+
* **Resolution:** The editor GUI is designed for a 1920x1080 resolution. Smaller resolutions are supported but will trigger scrollbars.

### Reserved Classes
Nexus Forge makes use of [several class names](https://github.com/Ketei/nexus-forge/wiki#reserved-class-names). Make sure you have them available before installing.

### Installation Steps
1. Download the [latest build](https://github.com/Ketei/nexus-forge/releases/latest) or the a copy of the [main branch](https://github.com/Ketei/nexus-forge/archive/refs/heads/main.zip).
2. Extract the zip file and extract the `addons/nexus_forge` folder to your project's `res://addons` directory.
3. Go to `Project` → `Project Settings` → `Plugins` and enable NexusForge
4. **(Optional)** Go to `Project` → `Project Settings` → `General` and in the Nexus Forge category configure the plugin. For more information go to the [Config Section](https://github.com/Ketei/nexus-forge/wiki/00.-Configuration) of the wiki.
5. Restart Godot/Reload your project to ensure the plugin is working correctly

## Features

Nexus Forge provides editors to structure your game's content:

* **Dialogue Editor:** A powerful easy-to-use graph-based visual tool for creating dialogs.
* **Global State:** A blackboard for global data storage and access.
* **Character & Species Data:** Complex character sheets with custom stats, skills and traits. Plus a robust Species/Sub-Species inheritance system.
* **Items & Crafting:** Define items with custom categories, flags and rarities. Define complex crafting recipes.
* **Quests:** Construct quests with multiple stages and objectives.
* **Economy:** Build single or multi-currency economies.

<img alt="Dialog Example" src="https://github.com/user-attachments/assets/d92ba731-fc55-44cf-9995-b187f7f8d932" />
<img alt="Quest Example" src="https://github.com/user-attachments/assets/6d3d3022-3b87-4a28-905b-6e0e7306ded2" />


### Static Utility Classes

Besides the editors, the plugin includes several objects that can be used independently in your code:

* **Caching:** A Least Recently Used (LRU) Cache implementation.
* **Data Pools and Selectors:** A Random Weighted Pool for random or weighted draws.
* **Other Helpers:** BitFlags, UUID (v4) generation and bitwise operations.

## Documentation

* **Built-in (F1):** All custom classes include manually written documentation accessible directly inside the Godot editor's F1 help menu.
* **GitHub Wiki:** Setup instructions and guides are available on the [Wiki](https://github.com/Ketei/nexus-forge/wiki). 
*(Note: The wiki was initially AI-assisted but manually reviewed. A full rewrite is planned for the Beta release once the API stabilizes).*

## Roadmap
Features that are planned to be implemented in the future:
### Alpha:
- [x] **Core:** Skip instantiating singleton modules based on editor modules enabled
- [x] **Discourse:** Use your own scene to test dialogs
- [x] **Depot(Items):** Allow for name & description to be formatted using Blackboard's variables on settings.
- [x] **Odyssey(Quests):** Allow for title & description to be formatted using Blackboard's variables on settings.
- [x] **Kindred(Species):** Hybridization system.
- [ ] **Core:** Fix all the critical bugs and stabilize the API, making the plugin usable on projects.
- [ ] Release Beta.


### Beta & Beyond
- [ ] **On Release:** Publish on Godot's Asset Library/Asset Store
- [ ] **Core:** UndoRedo for all modules
  - [ ] Discourse (Dialogs)
  - [ ] Blackboard (Variables)
  - [ ] Persona (Characters)
  - [ ] Kindred (Species)
  - [ ] Talents (Skills & Traits)
  - [ ] Depot (Items & Currencies)
  - [ ] Blueprints (Recipes)
  - [ ] Odyssey (Quests)
  - [ ] Phrase Maps
- [ ] **Core:** Implement an automatic [mod loader](#modding)
- [ ] **Discourse:** Import/Export CSV files for localization
- [ ] **Github Wiki:** Rewrite the Wiki and include examples using screenshots/gifs
- [ ] **GUI:** Improved GUI for smaller resolutions

_And more! ... maybe_

#### Modding
All core data APIs are exposed at runtime, allowing developers to easily implement modding. A mod loader would automatically scan a defined directory and apply all changes from mods.
