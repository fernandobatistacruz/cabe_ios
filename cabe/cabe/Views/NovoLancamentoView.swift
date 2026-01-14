//
//  NovoLancamentoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//

import SwiftUI

struct NovoLancamentoView: View {
   
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = NovoLancamentoViewModel()
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?
    @State private var mostrarCalendario = false
    @State private var mostrarZoomCategoria = false
    @State private var showCalendar = false
   
    var body: some View {
        NavigationStack{
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Tipo", selection: $vm.tipo) {
                        ForEach(Tipo.allCases.reversed(), id: \.self) { tipo in
                            Text(tipo.descricao).tag(tipo)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)
                    .onChange(of: vm.tipo) { novoTipo in
                        vm.reset()
                        mostrarCalendario = false
                    }

                    
                    Form {
                        Section{
                            TextField("Descrição", text: $vm.descricao)
                            Button {
                                sheetAtivo = .categoria
                            } label: {
                                HStack {
                                    Text("Categoria")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    
                                    let nome = vm.categoria?.pai == nil
                                    ? vm.categoria?.nome ?? String(
                                        localized: "Nenhuma"
                                    )
                                        : vm.categoria?.nomeSubcategoria ?? String(localized: "Nenhuma")

                                    Text(nome)
                                    .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                        }
                        Section{
                            Button {
                                sheetAtivo = .pagamento
                            } label: {
                                HStack {
                                    Text("Pagamento")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(vm.pagamentoSelecionado?.titulo ??  String(
                                        localized: "Nenhuma")
                                    ).foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                            if((vm.pagamentoSelecionado?.cartaoModel != nil))
                            {
                                Button {
                                    sheetAtivo = .fatura
                                } label: {
                                    HStack {
                                        Text("Fatura")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(
                                            vm.dataFatura.formatted(
                                                .dateTime
                                                    .month(.wide)
                                                    .year()
                                            )
                                        )
                                        .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                    }
                                }
                            }
                            
                            if(vm.tipo == .despesa){
                                Toggle(isOn: $vm.dividida) {Text("Dividida")}
                            }
                            
                            /* Quando precisar filtar a que aparece no menu
                             
                             var opcoesDisponiveis: [TipoRecorrente] {
                                 if formaPagamento == .cartao {
                                     return TipoRecorrente.allCases
                                 } else {
                                     return TipoRecorrente.allCases.filter { $0 != .parcelado }
                                 }
                             }
                             
                             Picker("Recorrência", selection: $tipoRecorrente) {
                                 ForEach(opcoesDisponiveis) { item in
                                     Text(item.titulo)
                                         .tag(item)
                                 }
                             }
                             .pickerStyle(.menu)
                             .tint(.secondary)
                             
                             */
                            
                            HStack {
                                Picker("Repete", selection: $vm.recorrente) {
                                    ForEach(TipoRecorrente.allCases) { item in
                                        Text(item.titulo)
                                            .tag(item)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.secondary)
                            }
                          
                            TextField("Valor", text: $vm.valorTexto)
                            .keyboardType(.numberPad)
                            .onChange(of: vm.valorTexto) { novoValor in
                                vm.atualizarValor(novoValor)
                            }
                             
                            Toggle(isOn: $vm.pago) {Text("Pago")}
                            
                            Button {
                                mostrarCalendario.toggle()
                            } label: {
                                HStack {
                                    Text("Data")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(vm.dataLancamento.formatted(date: .abbreviated, time: .omitted))")
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 22)
                                                .fill(
                                                    Color(
                                                        uiColor: .secondarySystemFill
                                                    )
                                                )
                                        )
                                }
                            }
                            
                            if mostrarCalendario {
                                DatePicker(
                                    "",
                                    selection: $vm.dataLancamento,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                            }
                            
                        }
                        Section{
                            ZStack(alignment: .topLeading) {
                                if vm.anotacao.isEmpty {
                                    Text("Anotação")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                }
                                TextEditor(text: $vm.anotacao)
                                    .padding(8)
                                    .background(Color.clear)
                            }
                            .frame(minHeight: 80, maxHeight: 100)
                        }
                    }
                }
            }
            .navigationTitle("Nova")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheetAtivo) { sheet in
                NavigationStack {
                    switch sheet {
                    case .categoria:
                        ZoomCategoriaView(
                            categoriaSelecionada: $vm.categoria,
                            tipo: vm.tipo
                        )
                    case .pagamento:
                        ZoomPagamentoView(selecionado: $vm.pagamentoSelecionado)
                    case .fatura:
                        ZoomCalendarioView(
                            dataInicial: vm.dataFatura,
                            onConfirm: { data in
                                vm.dataFatura = data
                            }
                        )
                        .presentationDetents([.medium, .large])
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task{
                            await salvar()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                        
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(!vm.formValido)
                }
            }
            .alert(item: $erroValidacao) { erro in
                Alert(
                    title: Text("Erro"),
                    message: Text(erro.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func salvar() async {
        switch vm.recorrente {
        case .mensal:
            await mensal()
            break
        case .quinzenal:
            await porDias(intervalo: 14)
            break
        case .semanal:
            await porDias(intervalo: 7)
            break
        default:
            await nuncoParcelado()
            break
        }
    }
    
    private func mensal() async {
        guard let meioPagamento = vm.pagamentoSelecionado else { return }

        let calendar = Calendar.current
        let repository = LancamentoRepository()
        let dataInicial: Date
        let diaVencimento: Int

        switch meioPagamento {
        case .cartao:
            dataInicial = vm.dataFatura
            diaVencimento = vm.pagamentoSelecionado?.cartaoModel?.vencimento ?? 1

        case .conta:
            dataInicial = vm.dataLancamento
            diaVencimento = calendar.component(.day, from: vm.dataLancamento)
        }

        guard let dataFinal = calendar.date(
            byAdding: .year,
            value: 10,
            to: dataInicial
        ) else {
            return
        }

        var dataAtual = dataInicial
        let uuid = UUID().uuidString

        do {
            while dataAtual <= dataFinal {

                var componentes = calendar.dateComponents([.year, .month], from: dataAtual)
                componentes.day = diaVencimento

                // Garante data válida (ex: fevereiro)
                guard calendar.date(from: componentes) != nil else {
                    dataAtual = calendar.date(byAdding: .month, value: 1, to: dataAtual)!
                    continue
                }

                let compra = calendar.dateComponents(
                    [.day, .month, .year],
                    from: vm.dataLancamento
                )

                let lancamento = try vm.construirLancamento(
                    uuid: uuid,
                    dia: componentes.day!,
                    mes: componentes.month!,
                    ano: componentes.year!,
                    diaCompra: compra.day!,
                    mesCompra: compra.month!,
                    anoCompra: compra.year!,
                    parcelaMes: ""
                )
               
                try await repository.salvar(lancamento)

                dataAtual = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: dataAtual
                )!
            }

            dismiss()

        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao salvar lançamento", error)
        }
    }

    
    private func porDias(intervalo: Int) async {
        let calendar = Calendar.current
        let repository = LancamentoRepository()
        var dataAtual = vm.dataLancamento

        guard let dataFinal = calendar.date(
            byAdding: .year,
            value: 10,
            to: vm.dataLancamento
        ) else {
            return
        }
        
        let uuid = UUID().uuidString

        do {
            while dataAtual <= dataFinal {

                let componentes = calendar.dateComponents(
                    [.day, .month, .year],
                    from: dataAtual
                )

                let lancamento = try vm.construirLancamento(
                    uuid: uuid,
                    dia: componentes.day ?? 0,
                    mes: componentes.month ?? 0,
                    ano: componentes.year ?? 0,
                    diaCompra: componentes.day ?? 0,
                    mesCompra: componentes.month ?? 0,
                    anoCompra: componentes.year ?? 0,
                    parcelaMes: ""
                )

                try await repository.salvar(lancamento)

                dataAtual = calendar.date(
                    byAdding: .day,
                    value: intervalo,
                    to: dataAtual
                )!
            }

            dismiss()

        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao salvar lançamento", error)
        }
    }

    
    private func nuncoParcelado() async {
        guard let meio = vm.pagamentoSelecionado else { return }

        let calendar = Calendar.current
        let repository = LancamentoRepository()

        let dataInicial: Date

        switch meio {
        case .cartao:
            var componentes = calendar.dateComponents(
                [.year, .month],
                from: vm.dataFatura
            )
            componentes.day = meio.cartaoModel?.vencimento ?? 1

            guard let dataCartao = calendar.date(from: componentes) else {
                return
            }
            dataInicial = dataCartao

        case .conta:
            dataInicial = vm.dataLancamento
        }

        let compra = calendar.dateComponents(
            [.day, .month, .year],
            from: vm.dataLancamento
        )

        var dataAtual = dataInicial
        
        let uuid = UUID().uuidString

        do {
            for parcela in 1...vm.parcelaInt {

                let lancamento = try vm.construirLancamento(
                    uuid: uuid,
                    dia: calendar.component(.day, from: dataAtual),
                    mes: calendar.component(.month, from: dataAtual),
                    ano: calendar.component(.year, from: dataAtual),
                    diaCompra: compra.day!,
                    mesCompra: compra.month!,
                    anoCompra: compra.year!,
                    parcelaMes: "\(parcela)/\(vm.parcelaInt)"
                )

                try await repository.salvar(lancamento)

                dataAtual = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: dataAtual
                )!
            }

            dismiss()

        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao salvar lançamento", error)
        }
    }

}

#Preview {
    NovoLancamentoView()
}

enum NovoLancamentoSheet: Identifiable {
    case categoria
    case pagamento
    case fatura

    var id: Int { hashValue }
}
