import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ComboBox {
    id: languageCombo
    
    model: translationManager ? translationManager.availableLanguages() : []
    
    currentIndex: {
        if (!translationManager) return 0
        var langs = translationManager.availableLanguages()
        return langs.indexOf(translationManager.currentLanguage)
    }
    
    displayText: translationManager ? 
        translationManager.languageName(currentValue) : ""
    
    onActivated: function(index) {
        if (translationManager && currentValue !== translationManager.currentLanguage) {
            translationManager.setLanguage(currentValue)
        }
    }
    
    delegate: ItemDelegate {
        width: languageCombo.width
        highlighted: languageCombo.highlightedIndex === index
        
        contentItem: Label {
            text: translationManager ? 
                translationManager.languageName(modelData) : modelData
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    Connections {
        target: translationManager
        function onLanguageChanged() {
            if (!translationManager) {
                languageCombo.currentIndex = 0
                return
            }
            var langs = translationManager.availableLanguages()
            languageCombo.currentIndex = langs.indexOf(translationManager.currentLanguage)
        }
    }
}
