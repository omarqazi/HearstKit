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
    
    public func createMember(mem: Member, callback: (Member) -> ()) -> NSError? {
        let insertQuery = mem.insertQuery()
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(insertQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.createMember(mem) { smem in
            let updateQuery = mem.updateQuery()
            do {
                try self.db?.run(updateQuery)
            } catch {
            }
            
            callback(smem)
        }
        
        return dbErr
    }
    
    public func getMember(threadId: String, mailboxId: String,callback: (Member) -> ()) -> Member? {
        var dbMember: Member? = nil
        let query = Member(threadId: threadId, mailboxId: mailboxId).selectQuery()
        
        do {
            for selectedMember in try self.db!.prepare(query) {
                dbMember = Member(threadId: threadId, mailboxId: mailboxId)
                dbMember!.parseRow(selectedMember)
            }
        } catch {
        }
        
        self.server?.getMember(threadId, mailboxId: mailboxId) { smem in
            if dbMember == nil { // insert new record
                let query = smem.insertQuery()
                do {
                    try self.db?.run(query)
                } catch {
                }
            } else { // update existing record
                let query = smem.updateQuery()
                do {
                    try self.db?.run(query)
                } catch {
                }
            }
        }
        
        return dbMember
    }
    
    public func updateMember(mem: Member, callback: (Member) -> ()) -> NSError? {
        let updateQuery = mem.updateQuery()
        var dbErr: NSError? = nil
        do {
            try self.db?.run(updateQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.updateMember(mem) { smem in
            let serverUpdateQuery = smem.updateQuery()
            do {
                try self.db?.run(serverUpdateQuery)
            } catch {
            }
            
            callback(smem)
        }
        
        return dbErr
    }
    
    public func deleteMember(mem: Member, callback: (Member) -> ()) -> NSError? {
        var dbErr: NSError? = nil
        
        do {
            try self.db?.run(mem.deleteQuery())
        } catch let err as NSError {
            dbErr = err
        }
        
        self.server?.deleteMember(mem) { callback($0) }
        return dbErr
    }
    
    public func createMessage(msg: Message, callback: (Message) -> ()) -> NSError? {
        let insertQuery = msg.insertQuery()
        var dbErr: NSError? = nil
        
        do {
            try db?.run(insertQuery)
        } catch let err as NSError {
            dbErr = err
        }
        
        server?.createMessage(msg) { smsg in
            let updateQuery = smsg.updateQuery()
            do {
                try self.db?.run(updateQuery)
            } catch {
            }
            
            callback(smsg)
        }
        
        return dbErr
    }
    
    // Unlike other models messages can't be updated so once we save them theres no need
    // to get updates from the server in the future
    public func getMessage(uuid: String, callback: (Message) -> ()) -> Message? {
        do {
            for selectedMessage in try db!.prepare(Message(uuid: uuid).selectQuery()) {
                let dbMessage = Message(uuid: uuid)
                dbMessage.parseRow(selectedMessage)
                return dbMessage // skip server request
            }
        } catch {
        }
        
        server?.getMessage(uuid) { smsg in
            do {
                try self.db?.run(smsg.insertQuery())
            } catch {
            }
            
            callback(smsg)
        }
        
        return nil
    }
}