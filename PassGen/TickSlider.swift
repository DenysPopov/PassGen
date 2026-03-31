//
//  TickSlider.swift
//  PassGen
//
//  Created by Denys Popov on 31.03.2026.
//

import AppKit
import SwiftUI

/// A slider that shows a fixed number of tick marks regardless of step count.
struct TickSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var tickCount: Int = 7

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider(value: value,
                              minValue: range.lowerBound,
                              maxValue: range.upperBound,
                              target: context.coordinator,
                              action: #selector(Coordinator.valueChanged(_:)))
        slider.numberOfTickMarks = tickCount
        slider.allowsTickMarkValuesOnly = false
        return slider
    }

    func updateNSView(_ slider: NSSlider, context: Context) {
        if slider.doubleValue != value {
            slider.doubleValue = value
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    class Coordinator: NSObject {
        var value: Binding<Double>
        init(value: Binding<Double>) { self.value = value }

        @objc func valueChanged(_ sender: NSSlider) {
            value.wrappedValue = sender.doubleValue.rounded()
        }
    }
}
