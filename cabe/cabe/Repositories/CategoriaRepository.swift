//
//  CategoriaRepository.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

import GRDB
import Foundation

final class CategoriaRepository : CategoriaRepositoryProtocol{
    
    fileprivate let db: AppDatabase
    
    init (db: AppDatabase = .shared){
        self.db = db
    }
    
    func observeCategorias(
        onChange: @escaping ([CategoriaModel]) -> Void
    ) -> AnyDatabaseCancellable {
        
        let observation = ValueObservation.tracking { db in
            try CategoriaModel.fetchAll(db).sorted {
                $0.nome.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) <
                $1.nome.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            }
        }
        
        return observation.start(
            in: db.dbQueue,
            onError: { print("Erro DB:", $0) },
            onChange: onChange
        )
    }

    func salvar(_ categoria: CategoriaModel) async throws {
        try await db.dbQueue.write { db in
            try categoria.insert(db)
        }
    }
    
    func editar(_ categoria: CategoriaModel) async throws {
        try await db.dbQueue.write { db in
            try categoria.update(db)
        }
    }
    
    func editarSubcategorias(_ categorias: [CategoriaModel]) async throws {
        try await db.dbQueue.write { db in
            for categoria in categorias {
                try categoria.update(db)
            }
        }
    }
    
    func remover(id: Int64, tipo: Int) async throws {
        _ =  try await db.dbQueue.write { db in
            try CategoriaModel
                .filter(
                    CategoriaModel.Columns.id == id &&
                    CategoriaModel.Columns.tipo == tipo
                )
                .deleteAll(db)
        }
    }
    
    func listar() throws -> [CategoriaModel] {
        try db.dbQueue.read { db in
            try CategoriaModel.fetchAll(db)
        }
    }
    
    func listar(tipo: Tipo) throws -> [CategoriaModel] {
        try db.dbQueue.read { db in
            try CategoriaModel
                .filter(CategoriaModel.Columns.tipo == tipo.rawValue)
                .fetchAll(db).sorted {
                    $0.nome.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) <
                    $1.nome.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                }
        }
    }
}

protocol CategoriaRepositoryProtocol {
   
    func observeCategorias(onChange: @escaping ([CategoriaModel]) -> Void) -> AnyDatabaseCancellable
    func salvar(_ categoria: CategoriaModel) async throws
    func editar(_ categoria: CategoriaModel) async throws
    func remover(id: Int64, tipo: Int) async throws
    func listar() throws -> [CategoriaModel]
    func listar(tipo: Tipo) throws -> [CategoriaModel]
}
