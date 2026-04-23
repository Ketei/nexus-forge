extends DiscourseDialog
class_name ModDiscourseDialog
## A resource containing a new modded conversation.
##
## This resource only contains the "logic" part of a conversation to be parsed
## by Discourse on project export. This file is intended for dialogs that are NOT
## in the base game and is intended to add new conversations to the game.

## [b]REQUIRED[/b][br]
## An ID for the dialog. Giving this a distinct ID that can ensure that
## this dialog doesn't conflict or get overriden by other mod dialogs.
@export var dialog_id: String = ""
## The path where the locale data is stored at. The localization folder structure
## must follow a specific structure which is usually made with Nexus Forge custom
## exporter (WIP)
@export_dir var localization_folder: String = ""
## The version of this dialog file
@export var version: String = ""
