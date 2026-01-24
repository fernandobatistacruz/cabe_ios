//
//  EditarLancamentoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//
//
//  EditarLancamentoView.swift
//  cabe
//

import SwiftUI

struct EditarLancamentoView: View {

    let lancamento: LancamentoModel
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: NovoLancamentoViewModel
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?
    @State private var mostrarCalendario = false
    @State private var isSaving = false
    @State private var escopoEdicao: EscopoEdicaoRecorrencia?
    @State private var mostrarConfirmacaoEscopo = false

    // MARK: - Init
    init(lancamento: LancamentoModel, repository: LancamentoRepository) {
        self.lancamento = lancamento
        _vm = StateObject(
            wrappedValue: NovoLancamentoViewModel(
                lancamento: lancamento,
                repository: repository)
        )
    }
    
    private var valorAlterado: Bool {
        vm.valor != lancamento.valor
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Form {

                        // MARK: - Dados básicos
                        Section {
                            TextField("Descrição", text: $vm.descricao)

                            Button {
                                sheetAtivo = .categoria
                            } label: {
                                HStack {
                                    Text("Categoria")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    
                                    Text(vm.categoria?.nome ?? "Selecione")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }
                        }

                        // MARK: - Pagamento
                        Section {
                            Button {
                                sheetAtivo = .pagamento
                            } label: {
                                HStack {
                                    Text("Pagamento")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(vm.pagamentoSelecionado?.titulo ?? "Selecione")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.footnote)
                                }
                            }

                            if vm.pagamentoSelecionado?.cartaoModel != nil {
                                Button {
                                    sheetAtivo = .fatura
                                } label: {
                                    HStack {
                                        Text("Fatura")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(
                                            vm.dataFatura.formatted(
                                                .dateTime.month(.wide).year()
                                            )
                                            .capitalizingFirstLetter()
                                        )
                                        .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.footnote)
                                    }
                                }
                            }

                            if vm.tipo == .despesa {
                                Toggle("Dividida", isOn: $vm.dividida)
                            }
                            
                            
                            if vm.recorrenciaPolicy.podeAlterarTipo {
                                Picker("Repete", selection: $vm.recorrente) {
                                    ForEach(vm.recorrenciasDisponiveis, id: \.self) { tipo in
                                        Text(tipo.titulo)
                                            .tag(tipo)
                                    }
                                }
                            } else {
                                HStack {
                                    Text("Repete")
                                    Spacer()
                                    Text(vm.recorrente.titulo)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if vm.podeAlterarNoParcela {
                                TextField("Número de parcelas", text: $vm.parcelaTexto)
                                    .keyboardType(.numberPad)
                            }

                            TextField("Valor", text: $vm.valorTexto)
                            .keyboardType(.numberPad)
                            .onChange(of: vm.valorTexto) { novoValor in
                                vm.atualizarValor(novoValor)
                            }

                            Toggle("Pago", isOn: $vm.pago)

                            Button {
                                mostrarCalendario.toggle()
                            } label: {
                                HStack {
                                    Text(vm.pagamentoSelecionado?.cartaoModel == nil ? "Vencimento" : "Data da Compra")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(vm.data.formatted(date: .abbreviated, time: .omitted))")
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
                                    selection: $vm.data,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                            }
                        }

                        // MARK: - Anotação
                        Section {
                            ZStack(alignment: .topLeading) {
                                if vm.anotacao.isEmpty {
                                    Text("Anotação")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                }
                                TextEditor(text: $vm.anotacao)
                                    .frame(minHeight: 80)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Editar Lançamento")
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
                        ZoomPagamentoView(
                            selecionado: $vm.pagamentoSelecionado
                        )

                    case .fatura:
                        ZoomCalendarioView(
                            dataInicial: vm.dataFatura,
                            onConfirm: { vm.dataFatura = $0 }
                        )
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.hidden)
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
                        Task {
                            if valorAlterado && vm.recorrenciaPolicy.requerConfirmacaoEscopoAoAlterarValor {
                                mostrarConfirmacaoEscopo = true
                                return
                            }

                            await salvarEdicao(escopo: .somenteEste)
                        }
                    } label: {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        }
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
        .onChange(of: vm.pagamentoSelecionado) { _ in
            vm.ajustarRecorrenciaSeNecessario()
            vm.sugerirDataFatura()
        }
        .alert(
            "Este lançamento faz parte de uma recorrência",
            isPresented: $mostrarConfirmacaoEscopo
        ) {
            Button("Somente este") {
                salvarAsync(.somenteEste)
            }
            Button("Este e próximos") {
                salvarAsync(.esteEProximos)
            }
            Button("Todos") {
                salvarAsync(.todos)
            }
            Button("Cancelar", role: .cancel) {}
        }
         
    }
    
    private func salvarAsync(_ escopo: EscopoEdicaoRecorrencia) {
        Task {
            await salvarEdicao(escopo: escopo)
        }
    }
    
    private func salvarEdicao(
        escopo: EscopoEdicaoRecorrencia
    ) async {

        do {
            isSaving = true

            try vm.validarRecorrencia()
                       
            var editado = lancamento
            try vm.aplicarEdicao(no: &editado)

            // Atualiza o lançamento atual e os recorrentes com base no escopo
            try await vm.repository.editar(
                lancamento: editado,
                escopo: escopo
            )

            // Se mudou recorrencia de nunca para outro tipo, cria os próximos lançamentos sem duplicar o atual
            if vm.recorrente != .nunca && lancamento.recorrente != editado.recorrente {
                await vm.salvar(desconsiderarPrimeiro: true)
            }
            
            isSaving = false
            dismiss()

        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro ao editar lançamento", error)
        }

        
    }
}

