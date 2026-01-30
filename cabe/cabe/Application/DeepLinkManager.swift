//
//  DeepLinkManager.swift
//  cabe
//
//  Created by Fernando Batista da Cruz on 09/01/26.
//

import SwiftUI
import Combine

import SwiftUI

enum DeepLink: Hashable {
    case notificacoes    
}



@MainActor
final class DeepLinkManager: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedTab: TabItem = .inicio

    func open(_ link: DeepLink) {
        switch link {
        case .notificacoes:
            selectedTab = .inicio
            path = NavigationPath()
            path.append(DeepLink.notificacoes)
        }
    }
}
