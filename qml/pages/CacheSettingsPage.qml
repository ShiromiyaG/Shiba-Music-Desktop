import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    Components.ThemePalette { id: theme }
    id: cacheSettingsPage
    
    background: Rectangle {
        color: "transparent"
    }
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: theme.paddingPanel
        
        ColumnLayout {
            width: parent.width - theme.paddingPanel * 2
            spacing: theme.spacing3xl
            
            // Header
            Label {
                text: qsTr("Cache Settings")
                font.pixelSize: theme.fontSizeHero
                font.weight: Font.Bold
                color: theme.textPrimary
            }
            
            // Cache Statistics
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: statsColumn.implicitHeight + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder
                border.width: 1
                
                ColumnLayout {
                    id: statsColumn
                    anchors.fill: parent
                    anchors.margins: theme.paddingCard
                    spacing: theme.spacingLg
                    
                    Label {
                        text: qsTr("Cache Statistics")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }
                    
                    GridLayout {
                        columns: 2
                        rowspacing: theme.spacingMd
                        columnspacing: theme.spacingXl
                        Layout.fillWidth: true
                        
                        Label {
                            text: qsTr("Total Size:")
                            color: theme.textSecondary
                        }
                        Label {
                            id: cacheSizeLabel
                            text: formatBytes(cacheManager ? cacheManager.getCacheSize() : 0)
                            color: theme.textPrimary
                            font.weight: Font.Medium
                        }
                        
                        Label {
                            text: qsTr("Cached Images:")
                            color: theme.textSecondary
                        }
                        Label {
                            id: imageCountLabel
                            text: cacheManager ? cacheManager.getImageCount() : "0"
                            color: theme.textPrimary
                            font.weight: Font.Medium
                        }
                    }
                    
                    Button {
                        text: qsTr("Refresh Stats")
                        Layout.preferredWidth: 150
                        onClicked: {
                            cacheSizeLabel.text = formatBytes(cacheManager.getCacheSize())
                            imageCountLabel.text = cacheManager.getImageCount()
                        }
                    }
                }
            }
            
            // Cache Management Actions
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: actionsColumn.implicitHeight + theme.spacing4xl
                radius: theme.radiusCard
                color: theme.cardBackground
                border.color: theme.cardBorder
                border.width: 1
                
                ColumnLayout {
                    id: actionsColumn
                    anchors.fill: parent
                    anchors.margins: theme.paddingCard
                    spacing: theme.spacingXl
                    
                    Label {
                        text: qsTr("Cache Management")
                        font.pixelSize: theme.fontSizeSection
                        font.weight: Font.DemiBold
                        color: theme.textPrimary
                    }
                    
                    Button {
                        text: qsTr("Clear Old Images (30+ days)")
                        Layout.fillWidth: true
                        onClicked: {
                            cacheManager.clearImageCache(30)
                            cacheSizeLabel.text = formatBytes(cacheManager.getCacheSize())
                            imageCountLabel.text = cacheManager.getImageCount()
                        }
                    }
                    
                    Button {
                        text: qsTr("Clear Old Metadata (7+ days)")
                        Layout.fillWidth: true
                        onClicked: {
                            cacheManager.clearMetadataCache(7)
                        }
                    }
                    
                    Button {
                        text: qsTr("Clear All Lists Cache")
                        Layout.fillWidth: true
                        onClicked: {
                            cacheManager.clearListCache()
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: theme.cardBorder
                    }
                    
                    Button {
                        text: qsTr("Clear All Cache")
                        Layout.fillWidth: true
                        highlighted: true
                        Material.background: Material.Red
                        onClicked: clearAllDialog.open()
                    }
                }
            }
            
            Item {
                Layout.fillHeight: true
            }
        }
    }
    
    // Confirm dialog for clearing all cache
    Dialog {
        id: clearAllDialog
        anchors.centerIn: parent
        title: qsTr("Clear All Cache?")
        standardButtons: Dialog.Yes | Dialog.No
        
        Label {
            text: qsTr("This will delete all cached images and metadata. Are you sure?")
            wrapMode: Text.WordWrap
        }
        
        onAccepted: {
            cacheManager.clearAllCache()
            cacheSizeLabel.text = formatBytes(0)
            imageCountLabel.text = "0"
        }
    }
    
    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        const k = 1024
        const sizes = ["B", "KB", "MB", "GB"]
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i]
    }
}












