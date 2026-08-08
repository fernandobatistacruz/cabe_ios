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
    let tipoAnterior: TipoRecorrente
    let contexto: Contexto
    
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
                case .trimestral:
                    return [.trimestral]
                case .semestral:
                    return [.semestral]
                case .anual:
                    return [.anual]
                case .nunca:
                    return [.nunca, .mensal, .parcelado]
                case .parcelado:
                    return [.parcelado]
                default:
                    return [.nunca]
                }
                
            case .conta:
                
                switch tipoAtual {
                case .quinzenal:
                    return [.quinzenal]
                case .semanal:
                    return [.semanal]
                case .mensal:
                    return [.mensal]
                case .semestral:
                    return [.semestral]
                case .trimestral:
                    return [.trimestral]
                case .anual:
                    return [.anual]
                case .nunca:
                    return TipoRecorrente.allCases
                case .parcelado:
                    return [.parcelado]
                }
            }
        }
    }

    var podeAlterarTipo: Bool {
        switch tipoAtual {
        case .nunca:
            return true
        default:
            return contexto == .criacao
        }
    }

    var requerConfirmacaoEscopoAlterar: Bool {
        switch tipoAnterior {
        case .mensal, .semanal, .quinzenal, .parcelado, .trimestral, .semestral, .anual:
            return true
        default:
            return false
        }
    }
    
    var podeAlterarNoParcela: Bool {
        switch tipoAtual {
        case .parcelado:
            if tipoAnterior == .nunca {
                return true
            }
            else {
                return false
            }
        default:
            return false
        }
    }

    static func sugestaoInicial(
        meioPagamento: MeioPagamento?
    ) -> TipoRecorrente {

        guard case .cartao = meioPagamento else {
            return .nunca
        }

        return .nunca
    }
}
