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
    @Published var erroValidacao: LancamentoValidacaoErro?
    
    private let contexto: RecorrenciaPolicy.Contexto
    private var uuidEdicao: String = ""
    private let lancamentoEdicao : LancamentoModel?
    
    // MARK: - Init

    /// Cadastro
    init() {
        self.contexto = .criacao
        self.lancamentoEdicao = nil
        configurarValorInicial(0)
        sugerirDataFatura()
        
        // sugestão inicial de recorrência
        self.recorrente = RecorrenciaPolicy
            .sugestaoInicial(meioPagamento: pagamentoSelecionado)
    }

    /// Edição
    init(lancamento: LancamentoModel) {
        self.lancamentoEdicao = lancamento
        self.contexto = .edicao
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
    
    
    var recorrenciaPolicy: RecorrenciaPolicy {
        RecorrenciaPolicy(
            meioPagamento: pagamentoSelecionado,
            tipoAtual: recorrente,
            tipoAnterior: lancamentoEdicao?.tipoRecorrente ?? .nunca,
            contexto: contexto
        )
    }
    

    var recorrenciasDisponiveis: [TipoRecorrente] {
        recorrenciaPolicy.recorrenciasPermitidas
    }
    
    var podeAlterarNoParcela: Bool {
        recorrenciaPolicy.podeAlterarNoParcela
    }
    
    func ajustarRecorrenciaSeNecessario() {

        if !recorrenciasDisponiveis.contains(recorrente) {
            recorrente = recorrenciasDisponiveis.first ?? .nunca
        }

        // Sugestão inteligente: cartão + nunca → parcelado (criação)
        if contexto == .criacao,
           pagamentoSelecionado?.cartaoModel != nil,
           recorrente == .nunca {

            recorrente = .parcelado
        }
    }

    func validarRecorrencia() throws {
        if !recorrenciasDisponiveis.contains(recorrente) {
            throw LancamentoValidacaoErro.recorrenciaInvalida
        }
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
        
        if !recorrenciasDisponiveis.contains(recorrente) {
            return .recorrenciaInvalida
        }
        
        if recorrente == .parcelado && parcelaTexto.isEmpty {
            return .parcelaVazia
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
            valor: valor / Decimal(parcelaInt),
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
        
        uuidEdicao = lancamento.uuid

        lancamento.descricao = descricao
        lancamento.anotacao = anotacao
        lancamento.valor = lancamento.tipoRecorrente == recorrente ? valor : valor / Decimal(parcelaInt)
        lancamento.divididoRaw = dividida ? 1 : 0
        lancamento.pagoRaw = pago ? 1 : 0
        lancamento.recorrente = recorrente.rawValue
        lancamento.parcelas = parcelaInt
        lancamento.parcelaMes = parcelaInt > 1 ? "1/\(parcelaInt)" : ""
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
    
    func salvar(desconsiderarPrimeiro: Bool) async {
        switch recorrente {
        case .mensal:
            await salvarMensal(desconsiderarPrimeiro)
        case .quinzenal:
            await salvarPorDias(desconsiderarPrimeiro, intervalo: 14)
        case .semanal:
            await salvarPorDias(desconsiderarPrimeiro,intervalo: 7)
        default:
            await salvarNuncaParcelado(desconsiderarPrimeiro)
        }
    }

    private func salvarMensal(_ desconsiderarPrimeiro: Bool) async {
            guard let meioPagamento = pagamentoSelecionado else { return }
            let calendar = Calendar.current
            let repository = LancamentoRepository()
            let dataInicial: Date
            let diaVencimento: Int

            switch meioPagamento {
            case .cartao:
                dataInicial = dataFatura
                diaVencimento = meioPagamento.cartaoModel?.vencimento ?? 1
            case .conta:
                dataInicial = dataLancamento
                diaVencimento = calendar.component(.day, from: dataLancamento)
            }

            guard let dataFinal = calendar.date(byAdding: .year, value: 10, to: dataInicial) else { return }
            var dataAtual = dataInicial
            let uuid = desconsiderarPrimeiro ? uuidEdicao : UUID().uuidString
            var isPrimeiro: Bool = true

            do {
                while dataAtual <= dataFinal {
                    var componentes = calendar.dateComponents([.year, .month], from: dataAtual)
                    componentes.day = diaVencimento
                    guard calendar.date(from: componentes) != nil else {
                        dataAtual = calendar.date(byAdding: .month, value: 1, to: dataAtual)!
                        continue
                    }

                    let compra = calendar.dateComponents([.day, .month, .year], from: dataLancamento)

                    let lancamento = try construirLancamento(
                        uuid: uuid,
                        dia: componentes.day!,
                        mes: componentes.month!,
                        ano: componentes.year!,
                        diaCompra: compra.day!,
                        mesCompra: compra.month!,
                        anoCompra: compra.year!,
                        parcelaMes: ""
                    )
                    
                    dataAtual = calendar.date(byAdding: .month, value: 1, to: dataAtual)!
                    
                    if desconsiderarPrimeiro && isPrimeiro {
                        isPrimeiro = false
                        continue
                    } else {
                        try await repository.salvar(lancamento)
                    }
                }
            } catch let erro as LancamentoValidacaoErro {
                erroValidacao = erro
            } catch {
                debugPrint("Erro inesperado ao salvar lançamento", error)
            }
        }

        private func salvarPorDias(_ desconsiderarPrimeiro: Bool, intervalo: Int) async {
            let calendar = Calendar.current
            let repository = LancamentoRepository()
            var dataAtual = dataLancamento

            guard let dataFinal = calendar.date(byAdding: .year, value: 10, to: dataAtual) else { return }
            let uuid = desconsiderarPrimeiro ? uuidEdicao : UUID().uuidString
            var isPrimeiro: Bool = true

            do {
                while dataAtual <= dataFinal {
                    let componentes = calendar.dateComponents([.day, .month, .year], from: dataAtual)

                    let lancamento = try construirLancamento(
                        uuid: uuid,
                        dia: componentes.day ?? 0,
                        mes: componentes.month ?? 0,
                        ano: componentes.year ?? 0,
                        diaCompra: componentes.day ?? 0,
                        mesCompra: componentes.month ?? 0,
                        anoCompra: componentes.year ?? 0,
                        parcelaMes: ""
                    )
                    
                    dataAtual = calendar.date(byAdding: .day, value: intervalo, to: dataAtual)!
                    
                    if desconsiderarPrimeiro && isPrimeiro {
                        isPrimeiro = false
                        continue
                    } else {
                        try await repository.salvar(lancamento)
                    }
                }
            } catch let erro as LancamentoValidacaoErro {
                erroValidacao = erro
            } catch {
                debugPrint("Erro inesperado ao salvar lançamento", error)
            }
        }

        private func salvarNuncaParcelado(_ desconsiderarPrimeiro: Bool) async {
            guard let meio = pagamentoSelecionado else { return }
            let calendar = Calendar.current
            let repository = LancamentoRepository()
            let dataInicial: Date

            switch meio {
            case .cartao:
                var componentes = calendar.dateComponents([.year, .month], from: dataFatura)
                componentes.day = meio.cartaoModel?.vencimento ?? 1
                guard let dataCartao = calendar.date(from: componentes) else { return }
                dataInicial = dataCartao
            case .conta:
                dataInicial = dataLancamento
            }

            let compra = calendar.dateComponents([.day, .month, .year], from: dataLancamento)
            var dataAtual = dataInicial
            let uuid = desconsiderarPrimeiro ? uuidEdicao : UUID().uuidString
            var isPrimeiro: Bool = true
           
            do {
                for parcela in 1...parcelaInt {
                    let lancamento = try construirLancamento(
                        uuid: uuid,
                        dia: calendar.component(.day, from: dataAtual),
                        mes: calendar.component(.month, from: dataAtual),
                        ano: calendar.component(.year, from: dataAtual),
                        diaCompra: compra.day!,
                        mesCompra: compra.month!,
                        anoCompra: compra.year!,
                        parcelaMes: "\(parcela)/\(parcelaInt)"
                    )
                    
                    dataAtual = calendar.date(byAdding: .month, value: 1, to: dataAtual)!
                    
                    if desconsiderarPrimeiro && isPrimeiro {
                        isPrimeiro = false
                        continue
                    } else {
                        try await repository.salvar(lancamento)
                    }
                }
            } catch let erro as LancamentoValidacaoErro {
                erroValidacao = erro
            } catch {
                debugPrint("Erro inesperado ao salvar lançamento", error)
            }
        }
}

extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}

