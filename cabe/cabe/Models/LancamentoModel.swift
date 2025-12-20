//
//  Lancamento.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 19/12/25.
//


import Foundation
import GRDB

import Foundation
import GRDB

struct LancamentoModel: Codable, FetchableRecord, PersistableRecord, Identifiable {
   
    static let databaseTableName = "lancamento"
    
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let tipo = Column("tipo")
        static let dia = Column("dia")
        static let mes = Column("mes")
        static let ano = Column("ano")
        static let diaCompra = Column("diaCompra")
        static let mesCompra = Column("mesCompra")
        static let anoCompra = Column("anoCompra")
        static let categoriaID = Column("categoria")
        static let recorrente = Column("recorrente")
        static let parcelas = Column("parcelas")
        static let parcelaMes = Column("parcelaMes")
        static let valor = Column("valor")
        static let cartaoUuid = Column("cartao_uuid")
        static let descricao = Column("notas")
        static let anotacao = Column("anotacao")
        static let pago = Column("pago")
        static let dividido = Column("dividido")
        static let transferencia = Column("transferencia")
        static let notificado = Column("notificado")
        static let contaUuid = Column("conta_uuid")
        static let dataCriacao = Column("dataCriacao")
    }
    
    var id: Int64?
    var uuid: String
    var tipo: Int
    var dia: Int
    var mes: Int
    var ano: Int
    var diaCompra: Int
    var mesCompra: Int
    var anoCompra: Int
    var categoriaID: Int
    var recorrente: Int
    var parcelas: Int
    var parcelaMes: String?
    var valor: Double
    var cartaoUuid: String?
    var descricao: String?
    var anotacao: String?
    var pago: Bool
    var dividido: Bool
    var transferencia: Bool
    var notificado: Bool
    var contaUuid: String
    var dataCriacao: String
}



