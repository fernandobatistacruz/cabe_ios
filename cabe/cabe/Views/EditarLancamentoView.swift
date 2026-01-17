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

    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: NovoLancamentoViewModel

    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?
    @State private var mostrarCalendario = false
    @State private var isSaving = false

    // 🔹 Lançamento que será editado
    private let lancamento: LancamentoModel

    // MARK: - Init
    init(lancamento: LancamentoModel) {
        self.lancamento = lancamento
        _vm = StateObject(
            wrappedValue: NovoLancamentoViewModel(lancamento: lancamento)
        )
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
                                    }
                                }
                            }

                            if vm.tipo == .despesa {
                                Toggle("Dividida", isOn: $vm.dividida)
                            }

                            // 🔒 Recorrência NÃO editável
                            HStack {
                                Text("Repete")
                                Spacer()
                                Text(vm.recorrente.titulo)
                                    .foregroundColor(.secondary)
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
                            isSaving = true
                            await salvarEdicao()
                            isSaving = false
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
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
            vm.sugerirDataFatura()
        }
    }

    // MARK: - Salvar edição
    private func salvarEdicao() async {
        do {
            let repository = LancamentoRepository()

            var editado = lancamento
            editado.descricao = vm.descricao
            editado.anotacao = vm.anotacao
            editado.valor = vm.valor
            editado.pago = vm.pago
            editado.dividido = vm.dividida
            editado.categoriaID = vm.categoria?.id ?? editado.categoriaID
            editado.cartaoUuid = vm.pagamentoSelecionado?.cartaoModel?.uuid ?? ""
            editado.contaUuid = vm.pagamentoSelecionado?.contaModel?.uuid ?? ""

            try await repository.editar(editado)
            dismiss()

        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro ao editar lançamento", error)
        }
    }
}
