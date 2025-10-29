import QtQuick
import QtQuick.Controls

Page {
    id: loginPage

    contentItem: Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        width: 420

        Label {
            text: "Conecte ao seu Navidrome"
            font.pixelSize: 20
        }
        TextField { id: url; placeholderText: "URL do servidor (https://...)" }
        TextField { id: user; placeholderText: "Usuário" }
        TextField { id: pass; placeholderText: "Senha"; echoMode: TextInput.Password }
        Button {
            text: "Entrar"
            onClicked: api.login(url.text, user.text, pass.text)
        }
        Label {
            id: err
            wrapMode: Label.Wrap
            color: "salmon"
            visible: false
        }
        Connections {
            target: api
            function onErrorOccurred(message) {
                err.text = message
                err.visible = true
            }
        }
    }
}
