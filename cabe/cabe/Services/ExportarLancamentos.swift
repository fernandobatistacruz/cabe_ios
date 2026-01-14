//
//  LancamentoCSVExporter.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 13/01/26.
//

import Foundation
import SwiftUI

struct ExportarLancamentos {

    static func export(
        lancamentos: [LancamentoModel],
        fileName: String = "lancamentos"
    ) throws -> URL {

        let csv = makeCSV(from: lancamentos)

        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("\(fileName).csv")

        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - CSV Builder

    private static func makeCSV(from lancamentos: [LancamentoModel]) -> String {
        var rows: [String] = []
        rows.append(header)

        for l in lancamentos {
            rows.append(row(from: l))
        }

        return rows.joined(separator: "\n")
    }

    // MARK: - Header

    private static let header =
    """
    Data Vencimento;\
    Data Compra;\
    Descrição;\
    Anotação;\
    Tipo;\
    Categoria;\
    Conta;\
    Cartão;\
    Valor;\
    Pago;\
    Recorrência;\
    Parcelas;\
    Transferência;\
    Criado em
    """
    .replacingOccurrences(of: "\n", with: "")

    // MARK: - Row

    private static func row(from l: LancamentoModel) -> String {

        let tipo = Tipo(rawValue: l.tipo)?.descricao.stringValue ?? ""
        let recorrencia = l.tipoRecorrente.titulo.stringValue

        return [
            l.dataVencimentoFormatada,
            l.dataCompraFormatada,
            sanitize(l.descricao),
            sanitize(l.anotacao),
            tipo,
            sanitize(l.categoria?.nome ?? ""),
            sanitize(l.conta?.nome ?? ""),
            sanitize(l.cartao?.nome ?? ""),
            formatDecimal(l.valorComSinal),
            l.pago ? "Sim" : "Não",
            recorrencia,
            "\(l.parcelas)",
            l.transferencia ? "Sim" : "Não",
            formatDate(l.dataCriacaoDate)
        ].joined(separator: ";")
    }

    // MARK: - Helpers

    private static func sanitize(_ value: String) -> String {
        value
            .replacingOccurrences(of: ";", with: ",")
            .replacingOccurrences(of: "\n", with: " ")
    }

    private static func formatDecimal(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.decimalSeparator = ","
        f.groupingSeparator = "."
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: value as NSNumber) ?? "0,00"
    }

    private static func formatDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }
}

extension LocalizedStringKey {
    var stringValue: String {
        Mirror(reflecting: self)
            .children
            .first { $0.label == "key" }?
            .value as? String ?? ""
    }
}
