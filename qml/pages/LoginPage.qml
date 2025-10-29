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
        spacing: 18
        width: 420

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: "Shiba Music"
                font.pixelSize: 28
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: "Conecte-se ao seu servidor Navidrome e curta suas playlists"
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
                spacing: 12
                Layout.fillWidth: true

                TextField {
                    id: url
                    placeholderText: "URL do servidor (https://...)"
                    Layout.fillWidth: true
                    selectByMouse: true
                }
                TextField {
                    id: user
                    placeholderText: "Usuário"
                    Layout.fillWidth: true
                    selectByMouse: true
                }
                TextField {
                    id: pass
                    placeholderText: "Senha"
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    selectByMouse: true
                    onAccepted: submit()
                }

                CheckBox {
                    id: crossfadeCheck
                    text: "Ativar crossfade entre faixas"
                    checked: player.crossfade
                    onToggled: player.crossfade = checked
                }

                Button {
                    text: "Entrar"
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

        Label {
            text: "Precisa de ajuda? Certifique-se de habilitar o acesso externo no Navidrome."
            font.pixelSize: 12
            color: "#6f788a"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }

    function submit() {
        err.text = ""
        api.login(url.text, user.text, pass.text)
    }

    Connections {
        target: api
        function onErrorOccurred(message) {
            err.text = message
        }
    }
}
