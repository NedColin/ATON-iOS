//
//  DelegateDetailViewController.swift
//  platonWallet
//
//  Created by Admin on 24/7/2019.
//  Copyright © 2019 ju. All rights reserved.
//

import UIKit
import Localize_Swift
import MJRefresh

enum RefreshDirection: String {
    case new = "new"
    case old = "old"
}

class DelegateDetailViewController: BaseViewController {
    
    lazy var tableView = { () -> UITableView in
        let tbView = UITableView(frame: .zero)
        tbView.delegate = self
        tbView.dataSource = self
        tbView.register(NodeAboutDelegateTableViewCell.self, forCellReuseIdentifier: "NodeAboutDelegateTableViewCell")
        tbView.separatorStyle = .none
        tbView.backgroundColor = normal_background_color
        tbView.tableFooterView = UIView()
        return tbView
    }()
    
    lazy var walletHeaderView = { () -> WalletBaseInfoView in
        let headerView = WalletBaseInfoView()
        return headerView
    }()
    
    lazy var refreshHeader: MJRefreshHeader = {
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(fetchDataLastest))!
        return header
    }()
    
    lazy var refreshFooter: MJRefreshFooter = {
        let footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(fetchDataMore))!
        return footer
    }()
    
    var delegate: Delegate?
    var delegateDetail: DelegateDetail?
    var listData: [DelegateDetail] = [] {
        didSet {
            tableView.mj_footer.isHidden = listData.count == 0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        super.leftNavigationTitle = "delegate_detail_title"
        
        view.backgroundColor = normal_background_color
        
        view.addSubview(walletHeaderView)
        walletHeaderView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(68)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(walletHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        let doubtButtonItem = UIBarButtonItem(image: UIImage(named: "3.icon_doubt"), style: .done, target: self, action: #selector(doubtTapAction))
        doubtButtonItem.tintColor = .black
        navigationItem.rightBarButtonItem = doubtButtonItem
        
        tableView.mj_header = refreshHeader
        tableView.mj_footer = refreshFooter
        
        setupWalletData()
        tableView.mj_header.beginRefreshing()
    }

}

extension DelegateDetailViewController {
    private func gotoDelgateController(_ dDetail: DelegateDetail) {
        let controller = DelegateViewController()
        controller.currentNode = dDetail.delegateToNode()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func gotoWithdrawController(_ dDetail: DelegateDetail) {
        let controller = WithDrawViewController()
        controller.currentNode = dDetail.delegateToNode()
        controller.stakingBlockNum = dDetail.stakingBlockNum
        controller.currentAddress = (AssetVCSharedData.sharedData.selectedWallet as! Wallet).key?.address
        navigationController?.pushViewController(controller, animated: true)
    };
    
    @objc private func openWebSiteController(_ linkUrl: String?) {
        guard let url = linkUrl else { return }
        let controller = WebCommonViewController()
        controller.requestUrl = url
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func setupWalletData() {
        walletHeaderView.avatarIV.image = delegate?.walletAvatar ?? UIImage(named: "walletAvatar_1")
        walletHeaderView.nameLabel.text = delegate?.walletName ?? "--"
        walletHeaderView.addressLabel.text = delegate?.walletAddress ?? "--"
    }
    
    private func fetchData(sequence: String, direction: RefreshDirection) {
        guard let del = delegate else {
            tableView.mj_header.endRefreshing()
            tableView.mj_footer.endRefreshing()
            return
        }
        
        StakingService.sharedInstance.getDelegateDetail(address: del.walletAddress, beginSequence: sequence, direction: direction.rawValue, listSize: 20) { [weak self] (result, data) in
            self?.tableView.mj_header.endRefreshing()
            
            switch result {
            case .success:
                if direction == .new {
                    self?.listData.removeAll()
                }
                
                if let newData = data as? [DelegateDetail], newData.count > 0 {
                    let filterData = newData.filter { return !DelegatePersistence.isDeleted(self?.delegate?.walletAddress ?? "", $0) }
                    
                    self?.listData.append(contentsOf: filterData)
                    self?.tableView.mj_footer.resetNoMoreData()
                } else {
                    self?.tableView.mj_footer.endRefreshingWithNoMoreData()
                }
                
                self?.tableView.reloadData()
            case .fail(_, _):
                break
            }
        }
    }
    
    
    @objc func fetchDataLastest() {
        fetchData(sequence: "0", direction: .new)
    }
    
    @objc func fetchDataMore() {
        tableView.mj_footer.endRefreshing()
//        guard let sequence = listData.last?.sequence else { return }
//        fetchData(sequence: sequence, direction: .old)
    }
}

extension DelegateDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NodeAboutDelegateTableViewCell") as! NodeAboutDelegateTableViewCell
        let delegateDetail = self.listData[indexPath.row]
        cell.delegateDetail = delegateDetail
        cell.delegateButton.isEnabled = delegateDetail.getLeftButtonIsEnable(address: delegate!.walletAddress)
        cell.delegateButton.backgroundColor = delegateDetail.getLeftButtonIsEnable(address: delegate!.walletAddress) ? UIColor.white : UIColor(rgb: 0xDCDFE8, alpha: 0.4)
        cell.withDrawButton.isHidden = !delegateDetail.rightButtonStatus.0
        cell.moveOutButton.isHidden = delegateDetail.rightButtonStatus.0
        cell.withDrawButton.isEnabled = delegateDetail.rightButtonStatus.1
        cell.moveOutButton.isEnabled = delegateDetail.rightButtonStatus.1
        cell.withDrawButton.backgroundColor = delegateDetail.rightButtonStatus.1 ? UIColor.white : UIColor(rgb: 0xDCDFE8, alpha: 0.4)
        cell.moveOutButton.backgroundColor = delegateDetail.rightButtonStatus.1 ? UIColor.white : UIColor(rgb: 0xDCDFE8, alpha: 0.4)
        
        cell.didLinkHanlder = { [weak self] _ in
            self?.openWebSiteController(delegateDetail.url)
        }
        cell.didDelegateHandler = { [weak self] _ in
            self?.gotoDelgateController(delegateDetail)
        }
        cell.didWithdrawHandler = { [weak self] _ in
            self?.gotoWithdrawController(delegateDetail)
        }
        cell.didMoveOutHandler = { [weak self] _ in
            self?.removeDelegateDetailCell(indexPath)
            
        }
        return cell
    }
    
    func removeDelegateDetailCell(_ indexPath: IndexPath) {
        let delegateDetail = listData[indexPath.row]
        let detailDel = DelegateDetailDel(walletAddress: delegate?.walletAddress ?? "", nodeId: delegateDetail.nodeId, stakingBlockNum: delegateDetail.stakingBlockNum)
        DelegatePersistence.add(delegates: [detailDel])
        listData.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
}

extension DelegateDetailViewController {
    @objc private func doubtTapAction() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10
        
        let lockedTitleAttr = NSAttributedString(string: Localized("staking_alert_locked_delegate") + "\n", attributes: [NSAttributedString.Key.foregroundColor: text_blue_color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let lockedDetailAttr = NSAttributedString(string: Localized("staking_alert_locked_delegate_detail") + "\n", attributes: [NSAttributedString.Key.foregroundColor: common_darkGray_color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        let unlockedTitleAttr = NSAttributedString(string: Localized("staking_alert_unlocked_delegate") + "\n", attributes: [NSAttributedString.Key.foregroundColor: text_blue_color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let unlockedDetailAttr = NSAttributedString(string: Localized("staking_alert_unlocked_delegate_detail") + "\n", attributes: [NSAttributedString.Key.foregroundColor: common_darkGray_color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        let releaseTitleAttr = NSAttributedString(string: Localized("staking_alert_released_delegate") + "\n", attributes: [NSAttributedString.Key.foregroundColor: text_blue_color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let releaseDetailAttr = NSAttributedString(string: Localized("staking_alert_released_detail") + "\n", attributes: [NSAttributedString.Key.foregroundColor: common_darkGray_color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        
        let alertVC = AlertStylePopViewController.initFromNib()
        let style = PAlertStyle.AlertWithText(attributedStrings: [lockedTitleAttr, lockedDetailAttr, unlockedTitleAttr, unlockedDetailAttr, releaseTitleAttr, releaseDetailAttr])
        alertVC.onAction(confirm: { (text, _) -> (Bool) in
            return true
        }) { (_, _) -> (Bool) in
            return true
        }
        alertVC.style = style
        alertVC.showInViewController(viewController: self)
    }
}