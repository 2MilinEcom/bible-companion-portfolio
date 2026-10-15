//
//  Message.swift
//  MyApp
//
//  Created by Shopify on 9/16/26.
//

import Foundation

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}
