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
    @Published var data: Date = Date()
    @Published var dataFatura: Date = Date()
    @Published var anotacao: String = ""
    @Published var recorrente: TipoRecorrente = .nunca    
    @Published var parcelaTexto: String = ""
    @Published var pagamentoSelecionado: MeioPagamento? = UserDefaults.standard.carregarPagamentoPadrao()
    @Published var erroValidacao: LancamentoValidacaoErro?
    
    private let contexto: RecorrenciaPolicy.Contexto
    private var uuidEdicao: String = ""
    private let lancamentoEdicao : LancamentoModel?
    let repository: LancamentoRepository
    
    // MARK: - Init

    /// Cadastro
    init(repository: LancamentoRepository) {
        self.repository = repository
        self.contexto = .criacao
        self.lancamentoEdicao = nil        
        sugerirDataFatura()
        
        // sugestão inicial de recorrência
        self.recorrente = RecorrenciaPolicy
            .sugestaoInicial(meioPagamento: pagamentoSelecionado)
    }

    /// Edição
    init(lancamento: LancamentoModel, repository: LancamentoRepository) {
        self.repository = repository
        self.lancamentoEdicao = lancamento
        self.contexto = .edicao
        self.descricao = lancamento.descricao
        self.anotacao = lancamento.anotacao
        self.tipo = Tipo(rawValue: lancamento.tipo) ?? .despesa
        self.dividida = lancamento.divididoRaw == 1
        self.pago = lancamento.pagoRaw == 1
        
        self.categoria = lancamento.categoria

        if lancamento.cartao != nil {
            self.data = Calendar.current.date(
                from: DateComponents(
                    year: lancamento.anoCompra,
                    month: lancamento.mesCompra,
                    day: lancamento.diaCompra
                )
            ) ?? Date()
        } else {
            self.data = Calendar.current.date(
                from: DateComponents(
                    year: lancamento.ano,
                    month: lancamento.mes,
                    day: lancamento.dia
                )
            ) ?? Date()
        }

        self.dataFatura = Calendar.current.date(
            from: DateComponents(
                year: lancamento.ano,
                month: lancamento.mes,
                day: lancamento.dia
            )
        ) ?? Date()

        self.recorrente = TipoRecorrente(rawValue: lancamento.recorrente) ?? .nunca
        self.parcelaTexto = String(lancamento.parcelas)

        self.valorTexto = NumberFormatter.decimalInput
            .string(from: lancamento.valor as NSDecimalNumber) ?? ""
        
        carregarPagamento(from: lancamento)
        configurarValorInicial(lancamento)
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
            .formatter(currencyCode: Locale.systemCurrencyCode)
            .string(from: valorDecimal as NSDecimalNumber) ?? ""
    }
    
    private func configurarValorInicial(_ lancamento: LancamentoModel) {
        valor = lancamento.valor

        valorTexto = CurrencyFormatter
            .formatter(currencyCode: lancamento.currencyCode)
            .string(from: valor as NSDecimalNumber) ?? ""
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
              (1...600).contains(value) else {
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
        categoria = nil
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
            dataCriacao: DataCivil.hojeString(),
            notificacaoLidaRaw: 0,
            currencyCode: Locale.current.currency?.identifier ?? Locale.systemCurrencyCode
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
        
        guard let meioPagamento = pagamentoSelecionado else { return }
        let calendar = Calendar.current
        var componentesVencimento = calendar.dateComponents([.year, .month], from: Date())
        var componentesDataCompra = calendar.dateComponents([.year, .month], from: Date())

        switch meioPagamento {
        case .cartao:
            let diaVencimento = meioPagamento.cartaoModel?.vencimento ?? 1
            componentesVencimento = calendar.dateComponents([.year, .month, .day], from: dataFatura)
            componentesVencimento.day = diaVencimento            
            componentesDataCompra = calendar.dateComponents([.year, .month, .day], from: data)
        case .conta:
            componentesVencimento = calendar.dateComponents([.year, .month, .day], from: data)
            componentesDataCompra = calendar.dateComponents([.year, .month, .day], from: data)
        }
        
        lancamento.dia = componentesVencimento.day ?? 1
        lancamento.mes = componentesVencimento.month ?? 1
        lancamento.ano = componentesVencimento.year ?? 1990
                
        lancamento.diaCompra = componentesDataCompra.day ?? 1
        lancamento.mesCompra = componentesDataCompra.month ?? 1
        lancamento.anoCompra = componentesDataCompra.year ?? 1990

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
        lancamento.cartao = pagamentoSelecionado?.cartaoModel
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
            let dataInicial: Date
            let diaVencimento: Int

            switch meioPagamento {
            case .cartao:
                dataInicial = dataFatura
                diaVencimento = meioPagamento.cartaoModel?.vencimento ?? 1
            case .conta:
                dataInicial = data
                diaVencimento = calendar.component(.day, from: data)
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

                    let compra = calendar.dateComponents([.day, .month, .year], from: data)

                    let lancamento = try construirLancamento(
                        uuid: uuid,
                        dia: componentes.day ?? 1,
                        mes: componentes.month ?? 1,
                        ano: componentes.year ?? 1990,
                        diaCompra: compra.day ?? 1,
                        mesCompra: compra.month ?? 1,
                        anoCompra: compra.year ?? 1990,
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
            var dataAtual = data

            guard let dataFinal = calendar.date(byAdding: .year, value: 10, to: dataAtual) else { return }
            let uuid = desconsiderarPrimeiro ? uuidEdicao : UUID().uuidString
            var isPrimeiro: Bool = true

            do {
                while dataAtual <= dataFinal {
                    let componentes = calendar.dateComponents([.day, .month, .year], from: dataAtual)

                    let lancamento = try construirLancamento(
                        uuid: uuid,
                        dia: componentes.day ?? 1,
                        mes: componentes.month ?? 1,
                        ano: componentes.year ?? 1990,
                        diaCompra: componentes.day ?? 1,
                        mesCompra: componentes.month ?? 1,
                        anoCompra: componentes.year ?? 1990,
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
            let dataInicial: Date

            switch meio {
            case .cartao:
                var componentes = calendar.dateComponents([.year, .month], from: dataFatura)
                componentes.day = meio.cartaoModel?.vencimento ?? 1
                guard let dataCartao = calendar.date(from: componentes) else { return }
                dataInicial = dataCartao
            case .conta:
                dataInicial = data
            }

            let compra = calendar.dateComponents([.day, .month, .year], from: data)
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

