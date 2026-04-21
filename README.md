# Nexus Forge - A Godot Game Data Manager


**Nexus Forge** is a powerful, open-source **Godot Engine plugin** designed to handle the basic data of your game. Built entirely in **GDScript**, it provides a range of visual editor tools for managing everything from complex dialogue, player stats, items, quests and more without enforcing any specific UI, giving you maximum creative freedom.

> [!IMPORTANT]
> * This plugin is currently in the **Alpha stage**. While the tools are functional they haven't been throughly tested and the **Graphical User Interface (GUI)**, internal API definitions (class names, function names) and other core properties may change significantly before the Beta release.</br>
> * **Use of this plugin is recommended for testing, evaluation, or as a VERY bold choice for current projects.** It is not yet considered reliable for production projects, expect bugs.</br>
> * This plugin started as a personal tool which means some things might be tailored for my personal intended use. This, however, doesn't mean I won't change or tweak them for general use in the future.</br>

> [!WARNING]
> Nexus Forge does NOT implement an **UndoRedo** system, meaning that any action taken in the plugin can't be undone.

## Core Features and Tools

Nexus Forge is a data-centric plugin that gives you structured control over your game's content:

* **Dialogue Editor:** Create branching, context-aware, localized conversations using a visual **GraphEdit** interface.
* **Global State Management:** Easily store and manage global variables.
* **Character Design:** Dedicated tools for defining **Characters**. Customize character sheets with user-defined stats, skills, traits, species, and flexible inheritance logic.
* **Item and Economy System:** Define **Items** with custom categories, flags, values, and rarities. Create detailed **Currencies** for robust multi-currency or single-currency economies.
* **Crafting Recipes:** Use the **Recipes** tool to create crafting recipes, making complex crafting systems easy to define.
* **Quest Creation:** Create detailed quests with stages and steps to follow.
* **Argument-based text formatting**: Create context aware text that changes based on given arguments.

## Utility Classes

The plugin also includes several utility classes covering specific, common development needs, which are a valuable asset outside of the main Nexus Forge editor tools:

* **Caching:** Includes a basic implementation of a **Least Recently Used (LRU) Cache**.
* **Data Structures:** Helper classes for advanced data handling, such as a **Random Weighted Pool** for controlled chance-based selection, and **BitFlags** for efficient boolean storage.
* **Low-Level Helpers:** Dedicated classes for efficient **UUID (v4) generation** and **Bitwise operations**.

## Compatibility and Recommended Use

* **Engine:** Godot Engine 4.4+ (Written in GDScript).
* **Requirement:** Requires Godot 4.4 or later due to the use of typed dictionaries.
* **Recommended Resolution:** The plugin GUI is designed for **1920x1080 resolution**. It is usable at smaller resolutions, but you will encounter horizontal and vertical scrollbars which can make navigation more difficult.

## Documentation

### In-Engine Documentation
All custom classes within Nexus Forge include comprehensive **built-in documentation**, accessible directly through the Godot editor's **F1 help menu**. Written manually to assist the developer

### GitHub Wiki
A wiki with detailed setup instructions and usage guides can be found on the project's [Wiki/Documentation Link Here].
Please note that the GitHub Wiki has been generated with the assitance of AI but was reviewed in its totallity by me.
A rewrite is planned for the future once I can dedicate less time to the code.
