//
//  MainController.swift
//  
//
//  Created by Marius on 2020-07-07.
//

import Vapor

struct MainController {
    private var app: Application

    init(app: Application) {
        self.app = app
    }

    func start() {
        print("STARTING!")
    }
}
