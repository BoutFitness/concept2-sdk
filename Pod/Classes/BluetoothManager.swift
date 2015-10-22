//
//  BluetoothManager.swift
//  Pods
//
//  Created by Jesse Curry on 9/29/15.
//
//

import CoreBluetooth

public protocol BluetoothManagerDelegate {
  func didLoadPerformanceMonitors(bluetoothManager:BluetoothManager,
    performanceMonitors:Array<PerformanceMonitor>)
}

public final class BluetoothManager
{
  private var centralManager:CBCentralManager
  private let centralManagerDelegate = CentralManagerDelegate()
  private let centralManagerQueue = dispatch_queue_create(
    "com.boutfitness.concept2.bluetooth.central",
    DISPATCH_QUEUE_CONCURRENT
  )
  
  #if os(iOS)
  @available(iOS 9.0, *)
  var isScanningForPerformanceMonitors:Bool { get { return centralManager.isScanning } }
  #endif
  
  var isReady:Bool { get { return centralManager.state == .PoweredOn } }
  
  public var delegate:BluetoothManagerDelegate
  
  // MARK: Initialization
  public init(withDelegate delegate:BluetoothManagerDelegate) {
    // Initialize 
    centralManager = CBCentralManager(delegate: centralManagerDelegate,
      queue: centralManagerQueue)
    self.delegate = delegate
    
    //
    centralManagerDelegate.bluetoothManager = self
    
    //
    NSNotificationCenter.defaultCenter().addObserverForName(
      PerformanceMonitorStoreDidAddItemNotification,
      object: PerformanceMonitorStore.sharedInstance,
      queue: nil) { (notification) -> Void in
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          delegate.didLoadPerformanceMonitors(self,
            performanceMonitors: Array(PerformanceMonitorStore.sharedInstance.performanceMonitors))
        })
    }
  }
  
  public func scanForPerformanceMonitors() {
    centralManager.scanForPeripheralsWithServices([Service.DeviceDiscovery.UUID],
      options: nil)
  }
  
  public func stopScanningForPerformanceMonitors() {
    centralManager.stopScan()
  }
  
  public func connectPerformanceMonitor(performanceMonitor:PerformanceMonitor) {
    centralManager.connectPeripheral(performanceMonitor.peripheral, options: nil)
  }
  
  public func disconnectPerformanceMonitor(performanceMonitor:PerformanceMonitor) {
    centralManager.cancelPeripheralConnection(performanceMonitor.peripheral)
  }
}