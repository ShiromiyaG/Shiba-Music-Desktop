import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: cacheSettingsPage
    
    background: Rectangle {
        color: "transparent"
    }
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: 24
        
        ColumnLayout {
            width: parent.width - 48
            spacing: 24
            
            // Header
            Label {
                text: qsTr("Cache Settings")
                font.pixelSize: 32
                font.weight: Font.Bold
                color: "#f5f7ff"
            }
            
            // Cache Statistics
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: statsColumn.implicitHeight + 32
                radius: 16
                color: "#1a1f2e"
                border.color: "#252d42"
                border.width: 1
                
                ColumnLayout {
                    id: statsColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    Label {
                        text: qsTr("Cache Statistics")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        color: "#f5f7ff"
                    }
                    
                    GridLayout {
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 16
                        Layout.fillWidth: true
                        
                        Label {
                            text: qsTr("Total Size:")
                            color: "#a0aac6"
                        }
                        Label {
                            id: cacheSizeLabel
                            text: formatBytes(cacheManager ? cacheManager.getCacheSize() : 0)
                            color: "#f5f7ff"
                            font.weight: Font.Medium
                        }
                        
                        Label {
                            text: qsTr("Cached Images:")
                            color: "#a0aac6"
                        }
                        Label {
                            id: imageCountLabel
                            text: cacheManager ? cacheManager.getImageCount() : "0"
                            color: "#f5f7ff"
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
                Layout.preferredHeight: actionsColumn.implicitHeight + 32
                radius: 16
                color: "#1a1f2e"
                border.color: "#252d42"
                border.width: 1
                
                ColumnLayout {
                    id: actionsColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    
                    Label {
                        text: qsTr("Cache Management")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        color: "#f5f7ff"
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
                        color: "#252d42"
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
