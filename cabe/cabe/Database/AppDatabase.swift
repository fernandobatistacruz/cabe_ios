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
//      1.0.0 - Inicialização do banco e configuração básica
//
//  Notes:
//      - Usar GRDB para acesso a SQLite.
//      - Todas as migrações devem ser registradas em Migrations.swift.
//      - Classe singleton para acesso global ao banco.
//

import GRDB
import Foundation

final class AppDatabase {

    static let shared = AppDatabase()
    let dbQueue: DatabaseQueue
    let defaultCurrencyCode: String

    private init() {
        
        self.defaultCurrencyCode =
                    Locale.current.currency?.identifier ?? "USD"
        
        do {
            let url = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("cabe.db")
            
            dbQueue = try DatabaseQueue(path: url.path)
            
            try Self.makeMigrator(
                            defaultCurrencyCode: defaultCurrencyCode
                        ).migrate(dbQueue)
        }
        catch {
            debugPrint("Erro ao abrir o banco", error)
            fatalError("Não foi possível abrir o banco")
        }
    }
}
