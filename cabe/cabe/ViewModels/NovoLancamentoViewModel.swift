//
//  NovoLancamentoViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import Foundation
internal import Combine

@MainActor
final class NovoLancamentoViewModel: ObservableObject {

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

    func validar() -> LancamentoValidacaoErro? {

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

    func construirLancamento() throws -> LancamentoModel {

        if let erro = validar() {
            throw erro
        }

        return LancamentoModel(
            uuid: UUID().uuidString,
            descricao: "",
            anotacao: "",
            tipo: 2,
            transferencia: 0,
            dia: 1,
            mes: 1,
            ano: 2025,
            diaCompra: 1,
            mesCompra: 1,
            anoCompra: 2025,
            categoriaID: 1,
            cartaoUuid: "",
            recorrente: 1,
            parcelas: 1,
            parcelaMes: "",
            valor: 100.00,
            pago: 0,
            dividido: 0,
            contaUuid: "",        
            notificado: 0,
            dataCriacao: Date()
        )
    }
}
