//
//  SearchMode.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 24/02/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func ifAvailableSearchable(searchText: Binding<String>) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            self.searchable(text: searchText, prompt: "Buscar")
        }
    }
}
