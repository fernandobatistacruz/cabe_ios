//
//  LancamentoCartaoRow.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 01/02/26.
//

import SwiftUI

struct LancamentoCartaoRow: View {

    let cartao: CartaoModel
    let lancamentos: [LancamentoModel]
    let total: Decimal
   
    private var temPendentes: Bool {
        lancamentos.contains { !$0.pago }
    }

    var body: some View {
        HStack(spacing: 12) {
        
            Circle()
                .fill(temPendentes ? Color.blue.gradient : Color.clear.gradient)
                .frame(width: 10, height: 10)
          
            Image(cartao.operadoraEnum.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        
            VStack(alignment: .leading, spacing: 2) {
                Text(cartao.nome)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text("Fatura")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(
                total,
                format: .currency(code: lancamentos.first?.currencyCode ?? Locale.systemCurrencyCode)
            )
            .foregroundColor(.secondary)
        }
    }
}
