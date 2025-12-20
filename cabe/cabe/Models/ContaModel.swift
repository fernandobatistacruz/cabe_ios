//
//  ContaModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 20/12/25.
//

//
//  Lancamento.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//

import GRDB

struct ContaModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "conta"
    
    var id: Int64?
    var uuid: String
    var nome: String
    var saldo: Double
    
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let nome = Column("nome")
        static let saldo = Column("saldo")
    }
}



