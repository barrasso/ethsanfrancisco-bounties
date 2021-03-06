//
//  LoansViewController.swift
//  LoanStar
//
//  Created by mbarrass on 10/5/18.
//  Copyright © 2018 ethsociety. All rights reserved.
//

import UIKit
//import PopupDialog

class LoansViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchFooter: SearchFooter!
    
    var detailViewController: DetailViewController? = nil
    var loans = [Loan]()
    var filteredLoans = [Loan]()
    let loanManager = LoanManager()
    
    let searchController = UISearchController(searchResultsController: nil)
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(activityIndicator)
        activityIndicator.frame = view.bounds
        activityIndicator.startAnimating()

        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for loans"
        searchController.searchBar.tintColor = UIColor.blueStar
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Setup the Scope Bar
        searchController.searchBar.scopeButtonTitles = ["All", "Signed", "Filled", "Cancelled"]
        searchController.searchBar.delegate = self
        
        // Setup the search footer
        tableView.tableFooterView = searchFooter
        
        // Search for loans
        loanManager.getLoanResults { (results, error) in
            if let results = results {
                self.loans = results
                self.tableView.reloadData()
                self.tableView.setContentOffset(CGPoint.zero, animated: false)
            }
            if !error.isEmpty { print("Search error: " + error) }
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    // MARK: - Table View
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            searchFooter.setIsFilteringToShow(filteredItemCount: filteredLoans.count, of: loans.count)
            return filteredLoans.count
        }
        searchFooter.setNotFiltering()
        return loans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LoanCell", for: indexPath) as! LoanCell
        let loan: Loan
        if isFiltering() {
            loan = filteredLoans[indexPath.row]
        } else {
            loan = loans[indexPath.row]
        }
        cell.loan = loan
        return cell
    }

    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let loan: Loan
                if isFiltering() {
                    loan = filteredLoans[indexPath.row]
                } else {
                    loan = loans[indexPath.row]
                }
                let controller = segue.destination as! DetailViewController
                controller.detailLoan = loan
            }
        }
    }
    
//    func showFilterPopup(animated: Bool = true) {
//        if let filterVC = storyboard?.instantiateViewController(withIdentifier: "RootFilterViewController") {
//
//            // Create the dialog
//            let popup = PopupDialog(viewController: filterVC,
//                                    buttonAlignment: .horizontal,
//                                    transitionStyle: .bounceDown,
//                                    tapGestureDismissal: false,
//                                    panGestureDismissal: false)
//
////            // Create first button
////            let buttonOne = CancelButton(title: "CANCEL", height: 60) {
////                print("You canceled the dialog")
////                self.dismiss(animated: animated, completion: nil)
////            }
////
////            // Create second button
////            let buttonTwo = DefaultButton(title: "RATE", height: 60) {
////                print("You hit the second button")
////            }
////
////            popup.addButtons([buttonOne, buttonTwo])
//            present(popup, animated: animated, completion: nil)
//        }
//    }
    
    // MARK: - Private instance methods
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredLoans = loans.filter({( loan : Loan) -> Bool in
            let doesCategoryMatch = (scope == "All") || (loan.category.contains(scope))
            
            if searchBarIsEmpty() {
                return doesCategoryMatch
            } else {
                return doesCategoryMatch && loan.id.lowercased().contains(searchText.lowercased())
            }
        })
        tableView.reloadData()
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeIsFiltering)
    }
}

extension LoansViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension LoansViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
}
