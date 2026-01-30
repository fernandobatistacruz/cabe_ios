//
//  AppDateFormatter.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 22/01/26.
//

import Foundation

enum DataCivil {

    static func hojeString() -> String {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month, .day], from: Date())

        return String(
            format: "%04d-%02d-%02d",
            c.year!,
            c.month!,
            c.day!
        )
    }
    
    static func extrairDataCivil(_ valor: String) -> Date? {
        let partes = valor.prefix(10).split(separator: "-")

        guard partes.count == 3,
              let ano = Int(partes[0]),
              let mes = Int(partes[1]),
              let dia = Int(partes[2]) else {
            return nil
        }

        return Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: ano, month: mes, day: dia))
    }
}
