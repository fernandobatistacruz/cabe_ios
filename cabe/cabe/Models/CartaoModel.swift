//
//  CartaoModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import GRDB

struct CartaoModel: Identifiable, Codable, FetchableRecord, PersistableRecord, Equatable {
    
    static let databaseTableName = "cartao"
    
    var id: Int64?
    var uuid: String
    var nome: String
    var vencimento: Int
    var fechamento: Int
    var operadora: Int
    var arquivado: Int
    var contaUuid: String
    var limite: Double
   
    var conta: ContaModel?
    
    enum CodingKeys: String, CodingKey {
        case id, uuid, nome, vencimento, fechamento, operadora, arquivado, contaUuid = "conta_uuid", limite
    }
    
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let nome = Column("nome")
        static let vencimento = Column("vencimento")
        static let fechamento = Column("fechamento")
        static let operadora = Column("operadora")
        static let arquivado = Column("arquivado")
        static let contaUuid = Column("conta_uuid")
        static let limite = Column("limite")
    }
    
    var operadoraEnum: OperadoraCartao {
        OperadoraCartao(rawValue: operadora) ?? .outra
    }
}

