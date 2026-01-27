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
    var notificacaoLida: Bool {
        get { notificacaoLidaRaw == 1 }
        set { notificacaoLidaRaw = newValue ? 1 : 0 }
    }
}

extension LancamentoModel {
    var pago: Bool {
        get { pagoRaw == 1 }
        set { pagoRaw = newValue ? 1 : 0 }
    }
}

extension LancamentoModel {
    var dividido: Bool {
        get { divididoRaw == 1 }
        set { divididoRaw = newValue ? 1 : 0 }
    }
}

extension LancamentoModel {
    var transferencia: Bool{
        transferenciaRaw == 1
    }
}

extension LancamentoModel {
    var valorComSinal: Decimal {
        tipo == Tipo.despesa.rawValue ? -valor : valor
    }
}

extension LancamentoModel {
    var tipoRecorrente: TipoRecorrente {
        TipoRecorrente(rawValue: recorrente) ?? .nunca
    }
}

extension LancamentoModel {
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
}

extension LancamentoModel {

    var dataVencimentoCartao: Date? {
        guard
            let cartao = cartao,
            cartao.vencimento > 0
        else { return nil }

        return Calendar.current.date(
            from: DateComponents(
                year: ano,
                month: mes,
                day: cartao.vencimento
            )
        )
    }
}

extension LancamentoModel {
    
    var dataCompra: Date? {
            Calendar.current.date(from: DateComponents(
                year: anoCompra,
                month: mesCompra,
                day: diaCompra
            ))
        }

    var dataCompraFormatada: String {
        guard let data = Calendar.current.date(from: DateComponents(
            year: anoCompra,
            month: mesCompra,
            day: diaCompra
        )) else {
            return "—" // placeholder caso algum valor esteja ausente
        }

        return data.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
}

extension LancamentoModel {

    var dataVencimentoFormatada: String {
        guard let data = Calendar.current.date(from: DateComponents(
            year: ano,
            month: mes,
            day: dia
        )) else {
            return "—" // placeholder caso algum valor esteja ausente
        }

        return data.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
}

extension LancamentoModel {

    var dataCriacaoDate: Date {

        if let date = AppDateFormatter.iso8601WithFraction.date(from: dataCriacao) {
            return date.apenasData()
        }

        if let date = AppDateFormatter.iso8601.date(from: dataCriacao) {
            return date.apenasData()
        }

        let legacy = DateFormatter()
        legacy.locale = Locale(identifier: "en_US_POSIX")
        legacy.dateFormat = "yyyy-MM-dd"

        if let date = legacy.date(from: dataCriacao) {
            return date.apenasData()
        }

        return .distantPast
    }
}

extension LancamentoModel {
    var dataCriacaoFormatada: String {
        return dataCriacaoDate.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
}

private let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

extension Date {
    func apenasData(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
}

extension LancamentoModel {
    var valorParaSaldo: Decimal {
        dividido ? (valorComSinal / 2) : valorComSinal
    }
}
