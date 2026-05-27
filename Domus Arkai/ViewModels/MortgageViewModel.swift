//
//  MortgageViewModel.swift
//  Domus Arkai
//

import Foundation

@MainActor
@Observable
final class MortgageViewModel {
    let property: Property

    // Form inputs
    var monthlyIncome: Double? = nil
    var secondIncome: Double? = nil
    var deposit: Double? = nil
    var years: Int = 25
    var existingDebts: Double? = nil
    var isFirstHome: Bool = true
    var interestRate: Double = 0.035

    // Result
    var estimate: MortgageEstimate?

    init(property: Property) {
        self.property = property
        // Suggerisco un deposit ragionevole (20% del prezzo)
        self.deposit = (property.price ?? 0) * 0.2
    }

    var canCalculate: Bool {
        (monthlyIncome ?? 0) > 0 && (deposit ?? 0) >= 0 && years > 0
    }

    func calculate() {
        let result = MortgageEstimate.calculate(
            propertyPrice: property.price ?? 0,
            monthlyIncome: monthlyIncome ?? 0,
            secondIncome: secondIncome ?? 0,
            availableDeposit: deposit ?? 0,
            mortgageYears: years,
            existingMonthlyDebts: existingDebts ?? 0,
            interestRate: interestRate
        )
        estimate = result
    }

    func reset() {
        estimate = nil
    }
}
