//
//  ContentFetching.swift
//  ShortLearn
//
//  Created by wahid tariq on 15/05/26.
//

import Foundation

protocol ContentFetching: Sendable {
    func nextCard() async throws -> WikiSummary
}
