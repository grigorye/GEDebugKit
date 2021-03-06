//
//  GenerationViewController.swift
//  GEDebugKit
//
//  Created by Grigorii Entin on 08/12/2017.
//  Copyright © 2017 Grigory Entin. All rights reserved.
//

import UIKit

extension String {
	
	var symbolDisplayName: String {
        #if CWLDEMANGLE_ENABLED
		return (try? parseMangledSwiftSymbol(self))?.print(using: SymbolPrintOptions.simplified.union([.displayModuleNames])) ?? self
        #else
        return self
        #endif
	}
}

class GenerationViewController : UITableViewController {

	class Data {
		
		var allocationGeneration: AllocationGeneration
		
		lazy var aliveObjects: [String : [WeakReference<AnyObject>]] = allocationGeneration.aliveObjects
		
		lazy var aliveObjectsClassNames: [String] = aliveObjects.keys.sorted()
		
		init(generationIndex: Int) {
			
			self.allocationGeneration = AllocationGeneration(generationIndex: generationIndex)
		}
	}
	
	var generationIndex: Int = 0
	
	var dataImp: Data? = nil
	var data: Data {
		return dataImp ?? {
			let data = Data(generationIndex: generationIndex)
			dataImp = data
			return data
		}()
	}
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
        return data.aliveObjects.count
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
        let cell = tableView.dequeueReusableCell(withIdentifier: "aliveObject", for: indexPath) … {
			
            let className = data.aliveObjectsClassNames[indexPath.row]
            let objects = data.aliveObjects[className]!
            let classDisplayName = className.symbolDisplayName
            $0.textLabel!.text = "\(classDisplayName)"
            $0.detailTextLabel!.text = "\(objects.count)"
        }
        return cell
    }
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		setTitleFromData()
	}
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showObjects"?:
            let indexPath = tableView.indexPathForSelectedRow!
			let className = data.aliveObjectsClassNames[indexPath.row]
            let classDisplayName = className.symbolDisplayName
			
            let objects = data.aliveObjects[className]!
			
            segue.destination as! ObjectsViewController … {
                $0.data = ObjectsViewController.Data(classDisplayName: classDisplayName, objects: objects)
            }
        default: ()
        }
    }
	
	func setTitleFromData() {
		
        let generationNumber = generationIndex + 1
		title = String.localizedStringWithFormat(
			NSLocalizedString("Generation %d of %d (%d objects)", comment: ""),
			generationNumber,
            data.allocationGeneration.currentSummaryForGenerations.count,
			data.allocationGeneration.aliveObjectsCount
		)
		
        let backTitle = String.localizedStringWithFormat(
            NSLocalizedString("Generation %d", comment: ""),
            generationNumber
        )

        navigationItem.backBarButtonItem = UIBarButtonItem(title: backTitle, style: .plain, target: nil, action: nil) … {
			
            $0.possibleTitles = [
                String.localizedStringWithFormat(
                    NSLocalizedString("Gen. %d", comment: ""),
                    generationNumber
                )
            ]
        }
	}
	
	func updateForGenerationIndex() {
		
		dataImp = nil
		setTitleFromData()
		tableView.reloadData()
	}
	
	@IBAction func generationForward(_ sender: Any) {
		
		guard generationIndex < lastAllocationGenerationIndex() else {
			return
		}
		
		generationIndex += 1
		updateForGenerationIndex()
	}
	
	@IBAction func generationBackward(_ sender: Any) {
		
		guard 0 < generationIndex else {
			return
		}
		
		generationIndex -= 1
		updateForGenerationIndex()
	}
}
