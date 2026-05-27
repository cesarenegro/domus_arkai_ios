//
//  MortgageEstimate.swift
//  Domus Arkai
//

import Foundation

struct MortgageEstimate: Codable, Hashable, Sendable {
    let propertyPrice: Double
    let monthlyIncome: Double
    let secondIncome: Double
    let availableDeposit: Double
    let mortgageYears: Int
    let existingMonthlyDebts: Double
    let interestRate: Double // es. 0.035 = 3.5%
    let estimatedLoanAmount: Double
    let estimatedMonthlyPayment: Double
    let incomeRatio: Double // monthly_payment / total_monthly_income
    let sustainabilityStatus: SustainabilityStatus

    enum SustainabilityStatus: String, Codable, Hashable, Sendable {
        case good       // <= 30%
        case warning    // 31-40%
        case critical   // > 40%

        var label: String {
            switch self {
            case .good: "Buona"
            case .warning: "Da verificare"
            case .critical: "Critica"
            }
        }
    }

    static func calculate(
        propertyPrice: Double,
        monthlyIncome: Double,
        secondIncome: Double,
        availableDeposit: Double,
        mortgageYears: Int,
        existingMonthlyDebts: Double,
        interestRate: Double = 0.035
    ) -> MortgageEstimate {
        let loanAmount = max(propertyPrice - availableDeposit, 0)
        let monthlyRate = interestRate / 12
        let n = Double(mortgageYears * 12)

        let monthlyPayment: Double
        if monthlyRate > 0 && n > 0 && loanAmount > 0 {
            let factor = pow(1 + monthlyRate, n)
            monthlyPayment = loanAmount * monthlyRate * factor / (factor - 1)
        } else {
            monthlyPayment = loanAmount > 0 && n > 0 ? loanAmount / n : 0
        }

        let totalIncome = monthlyIncome + secondIncome
        let netIncome = max(totalIncome - existingMonthlyDebts, 1)
        let ratio = monthlyPayment / netIncome

        let status: SustainabilityStatus
        if ratio <= 0.30 { status = .good }
        else if ratio <= 0.40 { status = .warning }
        else { status = .critical }

        return MortgageEstimate(
            propertyPrice: propertyPrice,
            monthlyIncome: monthlyIncome,
            secondIncome: secondIncome,
            availableDeposit: availableDeposit,
            mortgageYears: mortgageYears,
            existingMonthlyDebts: existingMonthlyDebts,
            interestRate: interestRate,
            estimatedLoanAmount: loanAmount,
            estimatedMonthlyPayment: monthlyPayment,
            incomeRatio: ratio,
            sustainabilityStatus: status
        )
    }
}

extension Double {
    func formattedEuro(maximumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: self)) ?? "€\(Int(self))"
    }
}
