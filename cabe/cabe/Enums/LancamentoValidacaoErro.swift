//
//  LancamentoValidacaoError.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import Foundation

enum LancamentoValidacaoErro: LocalizedError, Identifiable {

    case descricaoVazio
    case valorInvalido
    case operadoraNaoSelecionada
    case contaNaoSelecionada
    case pagamentoVazio
    case categoriaVazio
    case recorrenciaInvalida
    case parcelaVazia

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
            
        case .descricaoVazio:
            return NSLocalizedString("Informe o nome do cartão.", comment: "")
            
        case .valorInvalido:
            return NSLocalizedString("Informe um valor válido.", comment: "")
            
        case .operadoraNaoSelecionada:
            return NSLocalizedString("Selecione a operadora do cartão.", comment: "")
            
        case .contaNaoSelecionada:
            return NSLocalizedString("Selecione a conta vinculada ao cartão.", comment: "")
        
        case .pagamentoVazio:
            return NSLocalizedString("Selecione a forma de pagamento.", comment: "")
        
        case .categoriaVazio:
            return NSLocalizedString("Selecione uma categoria.", comment: "")
            
        case .recorrenciaInvalida:
            return NSLocalizedString("Selecione uma recorrencia válida.", comment: "")
            
        case .parcelaVazia:
            return NSLocalizedString("Informe o número de parcelas.", comment: "")
        }
    }
}
