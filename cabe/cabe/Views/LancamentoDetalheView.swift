//
//  LancamentoDetalheView.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 03/01/26.
//

import SwiftUI

struct LancamentoDetalheView: View {

    let lancamento: LancamentoModel
    @State private var mostrarEdicao = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    
                    Image(systemName: lancamento.categoria?.getIcone().systemName ?? "",)
                        .foregroundColor(lancamento.categoria?.getCor().cor)
                        .font(.system(size: 30))
                    VStack (alignment: .leading){
                        Text(lancamento.descricao)
                            .font(.title2.bold())
                        Text(lancamento.categoria?.nome ?? "")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(
                        lancamento.valorComSinal,
                        format: .currency(
                            code: lancamento.cartao?.conta?.currencyCode ?? "BRL"
                        )
                    )
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                }
                
            }
            Section(header: Text("Geral")) {
                HStack {
                    Text("Situação")
                    Spacer()
                    Text(lancamento.pago ? String(localized: "Pago") : String(localized: "Não Pago"))
                        .foregroundColor(.secondary)
                }
             
                HStack {
                    Text("Repete")
                    Spacer()
                    Text(lancamento.tipoRecorrente.titulo)
                        .foregroundColor(.secondary)
                }
                
                if(lancamento.cartao != nil) {
                    HStack {
                        Text("Pago com Cartão")
                        Spacer()
                        Text(lancamento.cartao?.nome ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                } else {
                    HStack {
                        Text("Pago com Conta")
                        Spacer()
                        Text(lancamento.conta?.nome ?? "")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Vencimento")
                        Spacer()
                        Text(lancamento.dataVencimentoFormatada)
                            .foregroundColor(.secondary)
                    }
                    
                }
                if(lancamento.dividido) {
                    HStack (){
                        Text("Dividido")
                        Spacer()
                        Text(lancamento.valorComSinal/2, format: .currency(code: lancamento.cartao?.conta?.currencyCode ?? "BRL"))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if (lancamento.cartao != nil){
                Section(header: Text("Cartão de Crédito")) {
                    HStack {
                        Text("Fatura")
                        Spacer()
                        Text(lancamento.dataFaturaFormatada)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Data da Compra")
                        Spacer()
                        Text(lancamento.dataCompraFormatada)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            
            Section(header: Text("Anotação")) {
                HStack {
                    Text(lancamento.anotacao) // caso seja opcional
                        .font(.body)                 // ajuste de fonte
                        .foregroundColor(.primary)   // cor do texto
                        .multilineTextAlignment(.leading) // alinhamento
                        .lineLimit(nil)              // permite várias linhas
                        .fixedSize(horizontal: false, vertical: true) // faz o Text crescer verticalmente

                }
            }
            
        }
        .navigationTitle("Detalhar Lançamento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "pencil")
                    .onTapGesture {
                        mostrarEdicao = true
                    }
            }
        }
        .sheet(isPresented: $mostrarEdicao) {
            EditarLancamentoView(lancamento: lancamento)
        }
    }
}
