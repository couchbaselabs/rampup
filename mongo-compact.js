db.runCommand({ compact: 'test' })
db.getLastError()
