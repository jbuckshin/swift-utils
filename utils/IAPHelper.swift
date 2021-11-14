import StoreKit
import Zipper


public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
  static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}
 
class IAPHelper: NSObject  {
  
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    private var fileManager : FileManager
    private var currentDirectoryURL : URL
    private var knownProducts = ["com.xxx.iap-example-1",
                                 "com.xxx.iap-example-2"] as Set<ProductIdentifier>
    // string mapping hash
    public var iapProducts : [String : SKProduct] = [:]
    let app = UIApplication.shared.delegate as! AppDelegate
    
    public override init() {
        
        productIdentifiers = knownProducts
        for productIdentifier in knownProducts {
          let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
          if purchased {
            purchasedProductIdentifiers.insert(productIdentifier)
            print("Previously purchased: \(productIdentifier)")
          } else {
            print("Not purchased: \(productIdentifier)")
          }
        }
      
        fileManager = FileManager()
        currentDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        super.init()

        checkIAP()
        
        SKPaymentQueue.default().add(self)
    }
    
    
    func checkIAP() {
        
        requestProducts { success, products in
            print("requestProducts \(success)")
            
            if let haveProducts = products {
                
                for product in haveProducts {
                    print("found product \(product.localizedTitle)")
                    self.iapProducts[product.productIdentifier] = product
                }
            }
        }
    }
}

// MARK: - StoreKit API

extension IAPHelper {
  
  public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
    productsRequest?.cancel()
    productsRequestCompletionHandler = completionHandler

    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

    
    public func buyProduct(_ productName: String) {
      print("Buying \(productName)...")
      let payment = SKPayment(product: iapProducts[productName]!)
      SKPaymentQueue.default().add(payment)
    }

        
  public func buyProduct(_ product: SKProduct) {
    print("Buying \(product.productIdentifier)...")
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
    return purchasedProductIdentifiers.contains(productIdentifier)
  }
  
  public class func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  public func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    print("Loaded list of products...")
    let products = response.products
    productsRequestCompletionHandler?(true, products)
    clearRequestAndHandler()

    for p in products {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }
  }

  public func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequestCompletionHandler?(false, nil)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {

  public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch (transaction.transactionState) {
      case .purchased:
        complete(transaction: transaction)
        break
      case .failed:
        fail(transaction: transaction)
        break
      case .restored:
        restore(transaction: transaction)
        break
      case .deferred:
        break
      case .purchasing:
        break
      }
    }
  }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {

        for download in downloads
        {
            switch download.downloadState {
                case SKDownloadState.active:
                    print("Download progress \(download.progress)")
                    print("Download time = \(download.timeRemaining)")
                    break
                case SKDownloadState.finished:
                    // Download is complete. Content file URL is at
                    // path referenced by download.contentURL. Move
                    // it somewhere safe, unpack it and give the user
                    // access to it
                    print("download finished")
                
                    procesessDownload(download: download)

                    break
                
                default:
                     break
            }
        }
    }

    func procesessDownload(download: SKDownload) {
        guard let hostedContentPath = download.contentURL?.appendingPathComponent("Contents") else {
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: hostedContentPath.relativePath)
            for file in files {
                print("file: \(file)")
                let source = hostedContentPath.appendingPathComponent(file)
                //copy to Application Support Path and mark as exclude from iCloud backup
                
                loadIAPStockIndividual(url: source)
            }

            //Delete cached file
            do {
                try FileManager.default.removeItem(at: download.contentURL!)
            } catch {
                //catch error
            }
        } catch {
            //catch error
        }
    }
    
    func loadIAPStockIndividual(url : URL) {
        
        print("in loadIAPStockIndividual()")

        do {
            
            let imageData = try Data(contentsOf: url)
            let stockImage = UIImage(data: imageData)

            app.sharedPhotoManager?.save(stockImage!, completion: { result, error in
                print("save completion result: \(result.description)")
            })

        } catch let error as NSError {
            print(error.description)
        }
    }
    
  private func complete(transaction: SKPaymentTransaction) {
    print("complete...")
    deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
      
      if transaction.downloads.count > 0 {
          SKPaymentQueue.default().start(transaction.downloads)
      } else {
          // Unlock feature or content here before
          // finishing transaction
          SKPaymentQueue.default().finishTransaction(transaction)
      }
  }

  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

    print("restore... \(productIdentifier)")
    deliverPurchaseNotificationFor(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func fail(transaction: SKPaymentTransaction) {
    print("fail...")
    if let transactionError = transaction.error as NSError?,
      let localizedDescription = transaction.error?.localizedDescription,
        transactionError.code != SKError.paymentCancelled.rawValue {
        print("Transaction Error: \(localizedDescription)")
      }

    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func deliverPurchaseNotificationFor(identifier: String?) {
    guard let identifier = identifier else { return }

    purchasedProductIdentifiers.insert(identifier)
    UserDefaults.standard.set(true, forKey: identifier)
    NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
  }

    // routine to do locale formatting of the price
    public static func getPriceFormatted(for product: SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
    
}
