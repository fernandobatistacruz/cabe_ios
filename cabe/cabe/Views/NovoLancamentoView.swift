//
//  NovoLancamentoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//

import SwiftUI

private enum CampoFoco {
    case descricao
    case parcelas
    case valor
    case anotacao
}

struct NovoLancamentoView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: NovoLancamentoViewModel
    @State var pagamentoSelecionado: MeioPagamento?
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?
    @State private var mostrarCalendario = false
    @State private var mostrarZoomCategoria = false
    @State private var showCalendar = false
    @State private var isSaving = false
    @FocusState private var campoFocado: CampoFoco?
    
    init(repository: LancamentoRepository, meioPagamento: MeioPagamento? = nil) {
        _vm = StateObject(
            wrappedValue: NovoLancamentoViewModel(repository: repository, meioPagamento: meioPagamento)
        )
    }
    
    var body: some View {
        NavigationStack{
            List {
                Section {
                    TextField("Valor", text: $vm.valorTexto)
                        .keyboardType(.numberPad)
                        .focused($campoFocado, equals: .valor)
                        .onChange(of: vm.valorTexto) { novoValor in
                            vm.atualizarValor(novoValor)
                        }
                    
                    TextField("Descrição", text: $vm.descricao)
                        .focused($campoFocado, equals: .descricao)
                        .submitLabel(.next)
                        .textInputAutocapitalization(.words)
                    
                    Button {
                        sheetAtivo = .categoria
                    } label: {
                        HStack {
                            Text("Categoria")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            let nome = vm.categoria?.pai == nil
                            ? vm.categoria?.nome ?? String(
                                localized: "Selecione"
                            )
                            : vm.categoria?.nomeSubcategoria ?? String(localized: "Selecione")
                            
                            Text(nome)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                    }
                }
                Section {
                    Button {
                        sheetAtivo = .pagamento
                    } label: {
                        HStack {
                            Text("Pagamento")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(vm.pagamentoSelecionado?.titulo ??  String(
                                localized: "Selecione")
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
                                    vm.dataFatura
                                        .formatted(
                                            .dateTime
                                                .month(.wide)
                                                .year()
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
                    
                    if(vm.tipo == .despesa){
                        Toggle(isOn: $vm.dividida) {Text("Dividida")}
                    }
                    
                    HStack {
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
                    }
                    
                    if vm.recorrente == .parcelado {
                        TextField("Número de parcelas", text: $vm.parcelaTexto)
                            .keyboardType(.numberPad)
                            .focused($campoFocado, equals: .parcelas)
                    }
                    
                    Toggle(isOn: $vm.pago) {Text("Pago")}
                    
                    Button {
                        mostrarCalendario.toggle()
                    } label: {
                        
                        HStack {
                            Text(vm.pagamentoSelecionado?.cartaoModel == nil ? "Vencimento" : "Data da Compra")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(vm.data.formatted(date: .abbreviated, time: .omitted))")
                                .foregroundColor(
                                    mostrarCalendario ? .accentColor : .primary
                                )
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
                        .frame(height: 340) // fixa altura
                        .clipped()
                        .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                    }
                }
                Section {
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
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .top) {
                Picker("Tipo", selection: $vm.tipo) {
                    ForEach(Tipo.allCases.reversed(), id: \.self) { tipo in
                        Text(tipo.descricao).tag(tipo)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
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
                            await vm.salvar(desconsiderarPrimeiro: false)
                            isSaving = false
                            
                            if vm.erroValidacao == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)                        
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(!vm.formValido || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()

                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                    }
                }
            }
            .alert(item: $erroValidacao) { erro in
                Alert(
                    title: Text("Erro"),
                    message: Text(erro.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
            .task {
                await Task.yield()
                campoFocado = .valor
            }
            .onChange(of: vm.pagamentoSelecionado) { _ in
                vm.sugerirDataFatura()
            }
        }
    }
}


enum NovoLancamentoSheet: Identifiable {
    case categoria
    case pagamento
    case fatura

    var id: Int { hashValue }
}
