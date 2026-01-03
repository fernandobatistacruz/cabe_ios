//
//  EditarLancamentoView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//

import SwiftUI

struct EditarLancamentoView: View {
    
    @State var lancamento: LancamentoModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NovoLancamentoViewModel()
    @State private var sheetAtivo: NovoLancamentoSheet?
    @State private var erroValidacao: LancamentoValidacaoErro?
    @State public var selectedYear = Calendar.current.component(.year, from: Date())
    @State public var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var faturaData = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section{
                    TextField("Nome", text: $viewModel.descricao)
                    
                    
                }
            }
            .navigationTitle("Editar Cartão")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $sheetAtivo) { sheet in
                NavigationStack {
                    switch sheet {
                    case .categoria:
                        CategoriaZoomView(
                            categoriaSelecionada: $viewModel.categoria,
                            tipo: viewModel.tipo
                        )
                    case .pagamento:
                        CategoriaZoomView(
                            categoriaSelecionada: $viewModel.categoria,
                            tipo: viewModel.tipo
                        )
                    case .fatura:                           
                        CalendarioZoomView(
                            dataInicial: faturaData,
                            onConfirm: { data in
                                faturaData = data
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
                        salvar()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(!viewModel.formValido)
                }
            }
            .alert(item: $erroValidacao) { erro in
                Alert(
                    title: Text("Erro"),
                    message: Text(erro.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear(){
                viewModel.descricao = lancamento.descricao
                viewModel.setLimite(lancamento.valor)
            }
        }
    }

    private func salvar() {
       /*
        do {
            var lancamento = try viewModel.construirLancamento()
            lancamento.id = self.lancamento.id
            lancamento.uuid = self.lancamento.uuid
            
            try LancamentoRepository().editar(lancamento)
            dismiss()
        } catch let erro as LancamentoValidacaoErro {
            erroValidacao = erro
        } catch {
            debugPrint("Erro inesperado ao editar lançamento", error)
        }
        */
    }
}
