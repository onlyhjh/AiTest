//
//  ViewExtension.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
