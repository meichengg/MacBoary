//
//  Localization.swift
//  macboary
//
//  Created by Marco Baeuml on 25/01/2026.
//

import Foundation

struct LocalizedString {
    let en: String
    let de: String
    let es: String?
    let fr: String?
    let zh: String?
    let ja: String?
    let ko: String?
    let ru: String?
    let pt: String?
    let it: String?
    
    init(en: String, de: String, es: String? = nil, fr: String? = nil, zh: String? = nil, ja: String? = nil, ko: String? = nil, ru: String? = nil, pt: String? = nil, it: String? = nil) {
        self.en = en
        self.de = de
        self.es = es
        self.fr = fr
        self.zh = zh
        self.ja = ja
        self.ko = ko
        self.ru = ru
        self.pt = pt
        self.it = it
    }
    
    func localized(_ language: AppLanguage) -> String {
        switch language {
        case .english:
            return en
        case .german:
            return de
        case .spanish:
            return es ?? en
        case .french:
            return fr ?? en
        case .chinese:
            return zh ?? en
        case .japanese:
            return ja ?? en
        case .korean:
            return ko ?? en
        case .russian:
            return ru ?? en
        case .portuguese:
            return pt ?? en
        case .italian:
            return it ?? en
        case .system:
            let langStr = Locale.current.language.languageCode?.identifier ?? "en"
            if langStr.contains("de") { return de }
            else if langStr.contains("es") { return es ?? en }
            else if langStr.contains("fr") { return fr ?? en }
            else if langStr.contains("zh") { return zh ?? en }
            else if langStr.contains("ja") { return ja ?? en }
            else if langStr.contains("ko") { return ko ?? en }
            else if langStr.contains("ru") { return ru ?? en }
            else if langStr.contains("pt") { return pt ?? en }
            else if langStr.contains("it") { return it ?? en }
            else { return en }
        }
    }
}

struct Localization {
    static func localized(_ key: String, language: AppLanguage) -> String {
        strings[key]?.localized(language) ?? key
    }
    
    static let strings: [String: LocalizedString] = [
        "search_placeholder": LocalizedString(
            en: "Search history...",
            de: "Verlauf durchsuchen...",
            es: "Buscar historial...",
            fr: "Rechercher dans l'historique...",
            zh: "搜索历史记录...",
            ja: "履歴を検索...",
            ko: "기록 검색...",
            ru: "Поиск в истории...",
            pt: "Pesquisar histórico...",
            it: "Cerca nella cronologia..."
        ),
        "clear_all": LocalizedString(
            en: "Clear All (Option+Click to include pinned)",
            de: "Alles löschen (Option+Klick für gepinnte)",
            es: "Borrar todo (Opción+Clic para incluir fijados)",
            fr: "Tout effacer (Option+Clic pour inclure les épinglés)",
            zh: "清除全部 (按住 Option 点击包括置顶项)",
            ja: "すべて消去 (Option+クリックでピン留めも含む)",
            ko: "모두 지우기 (Option+클릭으로 고정된 항목 포함)",
            ru: "Очистить все (Option+Клик для закрепленных)",
            pt: "Limpar tudo (Option+Clique para incluir fixados)",
            it: "Cancella tutto (Opzione+Clic per includere i fissati)"
        ),
        "no_history": LocalizedString(
            en: "No clipboard history",
            de: "Kein Verlauf",
            es: "Sin historial",
            fr: "Aucun historique",
            zh: "无剪贴板历史",
            ja: "履歴なし",
            ko: "기록 없음",
            ru: "Нет истории",
            pt: "Sem histórico",
            it: "Nessuna cronologia"
        ),
        "no_results": LocalizedString(
            en: "No results found",
            de: "Keine Ergebnisse",
            es: "No se encontraron resultados",
            fr: "Aucun résultat",
            zh: "未找到结果",
            ja: "結果なし",
            ko: "결과 없음",
            ru: "Нет результатов",
            pt: "Nenhum resultado",
            it: "Nessun risultato"
        ),
        "copy_start": LocalizedString(
            en: "Copy something to get started",
            de: "Kopiere etwas, um zu beginnen",
            es: "Copia algo para empezar",
            fr: "Copiez quelque chose pour commencer",
            zh: "复制内容以开始",
            ja: "コピーして開始",
            ko: "시작하려면 복사하세요",
            ru: "Скопируйте что-нибудь",
            pt: "Copie algo para começar",
            it: "Copia qualcosa per iniziare"
        ),
        "load_more": LocalizedString(
            en: "Load More...",
            de: "Mehr laden...",
            es: "Cargar más...",
            fr: "Charger plus...",
            zh: "加载更多...",
            ja: "もっと読み込む...",
            ko: "더 불러오기...",
            ru: "Загрузить еще...",
            pt: "Carregar mais...",
            it: "Carica altro..."
        ),
        "items_count": LocalizedString(
            en: "%d items",
            de: "%d Einträge",
            es: "%d elementos",
            fr: "%d éléments",
            zh: "%d 项",
            ja: "%d 項目",
            ko: "%d 항목",
            ru: "%d элементов",
            pt: "%d itens",
            it: "%d elementi"
        ),
        "results_count": LocalizedString(
            en: "%d results",
            de: "%d Ergebnisse",
            es: "%d resultados",
            fr: "%d résultats",
            zh: "%d 个结果",
            ja: "%d 件の結果",
            ko: "%d 결과",
            ru: "%d результатов",
            pt: "%d resultados",
            it: "%d risultati"
        ),
        "footer_help": LocalizedString(
            en: "↑↓ select  ⏎ paste  ⌘P pin  ⌘⌫ delete",
            de: "↑↓ wählen  ⏎ einfügen  ⌘P pinnen  ⌘⌫ löschen",
            es: "↑↓ seleccionar  ⏎ pegar  ⌘P fijar  ⌘⌫ eliminar",
            fr: "↑↓ select.  ⏎ coller  ⌘P épingler  ⌘⌫ suppr.",
            zh: "↑↓ 选择  ⏎ 粘贴  ⌘P 置顶  ⌘⌫ 删除",
            ja: "↑↓ 選択  ⏎ 貼り付け  ⌘P 固定  ⌘⌫ 削除",
            ko: "↑↓ 선택  ⏎ 붙여넣기  ⌘P 고정  ⌘⌫ 삭제",
            ru: "↑↓ выбрать  ⏎ вставить  ⌘P закрепить  ⌘⌫ удалить",
            pt: "↑↓ sel.  ⏎ colar  ⌘P fixar  ⌘⌫ excluir",
            it: "↑↓ sel.  ⏎ incolla  ⌘P fissa  ⌘⌫ elimina"
        ),
        "loading_image": LocalizedString(
            en: "Loading image...",
            de: "Bild wird geladen...",
            es: "Cargando imagen...",
            fr: "Chargement...",
            zh: "正在加载图片...",
            ja: "画像を読み込み中...",
            ko: "이미지 로드 중...",
            ru: "Загрузка изображения...",
            pt: "Carregando imagem...",
            it: "Caricamento immagine..."
        ),
        "pin": LocalizedString(
            en: "Pin (⌘P)",
            de: "Anpinnen (⌘P)",
            es: "Fijar (⌘P)",
            fr: "Épingler (⌘P)",
            zh: "置顶 (⌘P)",
            ja: "固定 (⌘P)",
            ko: "고정 (⌘P)",
            ru: "Закрепить (⌘P)",
            pt: "Fixar (⌘P)",
            it: "Fissa (⌘P)"
        ),
        "unpin": LocalizedString(
            en: "Unpin (⌘P)",
            de: "Lösen (⌘P)",
            es: "Desfijar (⌘P)",
            fr: "Désépingler (⌘P)",
            zh: "取消置顶 (⌘P)",
            ja: "固定解除 (⌘P)",
            ko: "고정 해제 (⌘P)",
            ru: "Открепить (⌘P)",
            pt: "Desafixar (⌘P)",
            it: "Rimuovi fissaggio (⌘P)"
        ),
        "delete": LocalizedString(
            en: "Delete (⌘⌫)",
            de: "Löschen (⌘⌫)",
            es: "Eliminar (⌘⌫)",
            fr: "Supprimer (⌘⌫)",
            zh: "删除 (⌘⌫)",
            ja: "削除 (⌘⌫)",
            ko: "삭제 (⌘⌫)",
            ru: "Удалить (⌘⌫)",
            pt: "Excluir (⌘⌫)",
            it: "Elimina (⌘⌫)"
        ),
        "just_now": LocalizedString(
            en: "Just now",
            de: "Gerade eben",
            es: "Ahora mismo",
            fr: "À l'instant",
            zh: "刚刚",
            ja: "たった今",
            ko: "방금",
            ru: "Только что",
            pt: "Agora mesmo",
            it: "Proprio ora"
        ),
        "min_ago": LocalizedString(
            en: "%d min ago",
            de: "vor %d min",
            es: "hace %d min",
            fr: "il y a %d min",
            zh: "%d 分钟前",
            ja: "%d 分前",
            ko: "%d분 전",
            ru: "%d мин назад",
            pt: "há %d min",
            it: "%d min fa"
        ),
        "hour_ago": LocalizedString(
            en: "%d h ago",
            de: "vor %d Std",
            es: "hace %d h",
            fr: "il y a %d h",
            zh: "%d 小时前",
            ja: "%d 時間前",
            ko: "%d시간 전",
            ru: "%d ч назад",
            pt: "há %d h",
            it: "%d h fa"
        ),
        "hours_ago": LocalizedString(
            en: "%d h ago",
            de: "vor %d Std",
            es: "hace %d h",
            fr: "il y a %d h",
            zh: "%d 小时前",
            ja: "%d 時間前",
            ko: "%d시간 전",
            ru: "%d ч. назад",
            pt: "há %d h",
            it: "%d h fa"
        ),
        "day_ago": LocalizedString(
            en: "%d d ago",
            de: "vor %d T",
            es: "hace %d d",
            fr: "il y a %d j",
            zh: "%d 天前",
            ja: "%d 日前",
            ko: "%d일 전",
            ru: "%d дн. назад",
            pt: "há %d d",
            it: "%d gg fa"
        ),
        "days_ago": LocalizedString(
            en: "%d d ago",
            de: "vor %d T",
            es: "hace %d d",
            fr: "il y a %d j",
            zh: "%d 天前",
            ja: "%d 日前",
            ko: "%d일 전",
            ru: "%d дн. назад",
            pt: "há %d d",
            it: "%d gg fa"
        ),
        "menu_show_history": LocalizedString(
            en: "Show History",
            de: "Verlauf anzeigen",
            es: "Mostrar historial",
            fr: "Afficher l'historique",
            zh: "显示历史",
            ja: "履歴を表示",
            ko: "기록 보기",
            ru: "Показать историю",
            pt: "Mostrar histórico",
            it: "Mostra cronologia"
        ),
        "menu_clear_history": LocalizedString(
            en: "Clear History",
            de: "Verlauf löschen",
            es: "Borrar historial",
            fr: "Effacer l'historique",
            zh: "清除历史",
            ja: "履歴を消去",
            ko: "기록 지우기",
            ru: "Очистить историю",
            pt: "Limpar histórico",
            it: "Cancella cronologia"
        ),
        "menu_settings": LocalizedString(
            en: "Settings...",
            de: "Einstellungen...",
            es: "Ajustes...",
            fr: "Réglages...",
            zh: "设置...",
            ja: "設定...",
            ko: "설정...",
            ru: "Настройки...",
            pt: "Configurações...",
            it: "Impostazioni..."
        ),
        "menu_about": LocalizedString(
            en: "About Macboary",
            de: "Über Macboary",
            es: "Acerca de Macboary",
            fr: "À propos de Macboary",
            zh: "关于 Macboary",
            ja: "Macboary について",
            ko: "Macboary 정보",
            ru: "О приложении Macboary",
            pt: "Sobre o Macboary",
            it: "Informazioni su Macboary"
        ),
        "menu_quit": LocalizedString(
            en: "Quit Macboary",
            de: "Macboary beenden",
            es: "Salir de Macboary",
            fr: "Quitter Macboary",
            zh: "退出 Macboary",
            ja: "Macboary を終了",
            ko: "Macboary 종료",
            ru: "Выйти из Macboary",
            pt: "Sair do Macboary",
            it: "Esci da Macboary"
        ),
        "settings_title": LocalizedString(
            en: "Macboary Settings",
            de: "Macboary Einstellungen",
            es: "Ajustes de Macboary",
            fr: "Réglages Macboary",
            zh: "Macboary 设置",
            ja: "Macboary 設定",
            ko: "Macboary 설정",
            ru: "Настройки Macboary",
            pt: "Configurações do Macboary",
            it: "Impostazioni Macboary"
        ),
        "about_title": LocalizedString(
            en: "About Macboary",
            de: "Über Macboary",
            es: "Acerca de Macboary",
            fr: "À propos de Macboary",
            zh: "关于 Macboary",
            ja: "Macboary について",
            ko: "Macboary 정보",
            ru: "О Macboary",
            pt: "Sobre o Macboary",
            it: "Informazioni su Macboary"
        ),
        "alert_clear_title": LocalizedString(
            en: "Clear Clipboard History?",
            de: "Verlauf löschen?",
            es: "¿Borrar historial?",
            fr: "Effacer l'historique ?",
            zh: "清除历史？",
            ja: "履歴を消去しますか？",
            ko: "기록을 지우시겠습니까?",
            ru: "Очистить историю?",
            pt: "Limpar histórico?",
            it: "Cancellare cronologia?"
        ),
        "alert_clear_desc": LocalizedString(
            en: "This will remove items from your clipboard history. This action cannot be undone.",
            de: "Dies wird alle Einträge aus dem Verlauf entfernen. Diese Aktion kann nicht rückgängig gemacht werden.",
            es: "Esto eliminará los elementos de tu historial. Esta acción no se puede deshacer.",
            fr: "Ceci supprimera les éléments de votre historique. Cette action est irréversible.",
            zh: "这将从您的剪贴板历史中移除项目。此操作无法撤销。",
            ja: "クリップボード履歴から項目が削除されます。この操作は取り消せません。",
            ko: "클립보드 기록에서 항목이 제거됩니다. 이 작업은 취소할 수 없습니다。",
            ru: "Это удалит элементы из истории. Действие нельзя отменить.",
            pt: "Isso removerá itens do seu histórico. Esta ação não pode ser desfeita.",
            it: "Questo rimuoverà gli elementi dalla cronologia. Azione irreversibile."
        ),
        "clear": LocalizedString(
            en: "Clear",
            de: "Löschen",
            es: "Borrar",
            fr: "Effacer",
            zh: "清除",
            ja: "消去",
            ko: "지우기",
            ru: "Очистить",
            pt: "Limpar",
            it: "Cancella"
        ),
        "cancel": LocalizedString(
            en: "Cancel",
            de: "Abbrechen",
            es: "Cancelar",
            fr: "Annuler",
            zh: "取消",
            ja: "キャンセル",
            ko: "취소",
            ru: "Отмена",
            pt: "Cancelar",
            it: "Annulla"
        ),
        "clear_pinned": LocalizedString(
            en: "Also clear pinned items",
            de: "Auch angepinnte Einträge löschen",
            es: "Incluir elementos fijados",
            fr: "Inclure les éléments épinglés",
            zh: "包括置顶项",
            ja: "ピン留めされた項目も含む",
            ko: "고정된 항목 포함",
            ru: "Включая закрепленные",
            pt: "Incluir fixados",
            it: "Includi fissati"
        ),
        "general": LocalizedString(
            en: "General",
            de: "Allgemein",
            es: "General",
            fr: "Général",
            zh: "常规",
            ja: "一般",
            ko: "일반",
            ru: "Основные",
            pt: "Geral",
            it: "Generale"
        ),
        "appearance": LocalizedString(
            en: "Appearance",
            de: "Erscheinungsbild",
            es: "Apariencia",
            fr: "Apparence",
            zh: "外观",
            ja: "外観",
            ko: "화면 표시",
            ru: "Внешний вид",
            pt: "Aparência",
            it: "Aspetto"
        ),
        "storage": LocalizedString(
            en: "Storage",
            de: "Speicher",
            es: "Almacenamiento",
            fr: "Stockage",
            zh: "存储",
            ja: "ストレージ",
            ko: "저장 공간",
            ru: "Хранилище",
            pt: "Armazenamento",
            it: "Archivio"
        ),
        "shortcuts": LocalizedString(
            en: "Shortcuts",
            de: "Kurzbefehle",
            es: "Atajos",
            fr: "Raccourcis",
            zh: "快捷键",
            ja: "ショートカット",
            ko: "단축키",
            ru: "Сокращения",
            pt: "Atalhos",
            it: "Scorciatoie"
        ),
        "permissions": LocalizedString(
            en: "Permissions",
            de: "Berechtigungen",
            es: "Permisos",
            fr: "Permissions",
            zh: "权限",
            ja: "権限",
            ko: "권한",
            ru: "Разрешения",
            pt: "Permissões",
            it: "Permessi"
        ),
        "about": LocalizedString(
            en: "About",
            de: "Über",
            es: "Acerca de",
            fr: "À propos",
            zh: "关于",
            ja: "詳細",
            ko: "정보",
            ru: "О программе",
            pt: "Sobre",
            it: "Info"
        ),
        "language": LocalizedString(
            en: "Language",
            de: "Sprache",
            es: "Idioma",
            fr: "Langue",
            zh: "语言",
            ja: "言語",
            ko: "언어",
            ru: "Язык",
            pt: "Idioma",
            it: "Lingua"
        ),
        "launch_login": LocalizedString(
            en: "Launch at login",
            de: "Beim Anmelden starten",
            es: "Abrir al iniciar sesión",
            fr: "Lancer au démarrage",
            zh: "登录时启动",
            ja: "ログイン時に起動",
            ko: "로그인 시 실행",
            ru: "Запускать при входе",
            pt: "Iniciar no login",
            it: "Apri all'avvio"
        ),
        "show_dock": LocalizedString(
            en: "Show in Dock",
            de: "Im Dock anzeigen",
            es: "Mostrar en el Dock",
            fr: "Afficher dans le Dock",
            zh: "在程序坞显示",
            ja: "Dock に表示",
            ko: "Dock에 표시",
            ru: "Показать в Dock",
            pt: "Mostrar no Dock",
            it: "Mostra nel Dock"
        ),
        "show_dock_desc": LocalizedString(
            en: "If disabled, app runs in menu bar only",
            de: "Wenn deaktiviert, läuft die App nur in der Menüleiste",
            es: "Solo barra de menú si está desactivado",
            fr: "Uniquement barre des menus si désactivé",
            zh: "禁用后仅在菜单栏运行",
            ja: "無効にするとメニューバーのみで実行",
            ko: "비활성화 시 메뉴 막대에서만 실행",
            ru: "Только меню, если отключено",
            pt: "Só menu se desativado",
            it: "Solo menu se disabilitato"
        ),
        "window_position": LocalizedString(
            en: "Window Position",
            de: "Fensterposition",
            es: "Posición de ventana",
            fr: "Position de la fenêtre",
            zh: "窗口位置",
            ja: "ウィンドウ位置",
            ko: "창 위치",
            ru: "Положение окна",
            pt: "Posição da janela",
            it: "Posizione finestra"
        ),
        "quit": LocalizedString(
            en: "Quit Macboary",
            de: "Macboary beenden",
            es: "Salir de Macboary",
            fr: "Quitter Macboary",
            zh: "退出 Macboary",
            ja: "Macboary を終了",
            ko: "Macboary 종료",
            ru: "Выйти из Macboary",
            pt: "Sair do Macboary",
            it: "Esci da Macboary"
        ),
        "quick_paste": LocalizedString(
            en: "Enable Quick Paste Shortcuts",
            de: "Quick Paste Kurzbefehle aktivieren",
            es: "Activar atajos de pegado rápido",
            fr: "Raccourcis de collage rapide",
            zh: "启用快速粘贴快捷键",
            ja: "クイック貼り付けを有効化",
            ko: "빠른 붙여넣기 단축키",
            ru: "Быстрая вставка",
            pt: "Atalhos de colagem rápida",
            it: "Scorciatoie incolla rapido"
        ),
        "quick_paste_desc": LocalizedString(
            en: "Use ⌘1-9 to paste the first 9 items",
            de: "Nutze ⌘1-9 zum Einfügen der ersten 9 Elemente",
            es: "Usa ⌘1-9 para pegar los primeros 9 elementos",
            fr: "Utilisez ⌘1-9 pour coller les 9 premiers éléments",
            zh: "使用 ⌘1-9 粘贴前 9 项",
            ja: "⌘1-9 で最初の 9 項目を貼り付け",
            ko: "⌘1-9를 사용하여 처음 9개 항목 붙여넣기",
            ru: "Используйте ⌘1-9 для вставки",
            pt: "Use ⌘1-9 para colar os primeiros 9 itens",
            it: "Usa ⌘1-9 per incollare i primi 9 elementi"
        ),
        "global_hotkey": LocalizedString(
            en: "Global Hotkey",
            de: "Globaler Kurzbefehl",
            es: "Atajo global",
            fr: "Raccourci global",
            zh: "全局快捷键",
            ja: "グローバルホットキー",
            ko: "전역 단축키",
            ru: "Глобальная клавиша",
            pt: "Atalho global",
            it: "Scorciatoia globale"
        ),
        "reset_default": LocalizedString(
            en: "Reset to Default (⌘⇧V)",
            de: "Standard wiederherstellen (⌘⇧V)",
            es: "Restablecer (⌘⇧V)",
            fr: "Rétablir (⌘⇧V)",
            zh: "恢复默认 (⌘⇧V)",
            ja: "デフォルトに戻す (⌘⇧V)",
            ko: "초기화 (⌘⇧V)",
            ru: "Сброс (⌘⇧V)",
            pt: "Redefinir (⌘⇧V)",
            it: "Ripristina (⌘⇧V)"
        ),
        "accessibility_access": LocalizedString(
            en: "Accessibility Access",
            de: "Bedienungshilfen-Zugriff",
            es: "Acceso de accesibilidad",
            fr: "Accès à l'accessibilité",
            zh: "辅助功能访问",
            ja: "アクセシビリティ",
            ko: "손쉬운 사용 접근",
            ru: "Универсальный доступ",
            pt: "Acessibilidade",
            it: "Accessibilità"
        ),
        "accessibility_desc": LocalizedString(
            en: "Required for automatic paste",
            de: "Erforderlich für automatisches Einfügen",
            es: "Para pegado automático",
            fr: "Pour le collage automatique",
            zh: "自动粘贴所需",
            ja: "自動貼り付けに必要",
            ko: "자동 붙여넣기에 필요",
            ru: "Для авто-вставки",
            pt: "Para colagem automática",
            it: "Per incolla automatico"
        ),
        "keychain_access": LocalizedString(
            en: "Keychain Access",
            de: "Schlüsselbund-Zugriff",
            es: "Acceso a llavero",
            fr: "Accès au trousseau",
            zh: "钥匙串访问",
            ja: "キーチェーン",
            ko: "키체인 접근",
            ru: "Связка ключей",
            pt: "Acesso às chaves",
            it: "Portachiavi"
        ),
        "keychain_desc": LocalizedString(
            en: "Required for encryption key storage",
            de: "Erforderlich für Verschlüsselungsschlüssel-Speicherung",
            es: "Para guardar clave de encriptación",
            fr: "Pour stocker la clé de chiffrement",
            zh: "存储密钥所需",
            ja: "暗号化キー保存に必要",
            ko: "암호화 키 저장에 필요",
            ru: "Для хранения ключа",
            pt: "Para chave de criptografia",
            it: "Per chiave crittografia"
        ),
        "granted": LocalizedString(
            en: "Granted",
            de: "Zugriff erteilt",
            es: "Concedido",
            fr: "Accordé",
            zh: "已授予",
            ja: "許可済み",
            ko: "허용됨",
            ru: "Предоставлено",
            pt: "Concedido",
            it: "Concesso"
        ),
        "denied": LocalizedString(
            en: "Denied",
            de: "Verweigert",
            es: "Denegado",
            fr: "Refusé",
            zh: "已拒绝",
            ja: "拒否",
            ko: "거부됨",
            ru: "Отказано",
            pt: "Negado",
            it: "Negato"
        ),
        "grant_access": LocalizedString(
            en: "Grant Access",
            de: "Zugriff gewähren",
            es: "Conceder acceso",
            fr: "Accorder l'accès",
            zh: "授予访问",
            ja: "アクセス許可",
            ko: "접근 허용",
            ru: "Дать доступ",
            pt: "Conceder acesso",
            it: "Concedi accesso"
        ),
        "permission_granted_notification": LocalizedString(
            en: "Accessibility permission granted! Automatic paste is now enabled.",
            de: "Zugriffsberechtigung erteilt! Automatisches Einfügen ist jetzt aktiviert.",
            es: "¡Permiso concedido! Pegado automático activado.",
            fr: "Permission accordée ! Collage automatique activé.",
            zh: "权限已授予！自动粘贴已启用。",
            ja: "権限が付与されました！自動貼り付けが有効です。",
            ko: "권한 허용됨! 자동 붙여넣기 활성화.",
            ru: "Разрешение получено! Авто-вставка включена.",
            pt: "Permissão concedida! Colagem automática ativada.",
            it: "Permesso concesso! Incolla automatico attivo."
        ),
        "permission_warning": LocalizedString(
            en: "Accessibility permission required for automatic paste.",
            de: "Bedienungshilfen-Zugriff erforderlich für automatisches Einfügen.",
            es: "Se requiere permiso para pegado automático.",
            fr: "Permission requise pour le collage automatique.",
            zh: "自动粘贴需要辅助功能权限。",
            ja: "自動貼り付けには権限が必要です。",
            ko: "자동 붙여넣기를 위해 권한이 필요합니다.",
            ru: "Для авто-вставки нужен доступ.",
            pt: "Permissão necessária para colagem automática.",
            it: "Permesso richiesto per incolla automatico."
        ),
        "keychain_access_title": LocalizedString(
            en: "Keychain Access Required",
            de: "Schlüsselbund-Zugriff erforderlich",
            es: "Acceso a llavero requerido",
            fr: "Accès au trousseau requis",
            zh: "需要钥匙串访问",
            ja: "キーチェーンアクセスが必要",
            ko: "키체인 접근 필요",
            ru: "Нужен доступ к ключам",
            pt: "Acesso às chaves necessário",
            it: "Accesso portachiavi richiesto"
        ),
        "keychain_access_message": LocalizedString(
            en: "Macboary needs access to the Keychain to store the encryption key securely. Encryption will be disabled for now. You can enable it anytime in the settings.",
            de: "Macboary benötigt Zugriff auf den Schlüsselbund, um den Verschlüsselungsschlüssel sicher zu speichern. Die Verschlüsselung wird vorerst deaktiviert. Sie können sie jederzeit in den Einstellungen aktivieren.",
            es: "Macboary necesita acceso al llavero para guardar la clave de seguridad. La encriptación se desactivará por ahora.",
            fr: "Macboary a besoin d'accéder au trousseau pour stocker la clé de sécurité. Le chiffrement est désactivé pour l'instant.",
            zh: "Macboary 需要访问钥匙串以存储密钥。加密暂时禁用。",
            ja: "Macboary はキーを保存するためにキーチェーンへのアクセスを必要とします。暗号化は一時的に無効になります。",
            ko: "Macboary는 키를 저장하기 위해 키체인 접근이 필요합니다. 암호화는 현재 비활성화됩니다.",
            ru: "Macboary нужен доступ к связке ключей. Шифрование пока отключено.",
            pt: "Macboary precisa de acesso às Chaves. A criptografia será desativada por enquanto.",
            it: "Macboary necessita accesso al portachiavi. Crittografia disabilitata per ora."
        ),
        "use_custom_colors": LocalizedString(
            en: "Use Custom Colors",
            de: "Benutzerdefinierte Farben",
            es: "Colores personalizados",
            fr: "Couleurs personnalisées",
            zh: "自定义颜色",
            ja: "カスタムカラー",
            ko: "사용자 지정 색상",
            ru: "Свои цвета",
            pt: "Cores personalizadas",
            it: "Colori personalizzati"
        ),
        "pinned": LocalizedString(
            en: "Show Pin Button",
            de: "Pin-Button anzeigen",
            es: "Mostrar botón fijar",
            fr: "Bouton épingler",
            zh: "显示置顶按钮",
            ja: "ピンボタン表示",
            ko: "고정 버튼 표시",
            ru: "Кнопка закрепить",
            pt: "Botão fixar",
            it: "Pulsante fissa"
        ),
        "center_screen": LocalizedString(
            en: "Center of Screen",
            de: "Bildschirmmitte",
            es: "Centro de pantalla",
            fr: "Centre de l'écran",
            zh: "屏幕中央",
            ja: "画面中央",
            ko: "화면 중앙",
            ru: "Центр экрана",
            pt: "Centro da tela",
            it: "Centro schermo"
        ),
        "mouse_position": LocalizedString(
            en: "At Mouse Position",
            de: "Mausposition",
            es: "Posición del ratón",
            fr: "Position de la souris",
            zh: "鼠标位置",
            ja: "マウス位置",
            ko: "마우스 위치",
            ru: "Позиция мыши",
            pt: "Posição do mouse",
            it: "Posizione mouse"
        ),
        "system": LocalizedString(
            en: "System",
            de: "System",
            es: "Sistema",
            fr: "Système",
            zh: "系统",
            ja: "システム",
            ko: "시스템",
            ru: "Система",
            pt: "Sistema",
            it: "Sistema"
        ),
        "light": LocalizedString(
            en: "Light",
            de: "Hell",
            es: "Claro",
            fr: "Clair",
            zh: "浅色",
            ja: "ライト",
            ko: "라이트",
            ru: "Светлая",
            pt: "Claro",
            it: "Chiaro"
        ),
        "dark": LocalizedString(
            en: "Dark",
            de: "Dunkel",
            es: "Oscuro",
            fr: "Sombre",
            zh: "深色",
            ja: "ダーク",
            ko: "다크",
            ru: "Темная",
            pt: "Escuro",
            it: "Scuro"
        ),
        "theme": LocalizedString(
            en: "Theme",
            de: "Thema",
            es: "Tema",
            fr: "Thème",
            zh: "主题",
            ja: "テーマ",
            ko: "테마",
            ru: "Тема",
            pt: "Tema",
            it: "Tema"
        ),
        "accent_color": LocalizedString(
            en: "Accent Color",
            de: "Akzentfarbe",
            es: "Color de acento",
            fr: "Couleur d'accentuation",
            zh: "强调色",
            ja: "アクセントカラー",
            ko: "강조 색상",
            ru: "Цвет акцента",
            pt: "Cor de destaque",
            it: "Colore accento"
        ),
        "background_color": LocalizedString(
            en: "Background Color",
            de: "Hintergrundfarbe",
            es: "Color de fondo",
            fr: "Couleur de fond",
            zh: "背景颜色",
            ja: "背景色",
            ko: "배경 색상",
            ru: "Цвет фона",
            pt: "Cor de fundo",
            it: "Colore sfondo"
        ),
        "secondary_color": LocalizedString(
            en: "Secondary Color",
            de: "Sekundärfarbe",
            es: "Color secundario",
            fr: "Couleur secondaire",
            zh: "次要颜色",
            ja: "セカンダリカラー",
            ko: "보조 색상",
            ru: "Вторичный цвет",
            pt: "Cor secundária",
            it: "Colore secondario"
        ),
        "secondary_color_desc": LocalizedString(
            en: "Secondary color is used for search bar and footer",
            de: "Sekundärfarbe wird für Suchleiste und Fußzeile verwendet",
            es: "Color para búsqueda y pie de página",
            fr: "Pour la recherche et le pied de page",
            zh: "用于搜索栏和页脚",
            ja: "検索バーとフッターに使用",
            ko: "검색 창과 바닥글에 사용",
            ru: "Для поиска и футера",
            pt: "Para pesquisa e rodapé",
            it: "Per ricerca e piè di pagina"
        ),
        "about_tagline": LocalizedString(
            en: "Clipboard History Manager",
            de: "Zwischenablage-Manager",
            es: "Gestor de portapapeles",
            fr: "Gestionnaire de presse-papiers",
            zh: "剪贴板管理器",
            ja: "クリップボードマネージャー",
            ko: "클립보드 관리자",
            ru: "Менеджер буфера обмена",
            pt: "Gerenciador de transferência",
            it: "Gestore appunti"
        ),
        "about_desc": LocalizedString(
            en: "A lightweight clipboard history manager",
            de: "Ein leichter Verlauf für die Zwischenablage",
            es: "Gestor de historial ligero",
            fr: "Gestionnaire d'historique léger",
            zh: "轻量级剪贴板历史",
            ja: "軽量なクリップボード履歴",
            ko: "가벼운 클립보드 기록",
            ru: "Легкий менеджер истории",
            pt: "Gerenciador de histórico leve",
            it: "Gestore cronologia leggero"
        ),
        "version": LocalizedString(
            en: "Version %@ (%@)",
            de: "Version %@ (%@)",
            es: "Versión %@ (%@)",
            fr: "Version %@ (%@)",
            zh: "版本 %@ (%@)",
            ja: "バージョン %@ (%@)",
            ko: "버전 %@ (%@)",
            ru: "Версия %@ (%@)",
            pt: "Versão %@ (%@)",
            it: "Versione %@ (%@)"
        ),
        "store_images": LocalizedString(
            en: "Store Images",
            de: "Bilder speichern",
            es: "Guardar imágenes",
            fr: "Enregistrer images",
            zh: "存储图片",
            ja: "画像を保存",
            ko: "이미지 저장",
            ru: "Сохранять изображения",
            pt: "Salvar imagens",
            it: "Salva immagini"
        ),
        "store_images_desc": LocalizedString(
            en: "Save copied images to history",
            de: "Kopierte Bilder im Verlauf speichern",
            es: "Guardar imágenes en historial",
            fr: "Sauvegarder les images dans l'historique",
            zh: "保存图片到历史",
            ja: "画像を履歴に保存",
            ko: "이미지를 기록에 저장",
            ru: "Сохранять изображения в истории",
            pt: "Salvar imagens no histórico",
            it: "Salva immagini nella cronologia"
        ),
        "text_retention": LocalizedString(
            en: "Text Retention",
            de: "Text-Aufbewahrung",
            es: "Retención de texto",
            fr: "Rétention de texte",
            zh: "文本保留",
            ja: "テキスト保持",
            ko: "텍스트 보관",
            ru: "Хранение текста",
            pt: "Retenção de texto",
            it: "Ritenzione testo"
        ),
        "image_retention": LocalizedString(
            en: "Image Retention",
            de: "Bild-Aufbewahrung",
            es: "Retención de imagen",
            fr: "Rétention d'image",
            zh: "图片保留",
            ja: "画像保持",
            ko: "이미지 보관",
            ru: "Хранение изображений",
            pt: "Retenção de imagem",
            it: "Ritenzione immagini"
        ),
        "max_history_items": LocalizedString(
            en: "History Limit",
            de: "Verlaufs-Limit",
            es: "Límite de historial",
            fr: "Limite d'historique",
            zh: "历史限制",
            ja: "履歴の上限",
            ko: "기록 한도",
            ru: "Лимит истории",
            pt: "Limite do histórico",
            it: "Limite cronologia"
        ),
        "retention": LocalizedString(
            en: "Retention",
            de: "Aufbewahrung",
            es: "Retención",
            fr: "Rétention",
            zh: "保留",
            ja: "保持",
            ko: "보관",
            ru: "Хранение",
            pt: "Retenção",
            it: "Ritenzione"
        ),
        "keep_text": LocalizedString(
            en: "Keep text for",
            de: "Text behalten für",
            es: "Mantener texto",
            fr: "Garder le texte",
            zh: "保留文本",
            ja: "テキスト保持",
            ko: "텍스트 보관",
            ru: "Хранить текст",
            pt: "Manter texto",
            it: "Mantieni testo"
        ),
        "keep_images": LocalizedString(
            en: "Keep images for",
            de: "Bilder behalten für",
            es: "Mantener imágenes",
            fr: "Garder les images",
            zh: "保留图片",
            ja: "画像保持",
            ko: "이미지 보관",
            ru: "Хранить изображения",
            pt: "Manter imagens",
            it: "Mantieni immagini"
        ),
        "days": LocalizedString(
            en: "days",
            de: "Tage",
            es: "días",
            fr: "jours",
            zh: "天",
            ja: "日",
            ko: "일",
            ru: "дн.",
            pt: "dias",
            it: "giorni"
        ),
        "forever": LocalizedString(
            en: "Forever",
            de: "Für immer",
            es: "Para siempre",
            fr: "Toujours",
            zh: "永久",
            ja: "無期限",
            ko: "영구",
            ru: "Всегда",
            pt: "Para sempre",
            it: "Per sempre"
        ),
        "disabled": LocalizedString(
            en: "Disabled",
            de: "Deaktiviert",
            es: "Desactivado",
            fr: "Désactivé",
            zh: "已禁用",
            ja: "無効",
            ko: "사용 안 함",
            ru: "Отключено",
            pt: "Desativado",
            it: "Disabilitato"
        ),
        "encrypt_clipboard": LocalizedString(
            en: "Encrypt Clipboard History",
            de: "Zwischenablage verschlüsseln",
            es: "Encriptar historial",
            fr: "Chiffrer l'historique",
            zh: "加密剪贴板历史",
            ja: "履歴を暗号化",
            ko: "기록 암호화",
            ru: "Шифровать историю",
            pt: "Criptografar histórico",
            it: "Cripta cronologia"
        ),
        "encrypt_clipboard_desc": LocalizedString(
            en: "Uses AES-256 encryption to protect sensitive data",
            de: "Verwendet AES-256-Verschlüsselung zum Schutz sensibler Daten",
            es: "Encriptación AES-256 para proteger datos",
            fr: "Chiffrement AES-256 pour protéger les données",
            zh: "使用 AES-256 加密保护数据",
            ja: "AES-256 暗号化でデータを保護",
            ko: "AES-256 암호화로 데이터 보호",
            ru: "Шифрование AES-256 для защиты",
            pt: "Criptografia AES-256 para proteger dados",
            it: "Crittografia AES-256 per proteggere i dati"
        ),
        "encrypt_opt_in_title": LocalizedString(
            en: "Enable Clipboard Encryption?",
            de: "Zwischenablage-Verschlüsselung aktivieren?",
            es: "¿Activar encriptación?",
            fr: "Activer le chiffrement ?",
            zh: "启用加密？",
            ja: "暗号化を有効化？",
            ko: "암호화 활성화?",
            ru: "Включить шифрование?",
            pt: "Ativar criptografia?",
            it: "Abilitare crittografia?"
        ),
        "encrypt_opt_in_message": LocalizedString(
            en: "Macboary can encrypt your clipboard history to protect sensitive information like passwords and credit cards.\n\nEncryption is optional but recommended for enhanced security. You can change this later in Settings.",
            de: "Macboary kann Ihren Zwischenablage-Verlauf verschlüsseln, um sensible Informationen wie Passwörter und Kreditkarten zu schützen.\n\nVerschlüsselung ist optional, aber für erhöhte Sicherheit empfohlen. Sie können dies später in den Einstellungen ändern.",
            es: "Macboary puede encriptar tu historial para proteger información sensible.\n\nLa encriptación es opcional pero recomendada.",
            fr: "Macboary peut chiffrer votre historique pour protéger les informations sensibles.\n\nLe chiffrement est optionnel mais recommandé.",
            zh: "Macboary 可以加密您的历史记录以保护敏感信息。\n\n加密是可选的，但建议启用。",
            ja: "Macboary は履歴を暗号化して機密情報を保護できます。\n\n暗号化はオプションですが、推奨されます。",
            ko: "Macboary는 기록을 암호화하여 정보를 보호할 수 있습니다.\n\n암호화는 선택 사항이지만 권장됩니다.",
            ru: "Macboary может зашифровать историю для защиты данных.\n\nШифрование рекомендуется.",
            pt: "Macboary pode criptografar seu histórico para proteger informações.\n\nA criptografia é recomendada.",
            it: "Macboary può criptare la cronologia per proteggere i dati.\n\nLa crittografia è consigliata."
        ),
        "encrypt_opt_in_enable": LocalizedString(
            en: "Enable Encryption",
            de: "Verschlüsselung aktivieren",
            es: "Activar encriptación",
            fr: "Activer chiffrement",
            zh: "启用加密",
            ja: "暗号化を有効化",
            ko: "암호화 활성화",
            ru: "Включить",
            pt: "Ativar criptografia",
            it: "Abilita crittografia"
        ),
        "encrypt_opt_in_disable": LocalizedString(
            en: "Skip",
            de: "Überspringen",
            es: "Omitir",
            fr: "Ignorer",
            zh: "跳过",
            ja: "スキップ",
            ko: "건너뛰기",
            ru: "Пропустить",
            pt: "Pular",
            it: "Salta"
        ),
        "accessibility_info_title": LocalizedString(
            en: "Accessibility Permission Required",
            de: "Zugriffsberechtigung erforderlich",
            es: "Permiso de accesibilidad",
            fr: "Permission d'accessibilité",
            zh: "需辅助功能权限",
            ja: "アクセシビリティ権限",
            ko: "접근성 권한 필요",
            ru: "Нужен доступ",
            pt: "Permissão necessária",
            it: "Permesso richiesto"
        ),
        "accessibility_info_message": LocalizedString(
            en: "Macboary needs Accessibility permission for automatic paste functionality.\n\nPlease grant permission in the next dialog.",
            de: "Macboary benötigt Zugriff auf die Bedienungshilfen für die automatische Einfügefunktion.\n\nBitte gewähren Sie Zugriff im nächsten Dialog.",
            es: "Macboary necesita permiso de accesibilidad para pegar automáticamente.\n\nPor favor, concede el permiso.",
            fr: "Macboary a besoin de la permission d'accessibilité pour le collage automatique.\n\nVeuillez accorder la permission.",
            zh: "Macboary 需要辅助功能权限以自动粘贴。\n\n请授予权限。",
            ja: "Macboary は自動貼り付けのためにアクセシビリティ権限を必要とします。\n\n許可してください。",
            ko: "Macboary는 자동 붙여넣기를 위해 권한이 필요합니다.\n\n권한을 허용해 주세요.",
            ru: "Macboary нужен доступ для авто-вставки.\n\nПожалуйста, предоставьте доступ.",
            pt: "Macboary precisa de permissão para colagem automática.\n\nPor favor, conceda.",
            it: "Macboary necessita del permesso per l'incolla automatico.\n\nPer favore, concedi il permesso."
        )
    ]
}
