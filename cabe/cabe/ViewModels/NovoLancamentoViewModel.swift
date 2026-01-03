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
    
    @Published var descricao: String = ""
    @Published var categoria: CategoriaModel?
    @Published var tipo: Tipo = .despesa
    @Published var valorTexto: String = ""
    @Published var dividida: Bool = false
    @Published var pago: Bool = false
    @Published var dataLancamento: Date = Date()
    @Published var dataFatura: Date = Date()
    @Published var anotacao: String = ""
    @Published var recorrente: TipoRecorrente = .nunca
    @Published var pagamentoSelecionado: MeioPagamento?
    @Published var parcelaTexto: String = ""


    // MARK: - Conversões (usando seu utils)

    /// Converte o texto digitado para Double respeitando o Locale
       
    var valorDecimal: Decimal? {
        NumberFormatter.decimalInput
            .number(from: valorTexto)?
            .decimalValue
    }

    
    var parcelaInt: Int {
        guard let value = Int(parcelaTexto),
              (1...31).contains(value) else {
            return 1
        }
        return value
    }

    /// Usado ao carregar dados do banco (edição)
    func setLimite(_ value: Decimal) {
        valorTexto = NumberFormatter.decimalInput
            .string(from: value as NSDecimalNumber) ?? ""
    }


    // MARK: - Validação

    func validar() -> LancamentoValidacaoErro? {

        if descricao.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .descricaoVazio
        }

        guard let limite = valorDecimal, limite > 0 else {
            return .valorInvalido
        }
        
        if(pagamentoSelecionado == nil) {
            return .pagamentoVazio
        }
        
        if(categoria == nil) {
            return .pagamentoVazio
        }

        return nil
    }

    /// Usado pelo `.disabled`
    var formValido: Bool {
        validar() == nil
    }
    
    func reset() {
        valorTexto = ""
        descricao = ""
        anotacao = ""
        categoria = nil
        pagamentoSelecionado = nil
        pagamentoSelecionado = nil
        dividida = false
        pago = false
        dataLancamento = Date()
        dataFatura = Date()
        recorrente = .nunca
        parcelaTexto = ""
    }


    // MARK: - Construção segura do Model

    func construirLancamento(uuid: String, dia: Int, mes: Int, ano: Int, diaCompra: Int, mesCompra: Int, anoCompra: Int, parcelaMes: String) throws -> LancamentoModel {

        if let erro = validar() {
            throw erro
        }

        return LancamentoModel(
            uuid: uuid,
            descricao: descricao,
            anotacao: anotacao,
            tipo: tipo.rawValue,
            transferenciaRaw: 0,
            dia: dia,
            mes: mes,
            ano: ano,
            diaCompra: diaCompra,
            mesCompra: mesCompra,
            anoCompra: anoCompra,
            categoriaID: categoria!.id!,
            cartaoUuid: pagamentoSelecionado?.cartaoModel?.uuid ?? "",
            recorrente: recorrente.rawValue,
            parcelas: parcelaInt,
            parcelaMes: parcelaMes,
            valor: valorDecimal ?? 0.0,
            pagoRaw: 0,
            divididoRaw: dividida ? 1 : 0,
            contaUuid: pagamentoSelecionado?.contaModel?.uuid ?? "",
            notificadoRaw: 0,
            dataCriacao: Date()
        )
    }
}
