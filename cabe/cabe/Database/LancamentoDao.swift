//
//  LancamentoDao.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//

import GRDB
import Foundation

final class LancamentoDAO {

    private let dbQueue = AppDatabase.shared.dbQueue
    
    func salvar(_ lancamento: inout LancamentoModel) throws {
        try dbQueue.write { db in
            try lancamento.insert(db)
        }
    }
    
    func editar(_ lancamento: LancamentoModel) throws {
        try dbQueue.write { db in
            try lancamento.update(db)
        }
    }
    
    func remover(id: Int64, uuid: String) throws {
        try dbQueue.write { db in
            try LancamentoModel
                .filter(
                    LancamentoModel.Columns.id == id &&
                    LancamentoModel.Columns.uuid == uuid
                )
                .deleteAll(db)
        }
    }

    
    func limparDados() throws {
        try dbQueue.write { db in
            try LancamentoModel.deleteAll(db)
        }
    }
    
    func consultarPorUuid(_ uuid: String) throws -> [LancamentoModel] {
        try dbQueue.read { db in
            try LancamentoModel
                .filter(Column("uuid") == uuid)
                .fetchAll(db)
        }
    }
    
    func consultarRecentes() throws -> [LancamentoModel] {
        try dbQueue.read { db in
            try LancamentoModel
                .order(Column("id").desc)
                .limit(30)
                .fetchAll(db)
        }
    }
    
    func consultarVenceHoje() throws -> [LancamentoModel] {
        let hoje = Date()
        let calendar = Calendar.current

        return try dbQueue.read { db in
            try LancamentoModel
                .filter(
                    Column("pago") == false &&
                    Column("tipo") == 2 &&
                    Column("dia") == calendar.component(.day, from: hoje) &&
                    Column("mes") == calendar.component(.month, from: hoje) &&
                    Column("ano") == calendar.component(.year, from: hoje)
                )
                .order(
                    Column("ano").desc,
                    Column("mes").desc,
                    Column("dia").desc,
                    Column("id").desc
                )
                .fetchAll(db)
        }
    }
    
    func consultarComJoin(sqlWhere: String) throws -> [Row] {
        try dbQueue.read { db in
            let sql = """
            SELECT
                l.*,
                c.nome AS categoriaNome,
                ct.nome AS contaNome
            FROM lancamento l
            JOIN categoria c ON l.categoria = c.id
            JOIN conta ct ON l.conta_uuid = ct.uuid
            \(sqlWhere)
            """
            return try Row.fetchAll(db, sql: sql)
        }
    }


}
