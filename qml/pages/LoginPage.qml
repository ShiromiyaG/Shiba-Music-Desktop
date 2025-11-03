import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Page {
    Components.ThemePalette { id: theme }
    id: loginPage
    objectName: "loginPage"

    property var savedCredentials: []
    property string selectedCredentialKey: ""

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.cardBackground }
            GradientStop { position: 1.0; color: theme.windowBackgroundFallback }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24
        width: Math.min(460, parent.width - 40)

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
                text: qsTr("Connect to your Navidrome or Subsonic server")
                wrapMode: Text.WordWrap
                color: theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Frame {
            Layout.fillWidth: true
            padding: 20
            background: Rectangle {
                radius: 16
                color: theme.surface
                border.color: theme.listItemHover
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: qsTr("Saved connections")
                        color: theme.textSecondary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        visible: savedCredentials.length > 0
                    }

                    ComboBox {
                        id: savedServersCombo
                        Layout.fillWidth: true
                        model: savedCredentials
                        textRole: "displayName"
                        enabled: savedCredentials.length > 0
                        displayText: currentIndex >= 0 && currentIndex < savedCredentials.length
                                ? savedCredentials[currentIndex].displayName
                                : (savedCredentials.length > 0 ? qsTr("Select a server")
                                                               : qsTr("No saved servers yet"))
                        onActivated: selectCredentialByIndex(index)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: qsTr("New credential")
                        Layout.fillWidth: true
                        onClicked: startNewCredential()
                    }

                    Button {
                        text: qsTr("Remove")
                        Layout.preferredWidth: implicitWidth
                        visible: savedCredentials.length > 0
                        enabled: selectedCredentialKey.length > 0
                        onClicked: removeSelectedCredential()
                    }
                }

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
                    text: qsTr("Remember this server")
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

    Component.onCompleted: refreshSavedCredentials()

    function normalizedUrlValue(value) {
        var trimmed = (value || "").trim()
        while (trimmed.endsWith("/")) {
            trimmed = trimmed.slice(0, -1)
        }
        return trimmed
    }

    function derivedCredentialKey(serverUrl, username) {
        var normalizedUrl = normalizedUrlValue(serverUrl)
        var normalizedUser = (username || "").trim()
        if (!normalizedUrl || !normalizedUser) {
            return ""
        }
        return normalizedUrl.toLowerCase() + "|" + normalizedUser.toLowerCase()
    }

    function credentialIndexForKey(key) {
        if (!key) {
            return -1
        }
        for (var i = 0; i < savedCredentials.length; ++i) {
            if (savedCredentials[i].key === key) {
                return i
            }
        }
        return -1
    }

    function selectCredentialByIndex(index) {
        if (index < 0 || index >= savedCredentials.length) {
            return false
        }
        return selectCredential(savedCredentials[index])
    }

    function selectCredentialByKey(key) {
        var idx = credentialIndexForKey(key)
        if (idx === -1) {
            return false
        }
        return selectCredential(savedCredentials[idx])
    }

    function selectCredential(entry) {
        if (!entry) {
            return false
        }
        selectedCredentialKey = entry.key || derivedCredentialKey(entry.serverUrl, entry.username)
        savedServersCombo.currentIndex = credentialIndexForKey(selectedCredentialKey)
        url.text = entry.serverUrl || ""
        user.text = entry.username || ""
        pass.text = toPlainString(entry.password)
        rememberCheck.checked = true
        return true
    }

    function clearForm() {
        selectedCredentialKey = ""
        if (typeof savedServersCombo !== "undefined") {
            savedServersCombo.currentIndex = -1
        }
        url.text = ""
        user.text = ""
        pass.text = ""
        rememberCheck.checked = true
    }

    function toPlainString(value) {
        if (value === undefined || value === null)
            return ""
        return String(value)
    }

    function mappedCredential(entry) {
        if (!entry)
            return null
        var normalizedServer = normalizedUrlValue(entry.serverUrl)
        var normalizedUser = (entry.username || "").trim()
        var key = entry.key || derivedCredentialKey(normalizedServer, normalizedUser)
        if (!key)
            return null
        var display = entry.displayName
        if (!display || !display.length) {
            display = normalizedUser.length ? normalizedUser + " @ " + normalizedServer : normalizedServer
        }
        return {
            key: key,
            serverUrl: normalizedServer,
            username: normalizedUser,
            password: toPlainString(entry.password),
            displayName: display,
            lastUsed: toPlainString(entry.lastUsed)
        }
    }

    function refreshSavedCredentials(targetKey) {
        if (!api || !api.savedCredentials) {
            savedCredentials = []
            clearForm()
            return
        }

        var fetched = api.savedCredentials()
        var list = []
        if (fetched && fetched.length !== undefined) {
            for (var i = 0; i < fetched.length; ++i) {
                var mapped = mappedCredential(fetched[i])
                if (mapped)
                    list.push(mapped)
            }
        }
        savedCredentials = list

        var keyToUse = targetKey
        if (!keyToUse) {
            if (selectedCredentialKey) {
                keyToUse = selectedCredentialKey
            } else if (api.loadCredentials) {
                var stored = api.loadCredentials()
                if (stored) {
                    keyToUse = stored.key || derivedCredentialKey(stored.serverUrl, stored.username)
                }
            }
        }

        if (keyToUse && selectCredentialByKey(keyToUse)) {
            return
        }

        if (savedCredentials.length > 0) {
            selectCredentialByIndex(0)
        } else {
            clearForm()
        }
    }

    function startNewCredential() {
        clearForm()
        url.forceActiveFocus()
    }

    function removeSelectedCredential() {
        if (!api || !api.removeCredentials || !selectedCredentialKey) {
            return
        }
        api.removeCredentials(selectedCredentialKey)
        selectedCredentialKey = ""
        refreshSavedCredentials("")
        url.forceActiveFocus()
    }

    function submit() {
        err.text = ""
        var serverUrl = normalizedUrlValue(url.text)
        var username = (user.text || "").trim()
        var password = pass.text || ""

        if (!serverUrl.length) {
            err.text = qsTr("Server URL is required.")
            url.forceActiveFocus()
            return
        }
        if (!username.length) {
            err.text = qsTr("Username is required.")
            user.forceActiveFocus()
            return
        }
        if (!password.length) {
            err.text = qsTr("Password is required.")
            pass.forceActiveFocus()
            return
        }

        var remember = rememberCheck.checked
        var newKey = derivedCredentialKey(serverUrl, username)

        if (api && api.saveCredentials) {
            api.saveCredentials(serverUrl, username, password, remember)
        }

        if (remember) {
            selectedCredentialKey = newKey
        } else if (selectedCredentialKey === newKey) {
            selectedCredentialKey = ""
        }

        refreshSavedCredentials(selectedCredentialKey)

        api.login(serverUrl, username, password)
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