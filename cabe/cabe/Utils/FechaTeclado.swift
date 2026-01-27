//
//  FechaTeclado.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 27/01/26.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil,
                   from: nil,
                   for: nil)
    }
}
