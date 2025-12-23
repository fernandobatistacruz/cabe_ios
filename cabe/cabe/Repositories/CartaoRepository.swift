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
            try self.listar()
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




