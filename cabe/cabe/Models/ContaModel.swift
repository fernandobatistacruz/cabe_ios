import GRDB

struct ContaModel: Identifiable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "conta"
    
    var id: Int64?
    var uuid: String
    var nome: String
    var saldo: Double
    var currencyCode: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case nome
        case saldo
        case currencyCode = "currency_code"
    }
    
    enum Columns {
        static let id = Column("id")
        static let uuid = Column("uuid")
        static let nome = Column("nome")
        static let saldo = Column("saldo")
        static let currencyCode = Column("currency_code")
    }
}
