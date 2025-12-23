//
//  LancamentoModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//


import GRDB
import Foundation

struct LancamentoModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    
    static let databaseTableName = "lancamento"
    
    var id: Int64?
    var uuid: String
    var descricao: String
    var anotacao: String
    var tipo: Int
    var transferenciaRaw: Int
    var dia: Int
    var mes: Int
    var ano: Int
    var diaCompra: Int
    var mesCompra: Int
    var anoCompra: Int
    var categoriaID: Int
    var cartaoUuid: String
    var recorrente: Int
    var parcelas: Int
    var parcelaMes: String
    var valor: Double
    var pagoRaw: Int
    var divididoRaw: Int
    var contaUuid: String
    var notificadoRaw: Int
    var dataCriacao: Date
    
    var categoria: CategoriaModel?
    var cartao: CartaoModel?
    var conta: ContaModel?
    var conferido: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case descricao = "notas"
        case anotacao
        case tipo
        case transferenciaRaw = "transferencia"
        case dia
        case mes
        case ano
        case diaCompra
        case mesCompra
        case anoCompra
        case recorrente
        case parcelas
        case parcelaMes
        case valor
        case pagoRaw = "pago"
        case divididoRaw = "dividido"
        case contaUuid = "conta_uuid"
        case categoriaID = "categoria"
        case cartaoUuid = "cartao_uuid"
        case notificadoRaw = "notificado"
        case dataCriacao
    }
    
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let descricao = Column("notas")
        static let anotacao = Column("anotacao")
        static let tipo = Column("tipo")
        static let transferenciaRaw = Column("transferencia")
        static let dia = Column("dia")
        static let mes = Column("mes")
        static let ano = Column("ano")
        static let diaCompra = Column("diaCompra")
        static let mesCompra = Column("mesCompra")
        static let anoCompra = Column("anoCompra")
        static let recorrente = Column("recorrente")
        static let parcelas = Column("parcelas")
        static let parcelaMes = Column("parcelaMes")
        static let valor = Column("valor")
        static let pagoRaw = Column("pago")
        static let divididoRaw = Column("dividido")
        static let contaUuid = Column("conta_uuid")
        static let categoriaID = Column("categoria")
        static let cartaoUuid = Column("cartao_uuid")
        static let notificadoRaw = Column("notificado")
        static let dataCriacao = Column("dataCriacao")
    }
}

extension LancamentoModel {
    var dataCompleta: Date {
        var components = DateComponents()
        components.day = dia
        components.month = mes
        components.year = ano
        return Calendar.current.date(from: components) ?? .now
    }
}

extension LancamentoModel {
    var dataAgrupamento: Date {
        var components = DateComponents()

        if let cartao = cartao {
            components.day = cartao.vencimento
        } else {
            components.day = dia
        }

        components.month = mes
        components.year = ano

        return Calendar.current.date(from: components) ?? .now
    }
}

extension LancamentoModel {
    var pago: Bool {
        pagoRaw == 1
    }
}

extension LancamentoModel {
    var dividido: Bool{
        divididoRaw == 1
    }
}

extension LancamentoModel {
    var notificado: Bool{
        notificadoRaw == 1
    }
}

extension LancamentoModel {
    var transferencia: Bool{
        transferenciaRaw == 1
    }
}
