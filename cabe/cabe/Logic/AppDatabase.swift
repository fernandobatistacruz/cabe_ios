//
//  AppDatabase.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/12/25.
//

import Foundation
import SQLite3

final class AppDatabase {
    
    static let shared = AppDatabase()
    let db: OpaquePointer?
    private let databaseName = "cabe.db"
    private let databaseVersion: Int32 = 23
   
    private init() {
        
        if AppDatabase.isPreview {
            db = nil
            return
       }
        
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(databaseName)

        var database: OpaquePointer?

        if sqlite3_open(url.path, &database) == SQLITE_OK {
            self.db = database
            migrateIfNeeded()
        } else {
            self.db = nil
        }
    }
    
    private func onCreate() {

        //exec(LancamentoDAO.tabelaSql)
        exec(CartaoData.tabelaSql)
        //exec(CategoriaDAO.tabelaSql)
        //exec(SaldoDAO.tabelaSql)
        //exec(ContaDAO.tabelaSql)
        //exec(FavoritosDAO.tabelaSql)

        //CategoriaDAO.inserts.forEach { exec($0) }
        //ContaDAO.inserts.forEach { exec($0) }
        //FavoritosDAO.inserts.forEach { exec($0) }

        //AppAjustes().setCarteira(["conta", "0", "Conta Inicial"])
    }

    private func onUpgrade(from old: Int32) {

        if old < 2 {
            exec("ALTER TABLE lancamento ADD pago INTEGER DEFAULT 0")
        }

        if old < 3 {
            exec("ALTER TABLE lancamento ADD cartao_uuid TEXT")
            exec(CartaoData.tabelaSql)
        }

        if old < 4 {
            //exec(CategoriaDAO.tabelaSql)
            //CategoriaDAO.inserts.forEach { exec($0) }
        }

        if old < 5 {
            //exec(CategoriaDAO.sql30)
        }

        if old < 6 {
            exec("ALTER TABLE lancamento ADD dividido INTEGER DEFAULT 0")
        }

        if old < 7 {
            exec("""
            UPDATE lancamento SET
            dia_compra = dia,
            mes_compra = mes,
            ano_compra = ano
            WHERE tipo = 1
            """)
        }

        if old < 8 {
            exec("""
            UPDATE lancamento SET
            dia_compra = dia,
            mes_compra = mes,
            ano_compra = ano
            WHERE tipo = 2
            AND recorrente = 1
            AND (cartao_uuid IS NULL OR cartao_uuid = '')
            """)
        }

        if old < 10 {
            //exec(CategoriaDAO.sql0)
        }

        if old < 11 {
            //exec(SaldoDAO.tabelaSql)
        }

        if old < 12 {
            exec("ALTER TABLE cartao ADD arquivado INTEGER DEFAULT 0")
        }

        if old < 13 {
            exec("DROP TABLE saldo")
            //exec(SaldoDAO.tabelaSql)
            //exec(ContaDAO.tabelaSql)
            //exec(ContaDAO.sql0)
            exec("ALTER TABLE cartao ADD conta_uuid TEXT DEFAULT '0'")
            exec("ALTER TABLE lancamento ADD conta_uuid TEXT DEFAULT '0'")

            UserDefaults.standard.removeObject(forKey: "controlarTransacao")
            UserDefaults.standard.removeObject(forKey: "cartaoPadrao")
        }

        if old < 14 {
            exec("ALTER TABLE lancamento ADD transferencia INTEGER DEFAULT 0")
        }

        if old < 15 {
            exec("ALTER TABLE lancamento ADD anotacao TEXT DEFAULT ''")
        }

        if old < 16 {
            //exec(FavoritosDAO.tabelaSql)
            //FavoritosDAO.inserts.forEach { exec($0) }
        }

        if old < 17 {
            exec("ALTER TABLE lancamento ADD notificado INTEGER DEFAULT 0")
        }

        if old < 18 {
            exec("ALTER TABLE lancamento ADD data_criacao TEXT DEFAULT '1990-01-01'")
        }

        if old < 19 {
            exec("DELETE FROM favoritos")
            //FavoritosDAO.inserts.forEach { exec($0) }
        }

        if old < 20 {
            //FavoritosDAO.moreInserts.forEach { exec($0) }
        }

        if old < 21 {
            exec("UPDATE favoritos SET nome = 'Contas' WHERE id = 0")
        }

        if old < 22 {
            exec("ALTER TABLE categoria ADD pai INTEGER")
            exec("ALTER TABLE categoria ADD nome_subcategoria TEXT")
        }

        if old < 23 {
            //AppAjustes().setNotificacao(false)
            //AppAjustes().setBackup(false)
        }
    }

    private func exec(_ sql: String) {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            fatalError("❌ Erro SQL: \(error)\n\(sql)")
        }
    }
}

extension AppDatabase {

    private func getUserVersion() -> Int32 {
        var stmt: OpaquePointer?
        var version: Int32 = 0

        if sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                version = sqlite3_column_int(stmt, 0)
            }
        }
        sqlite3_finalize(stmt)
        return version
    }

    private func setUserVersion(_ version: Int32) {
        let sql = "PRAGMA user_version = \(version);"
        sqlite3_exec(db, sql, nil, nil, nil)
    }
}

extension AppDatabase {
    private func migrateIfNeeded() {

        let oldVersion = getUserVersion()

        if oldVersion == 0 {
            onCreate()
        }

        onUpgrade(from: oldVersion)
        setUserVersion(databaseVersion)
    }
}

extension AppDatabase {
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

