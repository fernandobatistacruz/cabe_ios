//
//  LancamentoRow.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 01/02/26.
//

import SwiftUI

struct LancamentoRow: View {
    let lancamento: LancamentoModel   
    let mostrarPagamento: Bool
    let mostrarValores: Bool
    let mostrarData: Bool
    
    init(
        lancamento: LancamentoModel,
        mostrarPagamento: Bool,
        mostrarValores: Bool,
        mostrarData: Bool = false
    ) {
        self.lancamento = lancamento
        self.mostrarPagamento = mostrarPagamento
        self.mostrarValores = mostrarValores
        self.mostrarData = mostrarData
    }

    var body: some View {
        HStack(spacing: 12) {
            if (mostrarPagamento)  {
                Circle()
                    .fill(lancamento.pago ? Color.clear : .accentColor)
                    .frame(width: 12, height: 12)
            }
            let systemName: String = {
                if lancamento.transferencia {
                    return "arrow.left.arrow.right"
                } else {
                    return lancamento.categoria?.getIcone().systemName ?? "questionmark"
                }
            }()

            let color: Color = {
                if lancamento.transferencia {
                    return lancamento.tipo == Tipo.despesa.rawValue ? .red : .green
                } else {
                    return lancamento.categoria?.getCor().cor ?? .primary
                }
            }()

            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                HStack{
                    Text(lancamento.descricao)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.body)
                        .foregroundColor(.primary)
                    if lancamento.recorrente == TipoRecorrente.parcelado.rawValue {
                        Text(lancamento.parcelaMes)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    if lancamento.recorrente == TipoRecorrente.mensal.rawValue ||
                       lancamento.recorrente == TipoRecorrente.quinzenal.rawValue ||
                       lancamento.recorrente == TipoRecorrente.semanal.rawValue
                    {
                        Image(systemName: "repeat")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                if mostrarData {
                    Text(lancamento.dataCompraFormatada)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                else{
                    let subtitleText: String = {
                        if lancamento.transferencia {
                            return lancamento.conta?.nome ?? ""
                        } else {
                            if lancamento.categoria?.isSub == true {
                                return lancamento.categoria?.nomeSubcategoria ?? ""
                            } else {
                                return lancamento.categoria?.nome ?? ""
                            }
                        }
                    }()

                    Text(subtitleText)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
            
            
            
            if(mostrarValores) {
                Text(
                    lancamento.valorComSinal,
                    format: .currency(
                        code: lancamento.currencyCode
                    )
                )
                .foregroundColor(.secondary)
            } else {
                Text("•••")
                    .foregroundColor(.secondary)
            }
        }
    }
}
