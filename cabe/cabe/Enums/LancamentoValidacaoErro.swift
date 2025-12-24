//
//  LancamentoValidacaoError.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import Foundation

enum LancamentoValidacaoErro: LocalizedError, Identifiable {

    case descricaoVazio
    case vencimentoInvalido
    case fechamentoInvalido
    case limiteInvalido
    case operadoraNaoSelecionada
    case contaNaoSelecionada

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {

        case .descricaoVazio:
            return NSLocalizedString("Informe o nome do cartão.", comment: "")

        case .vencimentoInvalido:
            return NSLocalizedString("Informe um dia de vencimento entre 1 e 31.", comment: "")

        case .fechamentoInvalido:
            return NSLocalizedString("Informe um dia de fechamento entre 1 e 31.", comment: "")

        case .limiteInvalido:
            return NSLocalizedString("Informe um limite válido.", comment: "")

        case .operadoraNaoSelecionada:
            return NSLocalizedString("Selecione a operadora do cartão.", comment: "")

        case .contaNaoSelecionada:
            return NSLocalizedString("Selecione a conta vinculada ao cartão.", comment: "")
        }
    }
}
