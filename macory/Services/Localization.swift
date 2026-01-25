//
//  Localization.swift
//  macory
//
//  Created by Marco Baeuml on 25/01/2026.
//

import Foundation

struct Localization {
    static let en: [String: String] = [
        // General
        "search_placeholder": "Search history...",
        "clear_all": "Clear All (Option+Click to include pinned)",
        "no_history": "No clipboard history",
        "no_results": "No results found",
        "copy_start": "Copy something to get started",
        "items_count": "%d items",
        "results_count": "%d results",
        "footer_help": "↑↓ select  ⏎ paste  ⌘P pin  ⌘⌫ delete",
        "loading_image": "Loading image...",
        "pin": "Pin (⌘P)",
        "unpin": "Unpin (⌘P)",
        "delete": "Delete (⌘⌫)",
        
        // Time Algo
        "just_now": "Just now",
        "min_ago": "%d min ago",
        "hour_ago": "%d h ago",
        "hours_ago": "%d h ago",
        "day_ago": "%d d ago",
        "days_ago": "%d d ago",
        
        // Menu Bar
        "menu_show_history": "Show History",
        "menu_clear_history": "Clear History",
        "menu_settings": "Settings...",
        "menu_about": "About Macory",
        "menu_quit": "Quit Macory",
        
        // Windows & Alerts
        "settings_title": "Macory Settings",
        "about_title": "About Macory",
        "alert_clear_title": "Clear Clipboard History?",
        "alert_clear_desc": "This will remove items from your clipboard history. This action cannot be undone.",
        "clear": "Clear",
        "cancel": "Cancel",
        "clear_pinned": "Also clear pinned items",

        // Settings - Headers
        "general": "General",
        "appearance": "Appearance",
        "storage": "Storage",
        "shortcuts": "Shortcuts",
        "permissions": "Permissions",
        "about": "About",

        // Settings - General
        "language": "Language",
        "launch_login": "Launch at login",
        "show_dock": "Show in Dock",
        "show_dock_desc": "If disabled, app runs in menu bar only",
        "window_position": "Window Position",
        "quit": "Quit Macory",
        
        // Settings - Shortcuts
        "quick_paste": "Enable Quick Paste Shortcuts",
        "quick_paste_desc": "Use ⌘1-9 to paste the first 9 items",
        "global_hotkey": "Global Hotkey",
        "reset_default": "Reset to Default (⌘⇧V)",
        
        // Settings - Permissions
        "accessibility_access": "Accessibility Access",
        "accessibility_desc": "Required for global hotkey and pasting",
        "granted": "Granted",
        "grant_access": "Grant Access",

        // Settings - Appearance
        "use_custom_colors": "Use Custom Colors",
        "pinned": "Show Pin Button",
        "center_screen": "Center of Screen",
        "mouse_position": "At Mouse Position",
        "system": "System",
        "light": "Light",
        "dark": "Dark",
        "theme": "Theme",
        "accent_color": "Accent Color",
        "background_color": "Background Color",
        "secondary_color": "Secondary Color",
        "secondary_color_desc": "Secondary color is used for search bar and footer",
        
        // About
        "about_tagline": "Clipboard History Manager",
        "about_desc": "A lightweight clipboard history manager",
        "version": "Version %@ (%@)",

        // Settings - Storage
        "store_images": "Store Images",
        "store_images_desc": "Save copied images to history",
        "retention": "Retention",
        "keep_text": "Keep text for",
        "keep_images": "Keep images for",
        "days": "days"
    ]
    
    static let de: [String: String] = [
        // General
        "search_placeholder": "Verlauf durchsuchen...",
        "clear_all": "Alles löschen (Option+Klick für gepinnte)",
        "no_history": "Kein Verlauf",
        "no_results": "Keine Ergebnisse",
        "copy_start": "Kopiere etwas, um zu beginnen",
        "items_count": "%d Einträge",
        "results_count": "%d Ergebnisse",
        "footer_help": "↑↓ wählen  ⏎ einfügen  ⌘P pinnen  ⌘⌫ löschen",
        "loading_image": "Bild wird geladen...",
        "pin": "Anpinnen (⌘P)",
        "unpin": "Lösen (⌘P)",
        "delete": "Löschen (⌘⌫)",
        
        // Time Algo
        "just_now": "Gerade eben",
        "min_ago": "vor %d min",
        "hour_ago": "vor %d Std",
        "hours_ago": "vor %d Std",
        "day_ago": "vor %d T",
        "days_ago": "vor %d T",
        
        // Menu Bar
        "menu_show_history": "Verlauf anzeigen",
        "menu_clear_history": "Verlauf löschen",
        "menu_settings": "Einstellungen...",
        "menu_about": "Über Macory",
        "menu_quit": "Macory beenden",
        
        // Windows & Alerts
        "settings_title": "Macory Einstellungen",
        "about_title": "Über Macory",
        "alert_clear_title": "Verlauf löschen?",
        "alert_clear_desc": "Dies wird alle Einträge aus dem Verlauf entfernen. Diese Aktion kann nicht rückgängig gemacht werden.",
        "clear": "Löschen",
        "cancel": "Abbrechen",
        "clear_pinned": "Auch angepinnte Einträge löschen",

        // Settings - Headers
        "general": "Allgemein",
        "appearance": "Erscheinungsbild",
        "storage": "Speicher",
        "shortcuts": "Kurzbefehle",
        "permissions": "Berechtigungen",
        "about": "Über",

        // Settings - General
        "language": "Sprache",
        "launch_login": "Beim Anmelden starten",
        "show_dock": "Im Dock anzeigen",
        "show_dock_desc": "Wenn deaktiviert, läuft die App nur in der Menüleiste",
        "window_position": "Fensterposition",
        "quit": "Macory beenden",
        
        // Settings - Shortcuts
        "quick_paste": "Quick Paste Kurzbefehle aktivieren",
        "quick_paste_desc": "Nutze ⌘1-9 zum Einfügen der ersten 9 Elemente",
        "global_hotkey": "Globaler Kurzbefehl",
        "reset_default": "Standard wiederherstellen (⌘⇧V)",
        
        // Settings - Permissions
        "accessibility_access": "Bedienungshilfen-Zugriff",
        "accessibility_desc": "Erforderlich für globalen Kurzbefehl und Einfügen",
        "granted": "Zugriff erteilt",
        "grant_access": "Zugriff gewähren",

        // Settings - Appearance
        "use_custom_colors": "Benutzerdefinierte Farben",
        "pinned": "Pin-Button anzeigen",
        "center_screen": "Bildschirmmitte",
        "mouse_position": "Mausposition",
        "system": "System",
        "light": "Hell",
        "dark": "Dunkel",
        "theme": "Thema",
        "accent_color": "Akzentfarbe",
        "background_color": "Hintergrundfarbe",
        "secondary_color": "Sekundärfarbe",
        "secondary_color_desc": "Sekundärfarbe wird für Suchleiste und Fußzeile verwendet",
        
        // About
        "about_tagline": "Zwischenablage-Manager",
        "about_desc": "Ein leichter Verlauf für die Zwischenablage",
        "version": "Version %@ (%@)",

        // Settings - Storage
        "store_images": "Bilder speichern",
        "store_images_desc": "Kopierte Bilder im Verlauf speichern",
        "retention": "Aufbewahrung",
        "keep_text": "Text behalten für",
        "keep_images": "Bilder behalten für",
        "days": "Tage"
    ]
    
    static func string(_ key: String, language: AppLanguage) -> String {
        let dict: [String: String]
        switch language {
        case .german: dict = de
        case .english: dict = en
        case .system:
            // Simple heuristic for system language
            let langStr = Locale.current.language.languageCode?.identifier ?? "en"
            dict = langStr.contains("de") ? de : en
        }
        return dict[key] ?? key
    }
}
