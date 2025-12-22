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
            let rows = try Row.fetchAll(db, sql: """
                SELECT c.id AS c_id, c.uuid AS c_uuid, c.nome AS c_nome,
                       c.vencimento AS c_vencimento, c.fechamento AS c_fechamento,
                       c.operadora AS c_operadora, c.arquivado AS c_arquivado,
                       c.conta_uuid AS c_contaUuid, c.limite AS c_limite,
                       a.id AS a_id, a.uuid AS a_uuid, a.nome AS a_nome,
                       a.saldo AS a_saldo, a.currency_code AS a_currency
                FROM cartao c
                JOIN conta a ON c.conta_uuid = a.uuid
            """)            
          
            return rows.map { row in
                let conta = ContaModel(
                    id: row["a_id"],
                    uuid: row["a_uuid"],
                    nome: row["a_nome"],
                    saldo: row["a_saldo"],
                    currencyCode: row["a_currency"]
                )
                
                return CartaoModel(
                    id: row["c_id"],
                    uuid: row["c_uuid"],
                    nome: row["c_nome"],
                    vencimento: row["c_vencimento"],
                    fechamento: row["c_fechamento"],
                    operadora: row["c_operadora"],
                    arquivado: row["c_arquivado"],
                    contaUuid: row["c_contaUuid"],
                    limite: row["c_limite"],
                    conta: conta
                )
            }
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
            let rows = try Row.fetchAll(db, sql: """
                SELECT c.*, a.*
                FROM cartao c
                JOIN conta a ON c.conta_uuid = a.uuid
            """)

            return rows.map { row in
                let conta = ContaModel(
                    id: row["a.id"],
                    uuid: row["a.uuid"],
                    nome: row["a.nome"],
                    saldo: row["a.saldo"],
                    currencyCode: row["a.currency_code"]
                )

                return CartaoModel(
                    id: row["c.id"],
                    uuid: row["c.uuid"],
                    nome: row["c.nome"],
                    vencimento: row["c.vencimento"],
                    fechamento: row["c.fechamento"],
                    operadora: row["c.operadora"],
                    arquivado: row["c.arquivado"],
                    contaUuid: row["c.conta_uuid"],
                    limite: row["c.limite"],
                    conta: conta
                )
            }
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




