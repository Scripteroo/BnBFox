//
//  PropertySelectorView.swift
//  BnBFox
//
//  Created on 12/11/2025.
//

import SwiftUI

struct PropertySelectorView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        Menu {
            ForEach(viewModel.properties) { property in
                Button(action: {
                    viewModel.selectProperty(property)
                }) {
                    HStack {
                        Text(property.displayName)
                        if property.id == viewModel.selectedProperty?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedProperty?.displayName ?? "Select Property")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
    }
}
