import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: loginPage
    objectName: "loginPage"
    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1f2b" }
            GradientStop { position: 1.0; color: "#11141c" }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24
        width: Math.min(420, parent.width - 40)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: qsTr("Shiba Music")
                font.pixelSize: 28
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: qsTr("Connect to your Navidrome server")
                wrapMode: Text.WordWrap
                color: "#9aa4af"
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Frame {
            Layout.fillWidth: true
            padding: 20
            background: Rectangle {
                radius: 16
                color: "#1f2532"
                border.color: "#2d3545"
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                TextField {
                    id: url
                    placeholderText: qsTr("Server URL (https://...)")
                    Layout.fillWidth: true
                    selectByMouse: true
                }
                TextField {
                    id: user
                    placeholderText: qsTr("Username")
                    Layout.fillWidth: true
                    selectByMouse: true
                }
                TextField {
                    id: pass
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    selectByMouse: true
                    onAccepted: submit()
                }

                CheckBox {
                    id: rememberCheck
                    text: qsTr("Remember me")
                    checked: true
                }

                Button {
                    text: qsTr("Login")
                    Layout.fillWidth: true
                    highlighted: true
                    onClicked: submit()
                }

                Label {
                    id: err
                    visible: text.length > 0
                    color: "salmon"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    Component.onCompleted: {
        var credentials = api.loadCredentials();
        if (credentials.serverUrl) {
            url.text = credentials.serverUrl;
        }
        if (credentials.username) {
            user.text = credentials.username;
        }
    }

    function submit() {
        err.text = ""
        if (rememberCheck.checked) {
            api.saveCredentials(url.text, user.text, pass.text);
        } else {
            api.saveCredentials("", "", "");
        }
        api.login(url.text, user.text, pass.text)
    }

    function showError(message) {
        err.text = message
    }

    Connections {
        target: api
        function onErrorOccurred(message) {
            loginPage.showError(message)
        }
    }
}
