import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: updateDialog
    title: qsTr(qsTr("Update Available"))
    modal: true
    anchors.centerIn: parent
    width: Math.min(500, parent.width - 40)
    
    Material.roundedScale: Material.MediumScale

    property var checker: null

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
                    text: qsTr(qsTr("New Version Available"))
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Label {
                    text: checker ? "Version " + checker.latestVersion : ""
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
                text: checker ? (checker.releaseNotes || "No release notes available.") : ""
                wrapMode: Text.Wrap
                font.pixelSize: 13
                lineHeight: 1.4
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            visible: checker ? checker.isDownloading : false
            value: checker ? checker.downloadProgress / 100 : 0
            
            Label {
                anchors.centerIn: parent
                text: checker ? checker.downloadProgress + "%" : ""
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Material.foreground
            }
        }

        Label {
            Layout.fillWidth: true
            visible: checker ? checker.isDownloading : false
            text: qsTr("Downloading update...")
            font.pixelSize: 12
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
        }
    }

    footer: DialogButtonBox {
        Button {
            text: qsTr(qsTr("Later"))
            flat: true
            enabled: checker ? !checker.isDownloading : true
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }

        Button {
            text: checker ? (checker.isDownloading ? qsTr(qsTr("Downloading...")) : qsTr(qsTr("Download & Install"))) : qsTr(qsTr("Download & Install"))
            enabled: checker ? !checker.isDownloading : false
            Material.background: Material.Blue
            Material.foreground: "white"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
    }

    onAccepted: {
        if (checker) {
            checker.downloadAndInstall()
        }
    }

    onRejected: {
        if (checker) {
            checker.ignoreUpdate()
        }
    }

    Connections {
        target: checker

        function onUpdateCheckFailed(error) {

        }

        function onDownloadFailed(error) {
            errorDialog.errorMessage = error
            errorDialog.open()
            updateDialog.close()
        }
    }

    Dialog {
        id: errorDialog
        title: qsTr("Update Failed")
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
                text: qsTr("OK")
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
    }
}


