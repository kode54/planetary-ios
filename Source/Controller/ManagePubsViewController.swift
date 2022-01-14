//
//  ManagePubsViewController.swift
//  Planetary
//
//  Created by Martin Dutra on 3/3/20.
//  Copyright © 2020 Verse Communications Inc. All rights reserved.
//

import Foundation
import UIKit
import Logger
import Monitor
import Bot

class ManagePubsViewController: UITableViewController, KnownPubsTableViewDataSourceDelegate {
    
    lazy var dataSource = KnownPubsTableViewDataSource(pubs: [])
    
    // MARK: Lifecycle
    
    convenience init() {
        self.init(style: .grouped)
        self.title = Text.ManagePubs.title.text
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.load()
    }

    // MARK: Load and refresh

    private func load() {
        self.dataSource.delegate = self
        self.tableView.dataSource = self.dataSource
        self.tableView.prefetchDataSource = self.dataSource
        Bot.shared.pubs { [weak self] (pubs, error) in
            Logger.shared.optional(error)
            Monitor.shared.reportIfNeeded(error: error)
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(error: error)
                } else {
                    self?.dataSource.pubs = pubs
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    func reload() {
        self.tableView.reloadData()
    }
    
    // MARK:- UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetController = self.navigationController
        if indexPath.section == 0 {
            let controller = RedeemInviteViewController()
            controller.saveCompletion = { [weak self] _ in
                self?.load()
                targetController?.popViewController(animated: true)
            }
            targetController?.pushViewController(controller, animated: true)
        } else {
            let controller = AboutViewController(with: self.dataSource.pubs[indexPath.row].address.key)
            targetController?.pushViewController(controller, animated: true)
        }
    }
}
