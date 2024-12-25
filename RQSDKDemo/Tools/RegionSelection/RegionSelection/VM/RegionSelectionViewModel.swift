//
//  RegionSelectionViewModel.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 25/7/2023.
//

import Foundation

class RegionSelectionViewModel {
    
    @RxBehavioral var dataSource: [RegionInfo] = []

    // 设计此Subject 与 ViewController.textField.rx.text 绑定. 当 ViewController 中的搜索框输入时, 监听输入内容.
    @RxBehavioral var searchKeyword: String?

    private let disposeBag: DisposeBag = .init()

    init() {
        let allRegionsObservable = RxSwift.BehaviorSubject.init(value: RegionInfoProvider.allRegionInfos)
        RxSwift.Observable.combineLatest(allRegionsObservable, self.$searchKeyword).map { regions, searchKeyword -> [RegionInfo] in
            if let searchKeyword = searchKeyword, !searchKeyword.isEmpty {
                return regions.filter({ $0.countryName.contains(searchKeyword) })
            }else{
                return regions
            }
        }.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] regions in
            self?.dataSource = regions
        }).disposed(by: self.disposeBag)
    }
    
}
