//
//  Localization.swift
//  macory
//
//  Created by Marco Baeuml on 25/01/2026.
//

import Foundation

struct LocalizedString {
    let en: String
    let de: String
    
    func localized(_ language: AppLanguage) -> String {
        switch language {
        case .english:
            return en
        case .german:
            return de
        case .system:
            let langStr = Locale.current.language.languageCode?.identifier ?? "en"
            if langStr.contains("de") {
                return de
            } else {
                return en
            }
        }
    }
}

struct Localization {
    static func localized(_ key: String, language: AppLanguage) -> String {
        strings[key]?.localized(language) ?? key
    }
    
    static let strings: [String: LocalizedString] = [
        // General
        "search_placeholder": LocalizedString(en: "Search history...", de: "Verlauf durchsuchen..."),
        "clear_all": LocalizedString(en: "Clear All (Option+Click to include pinned)", de: "Alles löschen (Option+Klick für gepinnte)"),
        "no_history": LocalizedString(en: "No clipboard history", de: "Kein Verlauf"),
        "no_results": LocalizedString(en: "No results found", de: "Keine Ergebnisse"),
        "copy_start": LocalizedString(en: "Copy something to get started", de: "Kopiere etwas, um zu beginnen"),
        "load_more": LocalizedString(en: "Load More...", de: "Mehr laden..."),
        "items_count": LocalizedString(en: "%d items", de: "%d Einträge"),
        "results_count": LocalizedString(en: "%d results", de: "%d Ergebnisse"),
        "footer_help": LocalizedString(en: "↑↓ select  ⏎ paste  ⌘P pin  ⌘⌫ delete", de: "↑↓ wählen  ⏎ einfügen  ⌘P pinnen  ⌘⌫ löschen"),
        "loading_image": LocalizedString(en: "Loading image...", de: "Bild wird geladen..."),
        "pin": LocalizedString(en: "Pin (⌘P)", de: "Anpinnen (⌘P)"),
        "unpin": LocalizedString(en: "Unpin (⌘P)", de: "Lösen (⌘P)"),
        "delete": LocalizedString(en: "Delete (⌘⌫)", de: "Löschen (⌘⌫)"),
        
        // Time Algo
        "just_now": LocalizedString(en: "Just now", de: "Gerade eben"),
        "min_ago": LocalizedString(en: "%d min ago", de: "vor %d min"),
        "hour_ago": LocalizedString(en: "%d h ago", de: "vor %d Std"),
        "hours_ago": LocalizedString(en: "%d h ago", de: "vor %d Std"),
        "day_ago": LocalizedString(en: "%d d ago", de: "vor %d T"),
        "days_ago": LocalizedString(en: "%d d ago", de: "vor %d T"),
        
        // Menu Bar
        "menu_show_history": LocalizedString(en: "Show History", de: "Verlauf anzeigen"),
        "menu_clear_history": LocalizedString(en: "Clear History", de: "Verlauf löschen"),
        "menu_settings": LocalizedString(en: "Settings...", de: "Einstellungen..."),
        "menu_about": LocalizedString(en: "About Macory", de: "Über Macory"),
        "menu_quit": LocalizedString(en: "Quit Macory", de: "Macory beenden"),
        
        // Windows & Alerts
        "settings_title": LocalizedString(en: "Macory Settings", de: "Macory Einstellungen"),
        "about_title": LocalizedString(en: "About Macory", de: "Über Macory"),
        "alert_clear_title": LocalizedString(en: "Clear Clipboard History?", de: "Verlauf löschen?"),
        "alert_clear_desc": LocalizedString(en: "This will remove items from your clipboard history. This action cannot be undone.", de: "Dies wird alle Einträge aus dem Verlauf entfernen. Diese Aktion kann nicht rückgängig gemacht werden."),
        "clear": LocalizedString(en: "Clear", de: "Löschen"),
        "cancel": LocalizedString(en: "Cancel", de: "Abbrechen"),
        "clear_pinned": LocalizedString(en: "Also clear pinned items", de: "Auch angepinnte Einträge löschen"),
        
        // Settings - Headers
        "general": LocalizedString(en: "General", de: "Allgemein"),
        "appearance": LocalizedString(en: "Appearance", de: "Erscheinungsbild"),
        "storage": LocalizedString(en: "Storage", de: "Speicher"),
        "shortcuts": LocalizedString(en: "Shortcuts", de: "Kurzbefehle"),
        "permissions": LocalizedString(en: "Permissions", de: "Berechtigungen"),
        "about": LocalizedString(en: "About", de: "Über"),
        
        // Settings - General
        "language": LocalizedString(en: "Language", de: "Sprache"),
        "launch_login": LocalizedString(en: "Launch at login", de: "Beim Anmelden starten"),
        "show_dock": LocalizedString(en: "Show in Dock", de: "Im Dock anzeigen"),
        "show_dock_desc": LocalizedString(en: "If disabled, app runs in menu bar only", de: "Wenn deaktiviert, läuft die App nur in der Menüleiste"),
        "window_position": LocalizedString(en: "Window Position", de: "Fensterposition"),
        "quit": LocalizedString(en: "Quit Macory", de: "Macory beenden"),
        
        // Settings - Shortcuts
        "quick_paste": LocalizedString(en: "Enable Quick Paste Shortcuts", de: "Quick Paste Kurzbefehle aktivieren"),
        "quick_paste_desc": LocalizedString(en: "Use ⌘1-9 to paste the first 9 items", de: "Nutze ⌘1-9 zum Einfügen der ersten 9 Elemente"),
        "global_hotkey": LocalizedString(en: "Global Hotkey", de: "Globaler Kurzbefehl"),
        "reset_default": LocalizedString(en: "Reset to Default (⌘⇧V)", de: "Standard wiederherstellen (⌘⇧V)"),
        
        // Settings - Permissions
        "accessibility_access": LocalizedString(en: "Accessibility Access", de: "Bedienungshilfen-Zugriff"),
        "accessibility_desc": LocalizedString(en: "Required for automatic paste", de: "Erforderlich für automatisches Einfügen"),
        "keychain_access": LocalizedString(en: "Keychain Access", de: "Schlüsselbund-Zugriff"),
        "keychain_desc": LocalizedString(en: "Required for encryption key storage", de: "Erforderlich für Verschlüsselungsschlüssel-Speicherung"),
        "granted": LocalizedString(en: "Granted", de: "Zugriff erteilt"),
        "denied": LocalizedString(en: "Denied", de: "Verweigert"),
        "grant_access": LocalizedString(en: "Grant Access", de: "Zugriff gewähren"),
        "permission_granted_notification": LocalizedString(en: "Accessibility permission granted! Automatic paste is now enabled.", de: "Zugriffsberechtigung erteilt! Automatisches Einfügen ist jetzt aktiviert."),
        "permission_warning": LocalizedString(en: "Accessibility permission required for automatic paste.", de: "Bedienungshilfen-Zugriff erforderlich für automatisches Einfügen."),
        "keychain_access_title": LocalizedString(en: "Keychain Access Required", de: "Schlüsselbund-Zugriff erforderlich"),
        "keychain_access_message": LocalizedString(en: "Macory needs access to the Keychain to store the encryption key securely. Encryption will be disabled for now. You can enable it anytime in the settings.", de: "Macory benötigt Zugriff auf den Schlüsselbund, um den Verschlüsselungsschlüssel sicher zu speichern. Die Verschlüsselung wird vorerst deaktiviert. Sie können sie jederzeit in den Einstellungen aktivieren."),
        
        // Settings - Appearance
        "use_custom_colors": LocalizedString(en: "Use Custom Colors", de: "Benutzerdefinierte Farben"),
        "pinned": LocalizedString(en: "Show Pin Button", de: "Pin-Button anzeigen"),
        "center_screen": LocalizedString(en: "Center of Screen", de: "Bildschirmmitte"),
        "mouse_position": LocalizedString(en: "At Mouse Position", de: "Mausposition"),
        "system": LocalizedString(en: "System", de: "System"),
        "light": LocalizedString(en: "Light", de: "Hell"),
        "dark": LocalizedString(en: "Dark", de: "Dunkel"),
        "theme": LocalizedString(en: "Theme", de: "Thema"),
        "accent_color": LocalizedString(en: "Accent Color", de: "Akzentfarbe"),
        "background_color": LocalizedString(en: "Background Color", de: "Hintergrundfarbe"),
        "secondary_color": LocalizedString(en: "Secondary Color", de: "Sekundärfarbe"),
        "secondary_color_desc": LocalizedString(en: "Secondary color is used for search bar and footer", de: "Sekundärfarbe wird für Suchleiste und Fußzeile verwendet"),
        
        // About
        "about_tagline": LocalizedString(en: "Clipboard History Manager", de: "Zwischenablage-Manager"),
        "about_desc": LocalizedString(en: "A lightweight clipboard history manager", de: "Ein leichter Verlauf für die Zwischenablage"),
        "version": LocalizedString(en: "Version %@ (%@)", de: "Version %@ (%@)"),
        
        // Settings - Storage
        "store_images": LocalizedString(en: "Store Images", de: "Bilder speichern"),
        "store_images_desc": LocalizedString(en: "Save copied images to history", de: "Kopierte Bilder im Verlauf speichern"),
        "text_retention": LocalizedString(en: "Text Retention", de: "Text-Aufbewahrung"),
        "image_retention": LocalizedString(en: "Image Retention", de: "Bild-Aufbewahrung"),
        "max_history_items": LocalizedString(en: "History Limit", de: "Verlaufs-Limit"),
        "retention": LocalizedString(en: "Retention", de: "Aufbewahrung"),
        "keep_text": LocalizedString(en: "Keep text for", de: "Text behalten für"),
        "keep_images": LocalizedString(en: "Keep images for", de: "Bilder behalten für"),
        "days": LocalizedString(en: "days", de: "Tage"),
        "forever": LocalizedString(en: "Forever", de: "Für immer"),
        "disabled": LocalizedString(en: "Disabled", de: "Deaktiviert"),
        
        // Settings - Encryption
        "encrypt_clipboard": LocalizedString(en: "Encrypt Clipboard History", de: "Zwischenablage verschlüsseln"),
        "encrypt_clipboard_desc": LocalizedString(en: "Uses AES-256 encryption to protect sensitive data", de: "Verwendet AES-256-Verschlüsselung zum Schutz sensibler Daten"),
        "encrypt_opt_in_title": LocalizedString(en: "Enable Clipboard Encryption?", de: "Zwischenablage-Verschlüsselung aktivieren?"),
        "encrypt_opt_in_message": LocalizedString(en: "Macory can encrypt your clipboard history to protect sensitive information like passwords and credit cards.\n\nEncryption is optional but recommended for enhanced security. You can change this later in Settings.", de: "Macory kann Ihren Zwischenablage-Verlauf verschlüsseln, um sensible Informationen wie Passwörter und Kreditkarten zu schützen.\n\nVerschlüsselung ist optional, aber für erhöhte Sicherheit empfohlen. Sie können dies später in den Einstellungen ändern."),
        "encrypt_opt_in_enable": LocalizedString(en: "Enable Encryption", de: "Verschlüsselung aktivieren"),
        "encrypt_opt_in_disable": LocalizedString(en: "Skip", de: "Überspringen"),
        
        // Settings - Permission Info
        "accessibility_info_title": LocalizedString(en: "Accessibility Permission Required", de: "Zugriffsberechtigung erforderlich"),
        "accessibility_info_message": LocalizedString(en: "Macory needs Accessibility permission for automatic paste functionality.\n\nPlease grant permission in the next dialog.", de: "Macory benötigt Zugriff auf die Bedienungshilfen für die automatische Einfügefunktion.\n\nBitte gewähren Sie Zugriff im nächsten Dialog.")
    ]
}
