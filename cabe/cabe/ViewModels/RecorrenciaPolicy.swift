//
//  RecorrenciaPolicy.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 17/01/26.
//

struct RecorrenciaPolicy {
    
    enum Contexto {
        case criacao
        case edicao
    }
    
    let meioPagamento: MeioPagamento?
    let tipoAtual: TipoRecorrente
    let contexto: Contexto

    // MARK: - Recorrências permitidas

    var recorrenciasPermitidas: [TipoRecorrente] {
        guard let meioPagamento else {
            return [.nunca]
        }
        switch contexto {
            
        case .criacao:
            
            switch meioPagamento {
            case .cartao:
                return [.nunca, .mensal, .parcelado]
                
            case .conta:
                return TipoRecorrente.allCases
            }
            
        case .edicao:
            
            switch meioPagamento {
            case .cartao:
                
                switch tipoAtual {
                case .mensal:
                    return [.mensal]
                case .nunca:
                    return [.nunca, .mensal, .parcelado]
                case .parcelado:
                    return [.parcelado]
                default:
                    return [.nunca]
                }
                
            case .conta:
                
                switch tipoAtual {
                case .mensal:
                    return [.mensal]
                case .quinzenal:
                    return [.quinzenal]
                case .semanal:
                    return [.semanal]
                case .nunca:
                    return TipoRecorrente.allCases
                case .parcelado:
                    return [.parcelado]
                }
            }
        }
    }

    // MARK: - Pode alterar tipo?

    var podeAlterarTipo: Bool {
        switch tipoAtual {
        case .nunca:
            return true
        default:
            return contexto == .criacao
        }
    }

    // MARK: - Valor pode afetar série?

    var requerConfirmacaoEscopoAoAlterarValor: Bool {
        switch tipoAtual {
        case .mensal, .semanal, .quinzenal:
            return true
        default:
            return false
        }
    }

    // MARK: - Sugestão inicial

    static func sugestaoInicial(
        meioPagamento: MeioPagamento?
    ) -> TipoRecorrente {

        guard case .cartao = meioPagamento else {
            return .nunca
        }

        return .nunca
    }
}
