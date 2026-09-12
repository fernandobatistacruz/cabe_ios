import GRDB
import Foundation

struct ContaModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "conta"
    
    var id: Int64?
    var uuid: String
    var nome: String
    var saldo: Decimal
    var currencyCode: String
    var logo: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case nome
        case saldo
        case currencyCode = "currency_code"
        case logo = "logo"
    }
    
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let nome = Column("nome")
        static let saldo = Column("saldo")
        static let currencyCode = Column("currency_code")
        static let logo = Column("logo")
    }
    
    var bancoEnum: BancoLogo {
        BancoLogo(rawValue: logo) ?? .outro
    }
}

extension ContaModel {

    var saldoFormatado: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        return formatter.string(from: saldo as NSNumber) ?? "-"
    }
}
