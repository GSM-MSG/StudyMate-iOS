//
//  StudyRecordRepresentation.swift
//  StudyMate
//
//  Created by 최형우 on 6/2/25.
//

import Foundation

struct StudyRecordRepresentation: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let content: String
    let createdAt: Date
    let hasAttachment: Bool
    
    var formattedDate: String {
      return createdAt.formatted(.dateTime.month().day())
    }
} 
