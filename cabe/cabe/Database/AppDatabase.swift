//
//  AppDatabase.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//


import GRDB
import Foundation

final class AppDatabase {

    static let shared = try! AppDatabase()

    let dbQueue: DatabaseQueue

    private init() throws {
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("cabe.db")

        dbQueue = try DatabaseQueue(path: url.path)
        try Self.makeMigrator().migrate(dbQueue)
    }
}
