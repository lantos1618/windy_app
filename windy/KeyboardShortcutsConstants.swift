//
//  Constants.swift
//  windy
//
//  Created by Lyndon Leong on 08/03/2023.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let moveWindowLeft           = Self("moveWindowLeft",    default: .init(.leftArrow,  modifiers: [.control, .option]))
    static let moveWindowRight          = Self("moveWindowRight",   default: .init(.rightArrow, modifiers: [.control, .option]))
    static let moveWindowUp             = Self("moveWindowUp",      default: .init(.upArrow,    modifiers: [.control, .option]))
    static let moveWindowDown           = Self("moveWindowDown",    default: .init(.downArrow,  modifiers: [.control, .option]))
    //    move the window to next screens
    static let moveWindowScreenLeft     = Self("moveWindowScreenLeft",      default: .init(.leftArrow,  modifiers: [.shift, .control, .option]))
    static let moveWindowScreenRight    = Self("moveWindowScreenRight",     default: .init(.rightArrow,  modifiers: [.shift, .control, .option]))
    static let moveWindowScreenUp       = Self("moveWindowScreenUp",        default: .init(.upArrow,  modifiers: [.shift, .control, .option]))
    static let moveWindowScreenDown     = Self("moveWindowScreenDown",      default: .init(.downArrow,  modifiers: [.shift, .control, .option]))
}
