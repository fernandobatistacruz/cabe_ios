//
//  CartaoRepository.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import GRDB

final class CartaoRepository : CartaoRepositoryProtocol{
        
    fileprivate let db: AppDatabase
    
    init (db: AppDatabase = .shared){
        self.db = db
    }
    
    func observeCartoes(
        onChange: @escaping ([CartaoModel]) -> Void
    ) -> AnyDatabaseCancellable {

        let observation = ValueObservation.tracking { db in
            try self.listar(db: db)
        }
        
        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB:", $0) },
            onChange: onChange
        )
    }

    func salvar(_ cartao: inout CartaoModel) throws {
        try db.dbQueue.write { db in
            try cartao.insert(db)
        }
    }
    
    func editar(_ cartao: CartaoModel) throws {
        try db.dbQueue.write { db in
            try cartao.update(db)
        }
    }
    
    func remover(id: Int64, uuid: String) throws {
       _ =  try db.dbQueue.write { db in
            try CartaoModel
                .filter(
                    CartaoModel.Columns.id == id &&
                    CartaoModel.Columns.uuid == uuid
                )
                .deleteAll(db)
        }
    }
    
    func limparDados() throws {
       _ =  try db.dbQueue.write { db in
            try CartaoModel.deleteAll(db)
        }
    }
    
    func listar() throws -> [CartaoModel] {
        try db.dbQueue.read { db in
            try listar(db: db)
        }
    }
    
    private func listar(db: Database) throws -> [CartaoModel] {
        let rows = try Row.fetchAll(db, sql: """
                SELECT
                    c.id            AS cartao_id,
                    c.uuid          AS cartao_uuid,
                    c.nome          AS cartao_nome,
                    c.vencimento,
                    c.fechamento,
                    c.operadora,
                    c.arquivado,
                    c.conta_uuid,
                    c.limite,
            
                    a.id            AS conta_id,
                    a.uuid          AS conta_uuid,
                    a.nome          AS conta_nome,
                    a.saldo,
                    a.currency_code
                FROM cartao c
                JOIN conta a ON c.conta_uuid = a.uuid
            """)
        
        return rows.map { row in
            
            let conta = ContaModel(
                id: row["conta_id"],
                uuid: row["conta_uuid"],
                nome: row["conta_nome"],
                saldo: row["saldo"],
                currencyCode: row["currency_code"]
            )
            
            return CartaoModel(
                id: row["cartao_id"],
                uuid: row["cartao_uuid"],
                nome: row["cartao_nome"],
                vencimento: row["vencimento"],
                fechamento: row["fechamento"],
                operadora: row["operadora"],
                arquivado: row["arquivado"],
                contaUuid: row["conta_uuid"],
                limite: row["limite"],
                conta: conta
            )
        }        
    }
    
    func consultarPorUuid(_ uuid: String) throws -> [CartaoModel] {
        try db.dbQueue.read { db in
            try CartaoModel
                .filter(CartaoModel.Columns.uuid == uuid)
                .fetchAll(db)
        }
    }
}

protocol CartaoRepositoryProtocol {
    
    func observeCartoes(onChange: @escaping ([CartaoModel]) -> Void) -> AnyDatabaseCancellable
    func salvar(_ cartao: inout CartaoModel) throws
    func editar(_ cartao: CartaoModel) throws
    func remover(id: Int64, uuid: String) throws
    func limparDados() throws
    func listar() throws -> [CartaoModel]
    func consultarPorUuid(_ uuid: String) throws -> [CartaoModel]
}




