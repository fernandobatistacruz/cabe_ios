//
//  MeioPagamento.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/12/25.
//

import SwiftUI

enum MeioPagamento: Identifiable, Equatable, Codable {

    case cartao(CartaoModel)
    case conta(ContaModel)

    var id: String {
        switch self {
        case .cartao(let cartao):
            return "cartao-\(cartao.uuid)"
        case .conta(let conta):
            return "conta-\(conta.uuid)"
        }
    }

    var titulo: String {
        switch self {
        case .cartao(let cartao):
            return cartao.nome
        case .conta(let conta):
            return conta.nome
        }
    }
    
    var subtitulo: LocalizedStringKey {
        switch self {
        case .cartao:
            return "Cartão"
        case .conta:
            return "Conta"
        }
    }

    var cartaoModel: CartaoModel? {
        guard case .cartao(let cartao) = self else { return nil }
        return cartao
    }
    
    var contaModel: ContaModel? {
        guard case .conta(let conta) = self else { return nil }
        return conta
    }

    static func == (lhs: MeioPagamento, rhs: MeioPagamento) -> Bool {
        switch (lhs, rhs) {
        case (.cartao(let c1), .cartao(let c2)):
            return c1.uuid == c2.uuid
        case (.conta(let c1), .conta(let c2)):
            return c1.uuid == c2.uuid
        default:
            return false
        }
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case tipo
        case cartao
        case conta
    }

    enum Tipo: String, Codable {
        case cartao
        case conta
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .cartao(let cartao):
            try container.encode(Tipo.cartao, forKey: .tipo)
            try container.encode(cartao, forKey: .cartao)
        case .conta(let conta):
            try container.encode(Tipo.conta, forKey: .tipo)
            try container.encode(conta, forKey: .conta)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tipo = try container.decode(Tipo.self, forKey: .tipo)
        switch tipo {
        case .cartao:
            let cartao = try container.decode(CartaoModel.self, forKey: .cartao)
            self = .cartao(cartao)
        case .conta:
            let conta = try container.decode(ContaModel.self, forKey: .conta)
            self = .conta(conta)
        }
    }
}

extension UserDefaults {
    func salvarPagamentoPadrao(_ meio: MeioPagamento) {
        if let data = try? JSONEncoder().encode(meio) {
            set(data, forKey: AppSettings.pagamentoPadrao)
        }
    }

    func carregarPagamentoPadrao() -> MeioPagamento? {
        guard let data = data(forKey: AppSettings.pagamentoPadrao),
              let meio = try? JSONDecoder().decode(MeioPagamento.self, from: data) else {
            return nil
        }
        return meio
    }
}
