//
//  MigratorTest.swift
//  
//
//  Created by Omar Qazi on 5/30/16.
//
//

import XCTest
import SQLite
class MigratorTest: XCTestCase {
    var migrator: Migrator?
    
    override func setUp() {
        do {
            let db = try SQLite.Connection()
            self.migrator = Migrator(database: db)
        } catch {
            print("Failed to get SQLite database")
        }
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNextVersionNumber() {
        XCTAssert(self.migrator?.nextSchemaVersion() == 1)
        
        if let err = self.migrator?.upMigration(1) {
            XCTAssert(false, "Error running migration: \(err.localizedDescription)")
        }
        XCTAssert(self.migrator?.nextSchemaVersion() == 2)
        
        if let err = self.migrator?.upMigration(2) {
            XCTAssert(false, "Error running migration: \(err.localizedDescription)")
        }
        XCTAssert(self.migrator?.nextSchemaVersion() == 3)
        
        if let err = self.migrator?.downMigration(2, migrationName: "create-mailboxes") {
            XCTAssert(false, "Error running migration: \(err.localizedDescription)")
        }
        XCTAssert(self.migrator?.nextSchemaVersion() == 2)
        
        if let err = self.migrator?.upMigration(2) {
            XCTAssert(false, "Error running migration: \(err.localizedDescription)")
        }
        XCTAssert(self.migrator?.nextSchemaVersion() == 3)
    }
    
    func testRunLatestMigrations() {
        XCTAssert(self.migrator?.nextSchemaVersion() == 1)
        let ve = self.migrator?.runLatestMigrations()
        if ve?.error != nil {
            XCTAssert(false, "Error running migration: \(ve?.error?.localizedDescription)")
        }
        XCTAssert(self.migrator!.nextSchemaVersion() == (Int64(self.migrator!.hearstMigrations.count) + 1))
    }
}
