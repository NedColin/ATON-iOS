//
//  IPGeoPersistence.swift
//  platonWallet
//
//  Created by juzix on 2019/1/24.
//  Copyright © 2019 ju. All rights reserved.
//

import Foundation

let ipGeoInfoVaildDuring = 3600 * 24

class IPGeoPersistence {
    
    class func filter(isIncludedIp ip:[String]) -> [IPGeoInfo] {
        
        var predicate : NSPredicate?
        predicate = NSPredicate(format: "ipAddr IN %@ AND updateTime > %d", ip, Int(Date().timeIntervalSince1970) - ipGeoInfoVaildDuring)
        let r = RealmInstance!.objects(IPGeoInfo.self).filter(predicate!)
        return Array(r)
        
    }
    
    class func add(infos: [IPGeoInfo], update: Bool = true) {
        
        for info in infos {
            try? RealmInstance!.write {
                RealmInstance!.add(info, update: update)
            }
        }
    }
    
    class func getIpInfo(_ ip: String) -> IPGeoInfo {
        return RealmInstance!.object(ofType: IPGeoInfo.self, forPrimaryKey: ip) ?? IPGeoInfo()
    }
    
}
