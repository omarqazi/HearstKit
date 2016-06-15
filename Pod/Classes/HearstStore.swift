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
        
        self.server?.createMailbox(mb) { (smb) in
            // update db record
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
            // insert or update mailbox
            callback(mb)
        }
        
        return dbMailbox
    }
}