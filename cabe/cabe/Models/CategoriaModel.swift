//
//  CategoriaModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import GRDB

struct CategoriaModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "categoria"
    
    var id: Int64?
    var nome: String
    var nomeSubcategoria: String?
    var tipo: Int
    var icone: Int
    var cor: Int
    var pai: Int64?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nome
        case nomeSubcategoria
        case tipo
        case icone
        case cor
        case pai
    }
    
    enum Columns {
        static let id = Column("id")
        static let nome = Column("nome")
        static let nomeSubcategoria = Column("nomeSubcategoria")
        static let tipo = Column("tipo")
        static let icone = Column("icone")
        static let cor = Column("cor")
        static let pai = Column("pai")
    }
}
