//
//  IntegrationListViewModel.swift
//  S10
//
//  Created by Tony Xiao on 7/24/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import Bond

public struct IntegrationListViewModel {
    let subscription: MeteorSubscription
    public let integrations: DynamicArray<IntegrationViewModel>
    
    public init(meteor: MeteorService) {
        subscription = meteor.subscribe("integrations")
        integrations = Integration
            .sorted(by: IntegrationKeys.status_.rawValue, ascending: true)
            .sorted(by: IntegrationKeys.updatedAt.rawValue, ascending: true)
            .results(Integration)
            .map { IntegrationViewModel(integration: $0) }
    }
}