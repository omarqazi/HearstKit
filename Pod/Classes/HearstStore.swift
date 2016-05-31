import Foundation
import SQLite

public class HearstStore {
    private var databasePath: String = ""
    public var db: SQLite.Connection? = nil
    public var migrator: Migrator? = nil
    
    init(path: String) {
        if let err = self.openPath(path) {
            print("Error opening Hearst Database:",err.localizedDescription)
        }
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
}