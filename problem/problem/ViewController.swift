//
//  ViewController.swift
//  problem
//
//  Created by Yan Cheng Cheok on 24/06/2021.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    //
    // Core data container.
    //
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // This is a serious fatal error. We will just simply terminate the app, rather than using error_log.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // So that when backgroundContext write to persistent store, container.viewContext will retrieve update from
        // persistent store.
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    //
    // Core data background context. For write purpose.
    //
    private lazy var backgroundContext: NSManagedObjectContext = {
        let backgroundContext = persistentContainer.newBackgroundContext()

        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return backgroundContext
    }()
    
    //
    // FRC.
    //
    private lazy var fetchedResultsController: NSFetchedResultsController<NSTabInfo> = {
        
        let fetchRequest = NSFetchRequest<NSTabInfo>(entityName: "NSTabInfo")
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "order", ascending: true)
        ]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        controller.delegate = self
        
        return controller
    }()
    
    typealias DataSource = UICollectionViewDiffableDataSource<Int, NSManagedObjectID>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    
    private var dataSource: DataSource?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDataSource()
        
        collectionView.collectionViewLayout = layoutConfig()
        
        insertDataIfEmpty()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("\(error)")
        }
    }

    private func insertDataIfEmpty() {
        let backgroundContext = self.backgroundContext
        
        backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSTabInfo>(entityName: "NSTabInfo")
            
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "order", ascending: true)
            ]
            
            do {
                let nsTabInfos = try fetchRequest.execute()
                
                if nsTabInfos.isEmpty {
                    for index in 0...3 {
                        let nsTabInfo = NSTabInfo(
                            context: backgroundContext
                        )
                        
                        nsTabInfo.name = "\(index)"
                        nsTabInfo.order = Int64(index)
                    }
                    
                    if backgroundContext.hasChanges {
                        print("Write to core data for the first time")
                        try backgroundContext.save()
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    private func layoutConfig() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        
        return UICollectionViewCompositionalLayout (sectionProvider: { (sectionNumber, env) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(CGFloat(44)),
                heightDimension: .fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .estimated(CGFloat(44)),
                heightDimension: .absolute(CGFloat(44))
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 1
            return section
        }, configuration: configuration)
    }
    
    @IBAction func updateClicked(_ sender: Any) {
        let backgroundContext = self.backgroundContext
        
        backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSTabInfo>(entityName: "NSTabInfo")
            
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "order", ascending: true)
            ]
            
            do {
                let nsTabInfos = try fetchRequest.execute()
                
                if !nsTabInfos.isEmpty {
                    // Perform update on the first cell
                    
                    nsTabInfos[0].name = "\(Int(nsTabInfos[0].name!)! + 1)"
                    
                    if backgroundContext.hasChanges {
                        try backgroundContext.save()
                    }
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    @IBAction func moveClicked(_ sender: Any) {
        let backgroundContext = self.backgroundContext
        
        backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSTabInfo>(entityName: "NSTabInfo")
            
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "order", ascending: true)
            ]
            
            do {
                let nsTabInfos = try fetchRequest.execute()
                
                for (index, element) in nsTabInfos.reversed().enumerated() {
                    element.order = Int64(index)
                }
                
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                }
            } catch {
                print("\(error)")
            }
        }
    }
    
    private func initDataSource() {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { [weak self] (collectionView, indexPath, objectID) -> UICollectionViewCell? in
                
                guard let self = self else { return nil }
                
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "cell",
                    for: indexPath) as? CollectionViewCell else {
                    return nil
                }

                guard let nsTabInfo = self.getNSTabInfo(indexPath) else { return nil }
                cell.label.text = nsTabInfo.name
                
                print("Memory for cell \(Unmanaged.passUnretained(cell).toOpaque())")
                print("Content for cell \(cell.label.text)\n")
                
                return cell
            }
        )
        
        self.dataSource = dataSource
    }
    
    func getNSTabInfo(_ indexPath: IndexPath) -> NSTabInfo? {
        guard let sections = self.fetchedResultsController.sections else { return nil }
        return sections[indexPath.section].objects?[indexPath.item] as? NSTabInfo
    }
    
    func mergeChanges(_ changes: [AnyHashable : Any]) {
        NSManagedObjectContext.mergeChanges(
            fromRemoteContextSave: changes,
            into: [persistentContainer.viewContext, backgroundContext]
        )
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controller(_ fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshotReference: NSDiffableDataSourceSnapshotReference) {
            
        guard let dataSource = self.dataSource else {
            return
        }
        
        let snapshot = snapshotReference as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        print("dataSource.apply")
        
        dataSource.apply(snapshot, animatingDifferences: true) {
        }
    }
}

