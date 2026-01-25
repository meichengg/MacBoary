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
        case .english:
            dict = en
        case .german:
            dict = de
        case .spanish:
            dict = es
        case .french:
            dict = fr
        case .chinese:
            dict = zh
        case .hindi:
            dict = hi
        case .system:
            let langStr = Locale.current.language.languageCode?.identifier ?? "en"
            if langStr.contains("de") {
                dict = de
            } else if langStr.contains("es") {
                dict = es
            } else if langStr.contains("fr") {
                dict = fr
            } else if langStr.contains("zh") {
                dict = zh
            } else if langStr.contains("hi") {
                dict = hi
            } else {
                dict = en
            }
        }
        
        return dict[key] ?? en[key] ?? key
    }
    
    static let es: [String: String] = [
        // General
        "search_placeholder": "Buscar en el historial...",
        "clear_all": "Borrar todo (Opción+Click para incluir fijados)",
        "no_history": "Sin historial",
        "no_results": "Sin resultados",
        "copy_start": "Copia algo para empezar",
        "items_count": "%d elementos",
        "results_count": "%d resultados",
        "footer_help": "↑↓ seleccionar  ⏎ pegar  ⌘P fijar  ⌘⌫ eliniar",
        "loading_image": "Cargando imagen...",
        "pin": "Fijar (⌘P)",
        "unpin": "Desfijar (⌘P)",
        "delete": "Eliminar (⌘⌫)",
        
        // Time Algo
        "just_now": "Ahora mismo",
        "min_ago": "hace %d min",
        "hour_ago": "hace %d h",
        "hours_ago": "hace %d h",
        "day_ago": "hace %d d",
        "days_ago": "hace %d d",
        
        // Menu Bar
        "menu_show_history": "Mostrar Historial",
        "menu_clear_history": "Borrar Historial",
        "menu_settings": "Ajustes...",
        "menu_about": "Acerca de Macory",
        "menu_quit": "Salir de Macory",
        
        // Windows & Alerts
        "settings_title": "Ajustes de Macory",
        "about_title": "Acerca de Macory",
        "alert_clear_title": "¿Borrar historial?",
        "alert_clear_desc": "Esto eliminará los elementos de tu historial. Esta acción no se puede deshacer.",
        "clear": "Borrar",
        "cancel": "Cancelar",
        "clear_pinned": "Incluir elementos fijados",

        // Settings - Headers
        "general": "General",
        "appearance": "Apariencia",
        "storage": "Almacenamiento",
        "shortcuts": "Atajos",
        "permissions": "Permisos",
        "about": "Acerca de",

        // Settings - General
        "language": "Idioma",
        "launch_login": "Abrir al iniciar sesión",
        "show_dock": "Mostrar en el Dock",
        "show_dock_desc": "Si se desactiva, solo se muestra en la barra de menú",
        "window_position": "Posición de la ventana",
        "quit": "Salir de Macory",
        
        // Settings - Shortcuts
        "quick_paste": "Activar pegado rápido",
        "quick_paste_desc": "Usa ⌘1-9 para pegar los primeros 9 elementos",
        "global_hotkey": "Atajo global",
        "reset_default": "Restaurar (⌘⇧V)",
        
        // Settings - Permissions
        "accessibility_access": "Acceso de accesibilidad",
        "accessibility_desc": "Requerido para el atajo global y pegar",
        "granted": "Concedido",
        "grant_access": "Conceder acceso",

        // Settings - Appearance
        "use_custom_colors": "Colores personalizados",
        "pinned": "Mostrar botón de fijar",
        "center_screen": "Centro de la pantalla",
        "mouse_position": "Posición del ratón",
        "system": "Sistema",
        "light": "Claro",
        "dark": "Oscuro",
        "theme": "Tema",
        "accent_color": "Color de acento",
        "background_color": "Color de fondo",
        "secondary_color": "Color secundario",
        "secondary_color_desc": "El color secundario se usa para la barra de búsqueda y el pie",
        
        // About
        "about_tagline": "Gestor de historial del portapapeles",
        "about_desc": "Un gestor de portapapeles ligero",
        "version": "Versión %@ (%@)",

        // Settings - Storage
        "store_images": "Guardar imágenes",
        "store_images_desc": "Guardar imágenes copiadas en el historial",
        "retention": "Retención",
        "keep_text": "Guardar texto por",
        "keep_images": "Guardar imágenes por",
        "days": "días"
    ]

    static let fr: [String: String] = [
        // General
        "search_placeholder": "Rechercher...",
        "clear_all": "Tout effacer (Option+Clic pour les épinglés)",
        "no_history": "Aucun historique",
        "no_results": "Aucun résultat",
        "copy_start": "Copiez quelque chose pour commencer",
        "items_count": "%d éléments",
        "results_count": "%d résultats",
        "footer_help": "↑↓ choisir  ⏎ coller  ⌘P épingler  ⌘⌫ supprimer",
        "loading_image": "Chargement...",
        "pin": "Épingler (⌘P)",
        "unpin": "Désépingler (⌘P)",
        "delete": "Supprimer (⌘⌫)",
        
        // Time Algo
        "just_now": "À l'instant",
        "min_ago": "il y a %d min",
        "hour_ago": "il y a %d h",
        "hours_ago": "il y a %d h",
        "day_ago": "il y a %d j",
        "days_ago": "il y a %d j",
        
        // Menu Bar
        "menu_show_history": "Afficher l'historique",
        "menu_clear_history": "Effacer l'historique",
        "menu_settings": "Réglages...",
        "menu_about": "À propos de Macory",
        "menu_quit": "Quitter Macory",
        
        // Windows & Alerts
        "settings_title": "Réglages Macory",
        "about_title": "À propos de Macory",
        "alert_clear_title": "Effacer l'historique ?",
        "alert_clear_desc": "Ceci supprimera les éléments de votre historique. Cette action est irréversible.",
        "clear": "Effacer",
        "cancel": "Annuler",
        "clear_pinned": "Effacer aussi les éléments épinglés",

        // Settings - Headers
        "general": "Général",
        "appearance": "Apparence",
        "storage": "Stockage",
        "shortcuts": "Raccourcis",
        "permissions": "Permissions",
        "about": "À propos",

        // Settings - General
        "language": "Langue",
        "launch_login": "Lancer au démarrage",
        "show_dock": "Afficher dans le Dock",
        "show_dock_desc": "Si désactivé, l'app tourne uniquement dans la barre des menus",
        "window_position": "Position de la fenêtre",
        "quit": "Quitter Macory",
        
        // Settings - Shortcuts
        "quick_paste": "Collage rapide",
        "quick_paste_desc": "Utilisez ⌘1-9 pour coller les 9 premiers éléments",
        "global_hotkey": "Raccourci global",
        "reset_default": "Rétablir (⌘⇧V)",
        
        // Settings - Permissions
        "accessibility_access": "Accès d'accessibilité",
        "accessibility_desc": "Requis pour le raccourci global et le collage",
        "granted": "Accordé",
        "grant_access": "Accorder l'accès",

        // Settings - Appearance
        "use_custom_colors": "Couleurs personnalisées",
        "pinned": "Bouton d'épinglage",
        "center_screen": "Centre de l'écran",
        "mouse_position": "Position de la souris",
        "system": "Système",
        "light": "Clair",
        "dark": "Sombre",
        "theme": "Thème",
        "accent_color": "Couleur d'accentuation",
        "background_color": "Couleur d'arrière-plan",
        "secondary_color": "Couleur secondaire",
        "secondary_color_desc": "Utilisée pour la barre de recherche et le pied de page",
        
        // About
        "about_tagline": "Gestionnaire d'historique de presse-papiers",
        "about_desc": "Un gestionnaire de presse-papiers léger",
        "version": "Version %@ (%@)",

        // Settings - Storage
        "store_images": "Garder les images",
        "store_images_desc": "Enregistrer les images copiées",
        "retention": "Rétention",
        "keep_text": "Garder le texte pour",
        "keep_images": "Garder les images pour",
        "days": "jours"
    ]

    static let zh: [String: String] = [
        // General
        "search_placeholder": "搜索历史...",
        "clear_all": "清除全部 (Option+点击包含置顶)",
        "no_history": "无剪贴板历史",
        "no_results": "无结果",
        "copy_start": "复制内容以开始",
        "items_count": "%d 项",
        "results_count": "%d 结果",
        "footer_help": "↑↓ 选择  ⏎ 粘贴  ⌘P 置顶  ⌘⌫ 删除",
        "loading_image": "加载图片...",
        "pin": "置顶 (⌘P)",
        "unpin": "取消置顶 (⌘P)",
        "delete": "删除 (⌘⌫)",
        
        // Time Algo
        "just_now": "刚刚",
        "min_ago": "%d 分钟前",
        "hour_ago": "%d 小时前",
        "hours_ago": "%d 小时前",
        "day_ago": "%d 天前",
        "days_ago": "%d 天前",
        
        // Menu Bar
        "menu_show_history": "显示历史",
        "menu_clear_history": "清除历史",
        "menu_settings": "设置...",
        "menu_about": "关于 Macory",
        "menu_quit": "退出 Macory",
        
        // Windows & Alerts
        "settings_title": "Macory 设置",
        "about_title": "关于 Macory",
        "alert_clear_title": "清除剪贴板历史？",
        "alert_clear_desc": "这将移除剪贴板历史中的项目。此操作无法撤销。",
        "clear": "清除",
        "cancel": "取消",
        "clear_pinned": "同时清除置顶项目",

        // Settings - Headers
        "general": "常规",
        "appearance": "外观",
        "storage": "存储",
        "shortcuts": "快捷键",
        "permissions": "权限",
        "about": "关于",

        // Settings - General
        "language": "语言",
        "launch_login": "登录时启动",
        "show_dock": "显示在程序坞",
        "show_dock_desc": "如果禁用，应用仅在菜单栏运行",
        "window_position": "窗口位置",
        "quit": "退出 Macory",
        
        // Settings - Shortcuts
        "quick_paste": "启用快速粘贴",
        "quick_paste_desc": "使用 ⌘1-9 粘贴前9项",
        "global_hotkey": "全局快捷键",
        "reset_default": "重置默认 (⌘⇧V)",
        
        // Settings - Permissions
        "accessibility_access": "辅助功能权限",
        "accessibility_desc": "全局快捷键和粘贴功能需要",
        "granted": "已授权",
        "grant_access": "授权",

        // Settings - Appearance
        "use_custom_colors": "使用自定义颜色",
        "pinned": "显示置顶按钮",
        "center_screen": "屏幕中央",
        "mouse_position": "鼠标位置",
        "system": "系统",
        "light": "浅色",
        "dark": "深色",
        "theme": "主题",
        "accent_color": "强调色",
        "background_color": "背景色",
        "secondary_color": "次要颜色",
        "secondary_color_desc": "次要颜色用于搜索栏和底部",
        
        // About
        "about_tagline": "剪贴板历史管理器",
        "about_desc": "轻量级剪贴板历史工具",
        "version": "版本 %@ (%@)",

        // Settings - Storage
        "store_images": "存储图片",
        "store_images_desc": "保存复制的图片到历史",
        "retention": "保留时间",
        "keep_text": "文本保留",
        "keep_images": "图片保留",
        "days": "天"
    ]

    static let hi: [String: String] = [
        // General
        "search_placeholder": "इतिहास खोजें...",
        "clear_all": "सभी हटाएं (Option+Click पिन किए गए सहित)",
        "no_history": "कोई इतिहास नहीं",
        "no_results": "कोई परिणाम नहीं",
        "copy_start": "शुरू करने के लिए कुछ कॉपी करें",
        "items_count": "%d आइटम",
        "results_count": "%d परिणाम",
        "footer_help": "↑↓ चुनें  ⏎ पेस्ट  ⌘P पिन  ⌘⌫ हटाएं",
        "loading_image": "छवि लोड हो रही है...",
        "pin": "पिन (⌘P)",
        "unpin": "अनपिन (⌘P)",
        "delete": "हटाएं (⌘⌫)",
        
        // Time Algo
        "just_now": "अभी",
        "min_ago": "%d मिनट पहले",
        "hour_ago": "%d घंटे पहले",
        "hours_ago": "%d घंटे पहले",
        "day_ago": "%d दिन पहले",
        "days_ago": "%d दिन पहले",
        
        // Menu Bar
        "menu_show_history": "इतिहास दिखाएं",
        "menu_clear_history": "इतिहास हटाएं",
        "menu_settings": "सेटिंग्स...",
        "menu_about": "Macory के बारे में",
        "menu_quit": "Macory बंद करें",
        
        // Windows & Alerts
        "settings_title": "Macory सेटिंग्स",
        "about_title": "Macory के बारे में",
        "alert_clear_title": "क्लिपबोर्ड इतिहास हटाएं?",
        "alert_clear_desc": "यह आपके इतिहास से आइटम हटा देगा। इसे पूर्ववत नहीं किया जा सकता।",
        "clear": "हटाएं",
        "cancel": "रद्द करें",
        "clear_pinned": "पिन किए गए आइटम भी हटाएं",

        // Settings - Headers
        "general": "सामान्य",
        "appearance": "दिखावट",
        "storage": "भंडारण",
        "shortcuts": "शॉर्टकट",
        "permissions": "अनुमतियां",
        "about": "के बारे में",

        // Settings - General
        "language": "भाषा",
        "launch_login": "लॉगिन पर शुरू करें",
        "show_dock": "डॉक में दिखाएं",
        "show_dock_desc": "अक्षम होने पर, ऐप केवल मेनू बार में चलता है",
        "window_position": "विंडो स्थिति",
        "quit": "Macory बंद करें",
        
        // Settings - Shortcuts
        "quick_paste": "त्वरित पेस्ट सक्षम करें",
        "quick_paste_desc": "पहले 9 आइटम पेस्ट करने के लिए ⌘1-9 का उपयोग करें",
        "global_hotkey": "ग्लोबल हॉटकी",
        "reset_default": "डिफ़ॉल्ट रीसेट (⌘⇧V)",
        
        // Settings - Permissions
        "accessibility_access": "एक्सेसिबिलिटी एक्सेस",
        "accessibility_desc": "ग्लोबल हॉटकी और पेस्ट करने के लिए आवश्यक",
        "granted": "दी गई",
        "grant_access": "एक्सेस दें",

        // Settings - Appearance
        "use_custom_colors": "कस्टम रंग उपयोग करें",
        "pinned": "पिन बटन दिखाएं",
        "center_screen": "स्क्रीन के केंद्र में",
        "mouse_position": "माउस की स्थिति पर",
        "system": "सिस्टम",
        "light": "लाइट",
        "dark": "डार्क",
        "theme": "थीम",
        "accent_color": "एक्सेंट रंग",
        "background_color": "बैकग्राउंड रंग",
        "secondary_color": "द्वितीयक रंग",
        "secondary_color_desc": "द्वितीयक रंग खोज बार और फुटर के लिए उपयोग किया जाता है",
        
        // About
        "about_tagline": "क्लिपबोर्ड इतिहास प्रबंधक",
        "about_desc": "एक हल्का क्लिपबोर्ड इतिहास प्रबंधक",
        "version": "संस्करण %@ (%@)",

        // Settings - Storage
        "store_images": "छवियां स्टोर करें",
        "store_images_desc": "कॉपी की गई छवियां इतिहास में सहेजें",
        "retention": "अवधारण",
        "keep_text": "टेक्स्ट रखें",
        "keep_images": "छवियां रखें",
        "days": "दिन"
    ]
}
