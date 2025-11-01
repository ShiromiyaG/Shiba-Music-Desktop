import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: updateDialog
    title: "Update Available"
    modal: true
    anchors.centerIn: parent
    width: Math.min(500, parent.width - 40)
    
    Material.roundedScale: Material.MediumScale

    required property var updateChecker

    ColumnLayout {
        width: parent.width
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 48
                height: 48
                radius: 24
                color: Material.color(Material.Blue)

                Label {
                    anchors.centerIn: parent
                    text: "🎉"
                    font.pixelSize: 24
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "New Version Available"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Label {
                    text: "Version " + updateChecker.latestVersion
                    font.pixelSize: 14
                    opacity: 0.7
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Material.dividerColor
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            clip: true

            Label {
                width: updateDialog.width - 48
                text: updateChecker.releaseNotes || "No release notes available."
                wrapMode: Text.Wrap
                font.pixelSize: 13
                lineHeight: 1.4
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            visible: updateChecker.isDownloading
            value: updateChecker.downloadProgress / 100
            
            Label {
                anchors.centerIn: parent
                text: updateChecker.downloadProgress + "%"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Material.foreground
            }
        }

        Label {
            Layout.fillWidth: true
            visible: updateChecker.isDownloading
            text: "Downloading update..."
            font.pixelSize: 12
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "Later"
            flat: true
            enabled: !updateChecker.isDownloading
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }

        Button {
            text: updateChecker.isDownloading ? "Downloading..." : "Download & Install"
            enabled: !updateChecker.isDownloading
            Material.background: Material.Blue
            Material.foreground: "white"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
    }

    onAccepted: {
        updateChecker.downloadAndInstall()
    }

    onRejected: {
        updateChecker.ignoreUpdate()
    }

    Connections {
        target: updateChecker

        function onUpdateCheckFailed(error) {
            console.log("Update check failed:", error)
        }

        function onDownloadFailed(error) {
            errorDialog.errorMessage = error
            errorDialog.open()
            updateDialog.close()
        }
    }

    Dialog {
        id: errorDialog
        title: "Update Failed"
        modal: true
        anchors.centerIn: parent
        width: Math.min(400, parent.width - 40)

        property string errorMessage: ""

        Material.roundedScale: Material.MediumScale

        ColumnLayout {
            width: parent.width
            spacing: 16

            Label {
                Layout.fillWidth: true
                text: errorDialog.errorMessage
                wrapMode: Text.Wrap
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "OK"
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
    }
}
