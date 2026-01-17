//
//  NovoLancamentoViewModel.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 23/12/25.
//

import Foundation
import Combine

@MainActor
final class NovoLancamentoViewModel: ObservableObject {

    // MARK: - Inputs da tela

    @Published var descricao: String = ""
    @Published var categoria: CategoriaModel?
    @Published var tipo: Tipo = .despesa
    @Published var valorTexto: String = ""
    @Published var valor: Decimal = 0
    @Published var dividida: Bool = false
    @Published var pago: Bool = false
    @Published var dataLancamento: Date = Date()
    @Published var dataFatura: Date = Date()
    @Published var anotacao: String = ""
    @Published var recorrente: TipoRecorrente = .nunca    
    @Published var parcelaTexto: String = ""
    @Published var pagamentoSelecionado: MeioPagamento? = UserDefaults.standard.carregarPagamentoPadrao()

    // MARK: - Init

    /// Cadastro
    init() {
        configurarValorInicial(0)
        sugerirDataFatura()
    }

    /// Edição
    init(lancamento: LancamentoModel) {
        self.descricao = lancamento.descricao
        self.anotacao = lancamento.anotacao
        self.tipo = Tipo(rawValue: lancamento.tipo) ?? .despesa
        self.dividida = lancamento.divididoRaw == 1
        self.pago = lancamento.pagoRaw == 1
        
        self.categoria = lancamento.categoria

        self.dataLancamento = Calendar.current.date(
            from: DateComponents(
                year: lancamento.ano,
                month: lancamento.mes,
                day: lancamento.dia
            )
        ) ?? Date()

        self.dataFatura = Calendar.current.date(
            from: DateComponents(
                year: lancamento.anoCompra,
                month: lancamento.mesCompra,
                day: lancamento.diaCompra
            )
        ) ?? Date()

        self.recorrente = TipoRecorrente(rawValue: lancamento.recorrente) ?? .nunca
        self.parcelaTexto = String(lancamento.parcelas)

        self.valorTexto = NumberFormatter.decimalInput
            .string(from: lancamento.valor as NSDecimalNumber) ?? ""
        
        carregarPagamento(from: lancamento)
        configurarValorInicial(lancamento.valor)
    }
    
    func atualizarValor(_ novoTexto: String) {
        // remove tudo que não for número
        let numeros = novoTexto.filter { $0.isNumber }

        let centavos = Decimal(Int(numeros) ?? 0)
        let valorDecimal = centavos / 100

        valor = valorDecimal

        valorTexto = CurrencyFormatter
            .formatter(for: .current)
            .string(from: valorDecimal as NSDecimalNumber) ?? ""
    }
    
    private func configurarValorInicial(_ valorInicial: Decimal = 0) {
        valor = valorInicial

        valorTexto = CurrencyFormatter
            .formatter(for: .current)
            .string(from: valorInicial as NSDecimalNumber) ?? ""
    }
    
    func carregarPagamento(from lancamento: LancamentoModel) {
        if let cartao = lancamento.cartao {
            self.pagamentoSelecionado = .cartao(cartao)
            return
        }

        if let conta = lancamento.conta {
            self.pagamentoSelecionado = .conta(conta)
            return
        }

        self.pagamentoSelecionado = nil
    }


    var parcelaInt: Int {
        guard let value = Int(parcelaTexto),
              (1...31).contains(value) else {
            return 1
        }
        return value
    }

    // MARK: - Validação

    func validar() -> LancamentoValidacaoErro? {

        if descricao.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .descricaoVazio
        }

        if valor == 0 {
            return .valorInvalido
        }

        if pagamentoSelecionado == nil {
            return .pagamentoVazio
        }

        if categoria == nil {
            return .categoriaVazio
        }

        return nil
    }

    var formValido: Bool {
        validar() == nil
    }

    // MARK: - Reset (usado após salvar)

    func reset() {
        descricao = ""
        anotacao = ""
        valorTexto = ""
        parcelaTexto = ""
        categoria = nil
        pagamentoSelecionado = nil
        dividida = false
        pago = false
        dataLancamento = Date()
        dataFatura = Date()
        recorrente = .nunca
    }

    // MARK: - Criação

    func construirLancamento(
        uuid: String,
        dia: Int,
        mes: Int,
        ano: Int,
        diaCompra: Int,
        mesCompra: Int,
        anoCompra: Int,
        parcelaMes: String
    ) throws -> LancamentoModel {

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
            valor: valor,
            pagoRaw: pago ? 1 : 0,
            divididoRaw: dividida ? 1 : 0,
            contaUuid: pagamentoSelecionado?.contaModel?.uuid ?? "",
            dataCriacao: Date().description,
            notificacaoLidaRaw: 0,
            currencyCode: Locale.current.currency?.identifier ?? "USD"
        )
    }

    // MARK: - Edição

    func aplicarEdicao(
        no lancamento: inout LancamentoModel
    ) throws {

        if let erro = validar() {
            throw erro
        }

        lancamento.descricao = descricao
        lancamento.anotacao = anotacao
        lancamento.valor = valor
        lancamento.divididoRaw = dividida ? 1 : 0
        lancamento.pagoRaw = pago ? 1 : 0
        lancamento.categoriaID = categoria?.id ?? lancamento.categoriaID
        lancamento.cartaoUuid = pagamentoSelecionado?.cartaoModel?.uuid ?? ""
        lancamento.contaUuid = pagamentoSelecionado?.contaModel?.uuid ?? ""
    }
    
    func sugerirDataFatura() {
        guard case let .cartao(cartao) = pagamentoSelecionado else { return }

        let calendar = Calendar.current
        let hoje = Date()

        let diaHoje = calendar.component(.day, from: hoje)

        var componentes = calendar.dateComponents([.year, .month], from: hoje)

        if diaHoje > cartao.fechamento {
            // Fatura já fechou → próximo mês
            componentes.month = (componentes.month ?? 1) + 1
        }

        componentes.day = cartao.vencimento

        if let dataSugerida = calendar.date(from: componentes) {
            self.dataFatura = dataSugerida
        }
    }
}

