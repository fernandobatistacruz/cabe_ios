//
//  ContaRepository
//  cabe
//
//  Created by Fernando Batista da Cruz on 20/12/25.
//

import GRDB
import Foundation

final class ContaRepository : ContaRepositoryProtocol{
    
    fileprivate let db: AppDatabase
    
    init (db: AppDatabase = .shared){
        self.db = db
    }
    
    func observeContas(
        onChange: @escaping ([ContaModel]) -> Void
    ) -> AnyDatabaseCancellable {
        
        let observation = ValueObservation.tracking { db in
            try ContaModel.fetchAll(db)
        }
        
        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB:", $0) },
            onChange: onChange
        )
    }

    func salvar(_ conta: inout ContaModel) throws {
        try db.dbQueue.write { db in
            try conta.insert(db)
        }
    }
    
    func editar(_ conta: ContaModel) throws {
        try db.dbQueue.write { db in
            try conta.update(db)
        }
    }
    
    func remover(id: Int64, uuid: String) throws {
       _ =  try db.dbQueue.write { db in
            try ContaModel
                .filter(
                    ContaModel.Columns.id == id &&
                    ContaModel.Columns.uuid == uuid
                )
                .deleteAll(db)
        }
    }
    
    func limparDados() throws {
       _ =  try db.dbQueue.write { db in
            try ContaModel.deleteAll(db)
        }
    }
    
    func listar() throws -> [ContaModel] {
        try db.dbQueue.read { db in
            try ContaModel.fetchAll(db)
        }
    }
    
    func consultarPorUuid(_ uuid: String) throws -> [ContaModel] {
        try db.dbQueue.read { db in
            try ContaModel
                .filter(Column("uuid") == uuid)
                .fetchAll(db)
        }
    }
}

protocol ContaRepositoryProtocol {
   
    func observeContas(onChange: @escaping ([ContaModel]) -> Void) -> AnyDatabaseCancellable
    func salvar(_ conta: inout ContaModel) throws
    func editar(_ conta: ContaModel) throws
    func remover(id: Int64, uuid: String) throws
    func limparDados() throws
    func listar() throws -> [ContaModel]
    func consultarPorUuid(_ uuid: String) throws -> [ContaModel]
}
