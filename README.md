# 🛠️ Nexus Forge - The Comprehensive Godot Data Forge


**Nexus Forge** is a powerful, open-source **Godot Engine plugin** designed to handle the foundational data architecture for your game. Built entirely in **GDScript**, it provides a suite of visual editor tools for managing everything from complex dialogue to player stats, without enforcing any specific UI, giving you maximum creative freedom.

## ⚠️ Alpha Stage Warning
> [!IMPORTANT]
> This plugin is currently in the **Alpha stage**. While the tools are functional the **Graphical User Interface (GUI)** and internal API definitions (class names, function names) may change significantly before the Beta release.
> **Use of this plugin is recommended for testing, evaluation, or as a VERY bold choice for current projects.** It is not yet considered reliable for production projects, expect bugs.

## Core Features and Tools

Nexus Forge is a data-centric plugin that gives you structured control over your game's content:

* **Dialogue Editor:** Create branching, localized conversations using a visual **GraphEdit** interface. Supports variable and method substitution (e.g., `{$player/name}`), and complex logic using nodes like Random Dialog and Event nodes.
* **Global State Management:** Easily store and manage global variables. Organize data into folders and variables, with support for all Godot data types in code.
* **Character and Entity Design:** Dedicated tools for defining **Characters** and managing **Species/Subspecies**. Customize character sheets with user-defined Stats, Skills, Traits, and flexible inheritance logic.
* **Item and Economy System:** Define **Items** with custom categories, flags, and rarity. Create detailed **Currencies** for robust multi-currency or single-currency economies.
* **Crafting Recipes:** Use the **Recipes** tool to visually link input and output **Items** via drag-and-drop, making complex crafting systems easy to define.
* **Quest System (Odyssey):** Structure your game's progression using the hierarchical Quest system (Quests > Stages > Steps), allowing for detailed tracking and management of objectives.

## Utility Classes

The plugin also includes several utility classes covering specific, common development needs, which are a valuable asset outside of the main Nexus Forge editor tools:

* **Caching & Optimization:** Includes a basic implementation of a **Least Recently Used (LRU) Cache** and string optimization features.
* **Data Structures:** Helper classes for advanced data handling, such as a **Random Weighted Pool** for controlled chance-based selection, and **BitFlags** for efficient boolean storage.
* **Low-Level Helpers:** Dedicated classes for efficient **UUID (v4) generation** and **Bitwise operations**.

## Compatibility and Recommended Use

* **Engine:** Godot Engine 4.4+ (Written in GDScript).
* **Requirement:** Requires Godot 4.4 or later due to the use of typed dictionaries.
* **Recommended Resolution:** The plugin GUI is designed for **1920x1080 resolution**. It is usable at smaller resolutions, but you may encounter horizontal and vertical scrollbars which can make navigation more difficult.

## Documentation

All custom classes within Nexus Forge include comprehensive **built-in documentation**, accessible directly through the Godot editor's **F1 help menu**.

For detailed setup instructions and usage guides, please refer to the project's [Wiki/Documentation Link Here].
