//
//  CartaoDAO.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 14/12/25.
//

import Foundation
import SQLite3

final class CartaoData {

    static let tabela = "cartao"

    static let id = "id"
    static let uuid = "uuid"
    static let nome = "nome"
    static let vencimento = "vencimento"
    static let fechamento = "fechamento"
    static let operadora = "operadora"
    static let limite = "limite"
    static let arquivado = "arquivado"
    static let contaUuid = "conta_uuid"

    static let tabelaSql = """
    CREATE TABLE IF NOT EXISTS \(tabela)(
        \(id) INTEGER PRIMARY KEY AUTOINCREMENT,
        \(uuid) TEXT,
        \(nome) TEXT,
        \(vencimento) INTEGER,
        \(fechamento) INTEGER,
        \(operadora) INTEGER,
        \(arquivado) INTEGER,
        \(contaUuid) TEXT,
        \(limite) REAL
    );
    """

    private let db = AppDatabase.shared.db
}

extension CartaoData {

    func listar(where clause: String? = nil) async -> [CartaoModel] {

        let whereSQL = clause.map { "WHERE \($0)" } ?? ""

        let sql = """
        SELECT
            c.\(Self.uuid),
            c.\(Self.nome),
            c.\(Self.vencimento),
            c.\(Self.fechamento),
            c.\(Self.operadora),
            c.\(Self.limite),
            c.\(Self.arquivado),
            c.\(Self.contaUuid)
        FROM \(Self.tabela) c
        \(whereSQL)
        ORDER BY c.\(Self.nome)
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            print("❌ Erro ao preparar SQL:", error)
            return []
        }

        var lista: [CartaoModel] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            lista.append(
                CartaoModel(
                    uuid: String(cString: sqlite3_column_text(stmt, 0)),
                    nome: String(cString: sqlite3_column_text(stmt, 1)),
                    vencimento: Int(sqlite3_column_int(stmt, 2)),
                    fechamento: Int(sqlite3_column_int(stmt, 3)),
                    operadora: Int(sqlite3_column_int(stmt, 4)),
                    limite: sqlite3_column_double(stmt, 5),
                    arquivado: sqlite3_column_int(stmt, 6) == 1,
                    contaUuid: String(cString: sqlite3_column_text(stmt, 7))
                )
            )
        }

        sqlite3_finalize(stmt)
        return lista
    }
}


