//
//  AppDatabase.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//  Copyright © 2025 Fernando Batista da Cruz. All rights reserved.
//
//  Description:
//      Responsável pela configuração do banco de dados do aplicativo,
//      incluindo inicialização do dbQueue, migrações e seeds.
//
//  Version:
//      1.1.0 - Suporte a remoção e recriação do banco
//
//  Notes:
//      - Usar GRDB para acesso a SQLite.
//      - Todas as migrações devem ser registradas em Migrations.swift.
//      - Classe singleton para acesso global ao banco.
//

import Foundation
import GRDB

final class AppDatabase {

    // MARK: - Singleton
    static let shared = AppDatabase()

    // MARK: - Database
    /// Fila de acesso ao banco (read-only externamente)
    private(set) var dbQueue: DatabaseQueue!

    /// Moeda padrão usada nas migrações / seeds
    let defaultCurrencyCode: String

    // MARK: - Init
    private init() {
        self.defaultCurrencyCode = Locale.systemCurrencyCode

        do {
            try openDatabase()
        } catch {
            debugPrint("Erro ao abrir o banco:", error)
            fatalError("Não foi possível inicializar o banco de dados")
        }
    }
}

// MARK: - Database Lifecycle
extension AppDatabase {

    /// URL oficial do banco de dados
    private static func databaseURL() throws -> URL {
        try FileManager.default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("cabe.db")
    }

    /// Abre (ou reabre) o banco e executa migrações
    private func openDatabase() throws {
        let url = try Self.databaseURL()

        dbQueue = try DatabaseQueue(path: url.path)

        try Self.makeMigrator(
            defaultCurrencyCode: defaultCurrencyCode
        ).migrate(dbQueue)
    }

    /// Fecha o banco e remove todos os arquivos físicos
    func deleteDatabase() throws {
        // 1. Garante que nenhuma conexão está ativa
        dbQueue = nil

        let fm = FileManager.default
        let url = try Self.databaseURL()

        let files = [
            url,
            url.appendingPathExtension("wal"),
            url.appendingPathExtension("shm")
        ]

        for file in files where fm.fileExists(atPath: file.path) {
            try fm.removeItem(at: file)
        }
    }

    /// Recria o banco do zero (após delete)
    func recreateDatabase() throws {
        try openDatabase()
    }
}
