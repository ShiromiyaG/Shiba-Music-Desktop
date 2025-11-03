import QtQuick

QtObject {
    id: root

    property var manager: themeManager

    property var defaultPalette: ({
        themeId: "material",
        isDark: true,
        windowBackgroundStart: "#141926",
        windowBackgroundEnd: "#0c0f18",
        windowBackgroundFallback: "#11141a",
        surface: "#181d2b",
        surfaceBorder: "#1f2536",
        surfaceElevated: "#1b2031",
        surfaceElevatedBorder: "#232a3f",
        surfaceInteractive: "#1f2937",
        surfaceInteractiveBorder: "#374151",
        textPrimary: "#f5f7ff",
        textSecondary: "#a0aac6",
        textMuted: "#8fa0c2",
        accent: "#7c4dff",
        accentDark: "#5b3cc4",
        accentLight: "#a48cff",
        toolbarBackground: "#141926",
        listItem: "#1b2336",
        listItemAlternate: "#182030",
        listItemHover: "#273040",
        listItemActive: "#2d3a54",
        cardBackground: "#1d2332",
        cardBorder: "#252e42",
        divider: "#252e42",
        shadow: "#05060a",
        fontFamily: "Inter",
        fontSizeCaption: 12,
        fontSizeBody: 14,
        fontSizeSmall: 13,
        fontSizeExtraSmall: 11,
        fontSizeSubtitle: 15,
        fontSizeTitle: 16,
        fontSizeHeading: 20,
        fontSizeDisplay: 26,
        iconSizeSmall: 16,
        iconSizeMedium: 20,
        iconSizeLarge: 24,
        spacingXs: 4,
        spacingSm: 6,
        spacingMd: 8,
        spacingLg: 12,
        spacingXl: 16,
        spacing2xl: 18,
        spacing3xl: 24,
        spacing4xl: 32,
        paddingCard: 16,
        paddingPanel: 24,
        paddingPage: 32,
        paddingFieldHorizontal: 16,
        paddingFieldVertical: 10,
        opacityDisabled: 0.35,
        borderWidthThin: 1,
        radiusNone: 0,
        radiusBadge: 4,
        radiusChip: 8,
        radiusButton: 12,
        radiusCard: 16,
        radiusInput: 18,
        radiusPanel: 24,
        radiusDialog: 24,
        radiusAvatar: 26,
        radiusQueueHero: 80,
        radiusSliderGroove: 3.5,
        radiusSliderHandle: 7,
        radiusProgress: 4,
        radiusPill: 20,
        radiusPillLarge: 26,
        queueItemHeight: 64,
        queueArtworkSize: 40,
        placeholderTextWidth: 360
    })

    readonly property var palette: {
        var result = {}
        var base = defaultPalette
        for (var key in base)
            result[key] = base[key]
        var source = (manager && manager.palette) ? manager.palette : null
        if (source) {
            for (var sKey in source) {
                result[sKey] = source[sKey]
            }
        }
        return result
    }

    readonly property string themeId: palette.themeId || "material"
    readonly property bool isDark: palette.isDark === undefined ? true : palette.isDark
    readonly property bool isMaterial: themeId === "material"
    readonly property bool isMica: themeId === "mica"
    readonly property bool isGtk: themeId === "gtk"

    readonly property color windowBackgroundStart: color("windowBackgroundStart")
    readonly property color windowBackgroundEnd: color("windowBackgroundEnd")
    readonly property color windowBackgroundFallback: color("windowBackgroundFallback")
    readonly property color surface: color("surface")
    readonly property color surfaceBorder: color("surfaceBorder")
    readonly property color surfaceElevated: color("surfaceElevated")
    readonly property color surfaceElevatedBorder: color("surfaceElevatedBorder")
    readonly property color surfaceInteractive: color("surfaceInteractive")
    readonly property color surfaceInteractiveBorder: color("surfaceInteractiveBorder")
    readonly property color textPrimary: color("textPrimary")
    readonly property color textSecondary: color("textSecondary")
    readonly property color textMuted: color("textMuted")
    readonly property color accent: color("accent")
    readonly property color accentDark: color("accentDark")
    readonly property color accentLight: color("accentLight")
    readonly property color toolbarBackground: color("toolbarBackground")
    readonly property color listItem: color("listItem")
    readonly property color listItemAlternate: color("listItemAlternate")
    readonly property color listItemHover: color("listItemHover")
    readonly property color listItemActive: color("listItemActive")
    readonly property color cardBackground: color("cardBackground")
    readonly property color cardBorder: color("cardBorder")
    readonly property color divider: color("divider")
    readonly property color shadow: color("shadow")

    readonly property string fontFamily: text("fontFamily")
    readonly property real fontSizeCaption: metric("fontSizeCaption", 12)
    readonly property real fontSizeBody: metric("fontSizeBody", 14)
    readonly property real fontSizeSmall: metric("fontSizeSmall", 13)
    readonly property real fontSizeExtraSmall: metric("fontSizeExtraSmall", 11)
    readonly property real fontSizeSubtitle: metric("fontSizeSubtitle", 15)
    readonly property real fontSizeTitle: metric("fontSizeTitle", 16)
    readonly property real fontSizeHeading: metric("fontSizeHeading", 20)
    readonly property real fontSizeDisplay: metric("fontSizeDisplay", 26)

    readonly property real iconSizeSmall: metric("iconSizeSmall", 16)
    readonly property real iconSizeMedium: metric("iconSizeMedium", 20)
    readonly property real iconSizeLarge: metric("iconSizeLarge", 24)

    readonly property real spacingXs: metric("spacingXs", 4)
    readonly property real spacingSm: metric("spacingSm", 6)
    readonly property real spacingMd: metric("spacingMd", 8)
    readonly property real spacingLg: metric("spacingLg", 12)
    readonly property real spacingXl: metric("spacingXl", 16)
    readonly property real spacing2xl: metric("spacing2xl", 18)
    readonly property real spacing3xl: metric("spacing3xl", 24)
    readonly property real spacing4xl: metric("spacing4xl", 32)

    readonly property real paddingCard: metric("paddingCard", 16)
    readonly property real paddingPanel: metric("paddingPanel", 24)
    readonly property real paddingPage: metric("paddingPage", 32)
    readonly property real paddingFieldHorizontal: metric("paddingFieldHorizontal", 16)
    readonly property real paddingFieldVertical: metric("paddingFieldVertical", 10)
    readonly property real queueItemHeight: metric("queueItemHeight", 64)
    readonly property real queueArtworkSize: metric("queueArtworkSize", 40)
    readonly property real placeholderTextWidth: metric("placeholderTextWidth", 360)

    readonly property real opacityDisabled: metric("opacityDisabled", 0.35)
    readonly property real borderWidthThin: metric("borderWidthThin", 1)

    readonly property real radiusNone: metric("radiusNone", 0)
    readonly property real radiusBadge: metric("radiusBadge", 4)
    readonly property real radiusChip: metric("radiusChip", 8)
    readonly property real radiusButton: metric("radiusButton", 12)
    readonly property real radiusCard: metric("radiusCard", 16)
    readonly property real radiusInput: metric("radiusInput", 18)
    readonly property real radiusPanel: metric("radiusPanel", 24)
    readonly property real radiusDialog: metric("radiusDialog", 24)
    readonly property real radiusAvatar: metric("radiusAvatar", 26)
    readonly property real radiusQueueHero: metric("radiusQueueHero", 80)
    readonly property real radiusSliderGroove: metric("radiusSliderGroove", 3.5)
    readonly property real radiusSliderHandle: metric("radiusSliderHandle", 7)
    readonly property real radiusProgress: metric("radiusProgress", 4)
    readonly property real radiusPill: metric("radiusPill", 20)
    readonly property real radiusPillLarge: metric("radiusPillLarge", 26)

    function color(role) {
        if (!palette || !role)
            return "#000000"
        if (palette.hasOwnProperty(role))
            return palette[role]
        if (defaultPalette.hasOwnProperty(role))
            return defaultPalette[role]
        return "#000000"
    }

    function raw(role) {
        if (!palette || !role)
            return undefined
        if (palette.hasOwnProperty(role))
            return palette[role]
        if (defaultPalette.hasOwnProperty(role))
            return defaultPalette[role]
        return undefined
    }

    function text(role, fallback) {
        var value = raw(role)
        if (value === undefined || value === null)
            return fallback === undefined ? "" : fallback
        return "" + value
    }

    function metric(role, fallback) {
        var value = raw(role)
        if (value === undefined || value === null) {
            return fallback === undefined ? 0 : fallback
        }
        if (typeof value === "number")
            return value
        var numeric = Number(value)
        if (!isNaN(numeric))
            return numeric
        if (typeof value === "boolean")
            return value ? 1 : 0
        return fallback === undefined ? 0 : fallback
    }
}
