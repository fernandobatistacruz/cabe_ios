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
    var categoriaID: Int64
    var cartaoUuid: String
    var recorrente: Int
    var parcelas: Int
    var parcelaMes: String
    var valor: Decimal
    var pagoRaw: Int
    var divididoRaw: Int
    var contaUuid: String
    var dataCriacao: String
    var notificacaoLidaRaw: Int
    var currencyCode: String
    
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
        case dataCriacao
        case notificacaoLidaRaw = "notificado"
        case currencyCode = "currency_code"
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
        static let dataCriacao = Column("dataCriacao")
        static let notificacaoLidaRaw = Column("notificado")
        static let currencyCode = Column("currency_code")
    }    
}

extension LancamentoModel {
    
    var notificacaoLida: Bool {
        get { notificacaoLidaRaw == 1 }
        set { notificacaoLidaRaw = newValue ? 1 : 0 }
    }
    
    var pago: Bool {
        get { pagoRaw == 1 }
        set { pagoRaw = newValue ? 1 : 0 }
    }
    
    var dividido: Bool {
        get { divididoRaw == 1 }
        set { divididoRaw = newValue ? 1 : 0 }
    }
    
    var transferencia: Bool{
        transferenciaRaw == 1
    }
    
    var valorDividido: Decimal {
        let v = dividido ? (valor / 2) : valor
        return v.arredondadoMoeda()
    }
    
    var valorComSinal: Decimal {
        tipo == Tipo.despesa.rawValue ? -valor : valor
    }
    
    var valorComSinalDividido: Decimal {
        let v = dividido ? (valor / 2) : valor
        return tipo == Tipo.despesa.rawValue ? -v.arredondadoMoeda() : v.arredondadoMoeda()
    }
    
    var tipoRecorrente: TipoRecorrente {
        TipoRecorrente(rawValue: recorrente) ?? .nunca
    }
    
    var dataVencimento: Date {
        var components = DateComponents()

        if let cartao = cartao {
            components.day = cartao.vencimento > 0 ? cartao.vencimento : 1
        } else {
            components.day = dia
        }

        components.month = mes
        components.year = ano

        return Calendar.current.date(from: components) ?? .now
    }
    
    var dataVencimentoFormatada: String {
        return dataVencimento.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
    
    var dataFaturaFormatada: String {
        guard let dia = cartao?.vencimento,
              let data = Calendar.current.date(from: DateComponents(
                  year: ano,
                  month: mes,
                  day: dia
              )) else {
            return "—"
        }
        
        return data.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
    
    var dataCompra: Date {
            Calendar.current.date(from: DateComponents(
                year: anoCompra,
                month: mesCompra,
                day: diaCompra
            )) ?? Date()
        }

    var dataCompraFormatada: String {
        return dataCompra.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
    
    var dataCriacaoDate: Date {
        if let date = DataCivil.extrairDataCivil(dataCriacao) {
            return date
        }
        
        return Calendar(identifier: .gregorian)
            .startOfDay(for: Date())
    }
    
    var dataCriacaoFormatada: String {
        let c = Calendar.current.dateComponents([.day, .month, .year], from: dataCriacaoDate)
        
        if c.day == 1 && c.month == 1 && c.year == 1990 {
            return "-"
        }
                
        return String(
            format: "%02d/%02d/%04d",
            c.day!,
            c.month!,
            c.year!
        )
    }    
}
