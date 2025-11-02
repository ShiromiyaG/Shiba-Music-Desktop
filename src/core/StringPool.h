#pragma once
#include <QString>
#include <QHash>

class StringPool {
public:
    QString intern(const QString &str) {
        if (str.isEmpty()) return str;
        auto it = m_pool.constFind(str);
        if (it != m_pool.constEnd()) return *it;
        m_pool.insert(str, str);
        return str;
    }
    
    void clear() { m_pool.clear(); }
    int size() const { return m_pool.size(); }

private:
    QHash<QString, QString> m_pool;
};
