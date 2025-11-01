#pragma once
#include <QObject>
#include <QString>

class AppInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString appName READ appName CONSTANT)
    
public:
    explicit AppInfo(QObject *parent = nullptr) : QObject(parent) {}
    
    QString version() const {
        return QString(APP_VERSION);
    }
    
    QString appName() const {
        return "Shiba Music";
    }
};
