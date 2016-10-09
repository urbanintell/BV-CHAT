//
//  CurrentUser.swift
//  BVChat
//
//  Created by Lusenii Kromah on 10/7/16.
//  Copyright © 2016 Black Valley. All rights reserved.
//

import Foundation
class User:NSObject{
    var firstname:String!
    var lastname:String!
    var company:String!
    var email:String!
    var role:String!
    
    init(firstname:String, lastname:String, company:String, email:String, role:String){
        self.firstname = firstname
        self.lastname = lastname
        self.company = company
        self.email = email
        self.role = role
    }
}
