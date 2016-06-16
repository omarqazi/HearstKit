import Foundation
import SQLite

public class HearstStore {
    private var databasePath: String = ""
    public var db: SQLite.Connection? = nil
    public var migrator: Migrator? = nil
    public var server: Connection? = nil
    
    private var mailboxesTable = Table("mailboxes")
    private var threadsTable = Table("threads")
    private var membersTable = Table("thread_members")
    private var messagesTable = Table("messages")
    
    init(path: String, server: Connection?) {
        self.server = server
        if let err = self.openPath(path) {
            print("Error opening Hearst Database:",err.localizedDescription)
        }
    }
    
    convenience init(path: String, domain: String) {
        self.init(path: path, server: Connection(serverDomain: domain))
    }
    
    public func openPath(newPath: String) -> NSError? {
        self.databasePath = newPath
        do {
            self.db = try SQLite.Connection(self.databasePath)
            self.migrator = Migrator(database: self.db!)
            let ve = self.migrator!.runLatestMigrations()
            if ve.error != nil {
                return ve.error
            }
        } catch let err as NSError {
            return err
        }
        
        return nil
    }
    
    public func createMailbox(mb: Mailbox, callback: (Mailbox) -> ()) -> NSError? {
        let insertQuery = mb.insertQuery()
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(insertQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.createMailbox(mb) { smb in
            let updateQuery = smb.updateQuery()
            do {
                try self.db?.run(updateQuery)
            } catch {
            }
            
            callback(smb)
        }
        
        return dbErr
    }
    
    public func getMailbox(uuid: String, callback: (Mailbox) -> ()) -> Mailbox? {
        var dbMailbox: Mailbox? = nil
        let query = Mailbox(uuid: uuid).selectQuery()
        
        do {
            for selectedMailbox in try self.db!.prepare(query) {
                dbMailbox = Mailbox(uuid: uuid)
                dbMailbox?.parseRow(selectedMailbox)
            }
        } catch {
        }
        
        self.server?.getMailbox(uuid) { mb in
            if dbMailbox != nil {
                let query = mb.updateQuery()
                do {
                    try self.db?.run(query)
                } catch {
                }
            } else {
                let query = mb.insertQuery()
                do {
                    try self.db?.run(query)
                } catch {
                }
            }
            callback(mb)
        }
        
        return dbMailbox
    }
    
    public func updateMailbox(mb: Mailbox, callback: (Mailbox) -> ()) -> NSError? {
        let updateQuery = mb.updateQuery()
        var dbErr: NSError? = nil
        do {
            try self.db?.run(updateQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.updateMailbox(mb) { smb in
            let serverUpdateQuery = smb.updateQuery()
            do {
                try self.db?.run(serverUpdateQuery)
            } catch {
            }
            
            callback(smb)
        }
        
        return dbErr
    }
    
    public func deleteMailbox(mb: Mailbox, callback: (Mailbox) -> ()) -> NSError? {
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(mb.deleteQuery())
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.deleteMailbox(mb) { callback($0) }
        return dbErr
    }
    
    public func createThread(tr: Thread, callback: (Thread) -> ()) -> NSError? {
        let insertQuery = tr.insertQuery()
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(insertQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.createThread(tr) { str in
            let updateQuery = str.updateQuery()
            do {
                try self.db?.run(updateQuery)
            } catch {
            }
            
            callback(str)
        }
        
        return dbErr
    }
    
    public func getThread(uuid: String, callback: (Thread) -> ()) -> Thread? {
        var dbThread: Thread? = nil
        let query = Thread(uuid: uuid).selectQuery()
        
        do {
            for selectedThread in try self.db!.prepare(query) {
                dbThread = Thread(uuid: uuid)
                dbThread?.parseRow(selectedThread)
            }
        } catch {
        }
        
        self.server?.getThread(uuid) { tr in
            if dbThread != nil {
                let query = tr.updateQuery()
                do {
                    try self.db?.run(query)
                } catch {
                }
            } else {
                let query = tr.insertQuery()
                do {
                    try self.db?.run(query)
                } catch {
                }
            }
            callback(tr)
        }
        
        return dbThread
    }
    
    public func updateThread(tr: Thread, callback: (Thread) -> ()) -> NSError? {
        let updateQuery = tr.updateQuery()
        var dbErr: NSError? = nil
        do {
            try self.db?.run(updateQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.updateThread(tr) { str in
            let serverUpdateQuery = str.updateQuery()
            do {
                try self.db?.run(serverUpdateQuery)
            } catch {
            }
            
            callback(str)
        }
        
        return dbErr
    }
    
    public func deleteThread(tr: Thread, callback: (Thread) -> ()) -> NSError? {
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(tr.deleteQuery())
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.deleteThread(tr) { callback($0) }
        return dbErr
    }
    
    public func createThread(tr: Thread, callback: (Thread) -> ()) -> NSError? {
        let insertQuery = tr.insertQuery()
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(insertQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.createThread(tr) { str in
            let updateQuery = str.updateQuery()
            do {
                try self.db?.run(updateQuery)
            } catch {
            }
            
            callback(str)
        }
        
        return dbErr
    }
    
    public func createMember(mem: Member, callback: (Member) -> ()) -> NSError? {
        
    }

}