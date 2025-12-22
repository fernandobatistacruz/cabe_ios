//
//  NovoCartaoViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/12/25.
//

import Foundation
internal import Combine

@MainActor
final class NovoCartaoViewModel: ObservableObject {

    // MARK: - Inputs da tela
    
    @Published var nome: String = ""
    @Published var operadora: OperadoraCartao?
    @Published var conta: ContaModel?
    
    @Published var vencimentoTexto: String = ""
    @Published var fechamentoTexto: String = ""
    @Published var limiteTexto: String = ""

    // MARK: - Conversões (usando seu utils)
    
    var vencimentoInt: Int? {
        guard let value = Int(vencimentoTexto),
              (1...31).contains(value) else {
            return nil
        }
        return value
    }

    var fechamentoInt: Int? {
        guard let value = Int(fechamentoTexto),
              (1...31).contains(value) else {
            return nil
        }
        return value
    }

    /// Converte o texto digitado para Double respeitando o Locale
    var limiteDouble: Double? {
        NumberFormatter.decimalInput
            .number(from: limiteTexto)?
            .doubleValue
    }

    /// Usado ao carregar dados do banco (edição)
    func setLimite(_ value: Double) {
        limiteTexto = NumberFormatter.decimalInput
            .string(from: NSNumber(value: value)) ?? ""
    }

    // MARK: - Validação

    func validar() -> CartaoValidacaoErro? {

        if nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .nomeVazio
        }

        guard let limite = limiteDouble, limite > 0 else {
            return .limiteInvalido
        }

        guard operadora != nil else {
            return .operadoraNaoSelecionada
        }

        guard conta != nil else {
            return .contaNaoSelecionada
        }
        
        guard vencimentoInt != nil else {
            return .vencimentoInvalido
        }

        guard fechamentoInt != nil else {
            return .fechamentoInvalido
        }

        return nil
    }

    /// Usado pelo `.disabled`
    var formValido: Bool {
        validar() == nil
    }

    // MARK: - Construção segura do Model

    func construirCartao() throws -> CartaoModel {

        if let erro = validar() {
            throw erro
        }

        return CartaoModel(
            uuid: UUID().uuidString,
            nome: nome,
            vencimento: vencimentoInt!,
            fechamento: fechamentoInt!,
            operadora: operadora!.rawValue,
            arquivado: 0,
            contaUuid: conta!.uuid,
            limite: limiteDouble!
        )
    }
}




