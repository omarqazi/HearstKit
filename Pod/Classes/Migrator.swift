import Foundation
import SQLite

struct Migration {
    var up: () -> (NSError?)
    var down: (String) -> (NSError?)
    var number: Int64
    var name: String
}

public class Migrator {
    var db: SQLite.Connection
    let versions = Table("schema_versions")
    let mailboxes = Table("mailboxes")
    let threads = Table("threads")
    let members = Table("thread_members")
    let messages = Table("messages")
    
    var hearstMigrations: [Migration] {
        return [
            Migration(up: self.migrate_1_create_versions, down: self.demigrate_1_create_versions,number: 1, name: "create-versions"),
            Migration(up: self.migrate_2_create_mailboxes, down: self.demigrate_2_create_mailboxes,number: 2, name: "create-mailboxes"),
            Migration(up: self.migrate_3_create_threads, down: self.demigrate_3_create_threads, number: 3, name: "create-threads"),
            Migration(up: self.migrate_4_create_members, down: self.demigrate_4_create_members, number: 4, name: "create-members"),
            Migration(up: self.migrate_5_create_messages, down: self.demigrate_5_create_messages, number: 5, name: "create-messages")
        ]
    }
    
    init(database: SQLite.Connection) {
        self.db = database
    }
    
    func runLatestMigrations() -> (dbVersion: Int64, error: NSError?) {
        var currentVersion: Int64 = 0
        while self.nextSchemaVersion() < (self.hearstMigrations.count + 1) {
            currentVersion = self.nextSchemaVersion()
            if let err = self.upMigration(currentVersion) {
                return (currentVersion, err)
            }
        }
        return (currentVersion, nil)
    }
    
    // Returns the next version number that hasn't been installed yet
    func nextSchemaVersion() -> Int64 {
        let migrationNumber = Expression<Int64>("id")
        let query = versions.order(migrationNumber.desc).limit(1)
        do {
            for latestMigration in try db.prepare(query) {
                return latestMigration[migrationNumber] + 1
            }
        } catch {
        }
        
        return 1
    }
    
    func upMigration(index: Int64) -> NSError? {
        let mig = self.hearstMigrations[index - 1]
        if let err = mig.up() {
            return err
        }
        if let err = self.recordMigration(mig) {
            return err
        }
        return nil
    }
    
    func downMigration(index: Int64, migrationName: String) -> NSError? {
        let mig = self.hearstMigrations[index - 1]
        if let err = mig.down(migrationName) {
            return err
        }
        if let err = self.unrecordMigration(mig) {
            return err
        }
        return nil
    }
    
    func recordMigration(mig: Migration) -> NSError? {
        let insertQuery = versions.insert(Expression<String>("migration") <- mig.name)
        do {
            try db.run(insertQuery)
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func unrecordMigration(mig: Migration) -> NSError? {
        let id = Expression<Int64>("id")
        let deleteQuery = versions.filter(id == mig.number).delete()
        do {
            try db.run(deleteQuery)
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func migrate_1_create_versions() -> NSError? {
        do {
            try db.run(versions.create() { t in
                t.column(Expression<Int64>("id"),primaryKey: true)
                t.column(Expression<String>("migration"))
            })
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func demigrate_1_create_versions(migrationName: String) -> NSError? {
        do {
            try db.run(versions.drop())
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func migrate_2_create_mailboxes() -> NSError? {
        do {
            try db.run(mailboxes.create() { t in
                t.column(Expression<Int64>("id"),primaryKey: true)
                t.column(Expression<String>("uuid"))
                t.column(Expression<String>("public_key"))
                t.column(Expression<String>("device_id"))
                t.column(Expression<Int64>("downloaded_at"))
                t.column(Expression<Int64>("connected_at"))
                t.column(Expression<Int64>("created_at"))
                t.column(Expression<Int64>("updated_at"))
            })
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func demigrate_2_create_mailboxes(migrationName: String) -> NSError? {
        do {
            try db.run(mailboxes.drop())
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func migrate_3_create_threads() -> NSError? {
        do {
            try db.run(threads.create() { t in
                t.column(Expression<Int64>("id"),primaryKey: true)
                t.column(Expression<String>("uuid"))
                t.column(Expression<String>("identifier"))
                t.column(Expression<String>("domain"))
                t.column(Expression<String>("subject"))
                t.column(Expression<Int64>("created_at"))
                t.column(Expression<Int64>("updated_at"))
            })
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func demigrate_3_create_threads(migrationName: String) -> NSError? {
        do {
            try db.run(threads.drop())
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func migrate_4_create_members() -> NSError? {
        do {
            try db.run(members.create() { t in
                t.column(Expression<Int64>("id"),primaryKey: true)
                t.column(Expression<String>("thread_id"))
                t.column(Expression<String>("mailbox_id"))
                t.column(Expression<Bool>("allow_read"))
                t.column(Expression<Bool>("allow_write"))
                t.column(Expression<Bool>("allow_notification"))
            })
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func demigrate_4_create_members(migrationName: String) -> NSError? {
        do {
            try db.run(members.drop())
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func migrate_5_create_messages() -> NSError? {
        do {
            try db.run(messages.create() { t in
                t.column(Expression<Int64>("id"),primaryKey: true)
                t.column(Expression<String>("uuid"))
                t.column(Expression<String>("thread_id"))
                t.column(Expression<String>("sender_id"))
                t.column(Expression<Int64>("created_at"))
                t.column(Expression<Int64>("updated_at"))
                t.column(Expression<Int64>("expires_at"))
                t.column(Expression<String>("topic"))
                t.column(Expression<String>("body"))
                t.column(Expression<String>("labels"))
                t.column(Expression<String>("payload"))
                t.column(Expression<Int64>("index"))
            })
        } catch let err as NSError {
            return err
        }
        return nil
    }
    
    func demigrate_5_create_messages(migrationName: String) -> NSError? {
        do {
            try db.run(messages.drop())
        } catch let err as NSError {
            return err
        }
        return nil
    }
}
