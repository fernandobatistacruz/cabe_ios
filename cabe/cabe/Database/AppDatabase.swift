//
//  AppDatabase.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//


import GRDB
import Foundation

final class AppDatabase {

    static let shared = AppDatabase()

    let dbQueue: DatabaseQueue

    private init() {
        do {
            let url = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("cabe.db")
            
            dbQueue = try DatabaseQueue(path: url.path)
            
            try Self.makeMigrator().migrate(dbQueue)
        }
        catch {
            debugPrint("Erro ao abrir o banco", error)
            fatalError("Não foi possível abrir o banco")
        }
    }
}
