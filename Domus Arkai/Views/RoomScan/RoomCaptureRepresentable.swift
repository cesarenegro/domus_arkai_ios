//
//  RoomCaptureRepresentable.swift
//  Domus Arkai
//
//  v2.0 Spatial Staging — wrapper SwiftUI di Apple RoomPlan `RoomCaptureView`.
//  Lifecycle: viewDidAppear → captureSession.run · viewWillDisappear → stop.
//  Delegate fornisce il risultato post-processed (`CapturedRoom`) tramite callback.
//
//  Requisiti hardware: iPhone Pro / iPad Pro con sensore LiDAR.
//  Su device senza LiDAR `RoomCaptureSession.isSupported == false` → la chiamante
//  deve verificare prima di presentare questa view.
//

import SwiftUI
import RoomPlan
import ARKit

struct RoomCaptureRepresentable: UIViewControllerRepresentable {
    /// Controller condiviso che permette a SwiftUI di triggerare stop/cancel
    /// sulla session attiva (i bottoni UIKit non sono accessibili senza una
    /// UINavigationController, quindi facciamo overlay SwiftUI esterno).
    let controller: RoomScanController
    let onComplete: (CapturedRoom) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> RoomScanViewController {
        let vc = RoomScanViewController()
        vc.onComplete = onComplete
        vc.onCancel = onCancel
        vc.onError = onError
        // Wire controller per stop/cancel da SwiftUI
        Task { @MainActor in
            controller.hostVC = vc
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: RoomScanViewController, context: Context) {
        // no-op
    }
}

/// Bridge controller per inviare comandi da SwiftUI al RoomScanViewController UIKit.
@Observable
@MainActor
final class RoomScanController {
    weak var hostVC: RoomScanViewController?

    func requestStop() {
        hostVC?.publicStopSession()
    }

    func requestCancel() {
        hostVC?.publicCancelSession()
    }
}

// MARK: - UIKit host controller per RoomCaptureView

final class RoomScanViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {

    var onComplete: ((CapturedRoom) -> Void)?
    var onCancel: (() -> Void)?
    var onError: ((Error) -> Void)?

    private var roomCaptureView: RoomCaptureView!
    private let sessionConfig = RoomCaptureSession.Configuration()
    private var doneButton: UIBarButtonItem?
    private var cancelButton: UIBarButtonItem?
    private var hasFinished: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupRoomCaptureView()
        setupToolbar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Garantisce stop sessione anche se l'utente swipe-down
        if !hasFinished {
            roomCaptureView?.captureSession.stop()
        }
    }

    // MARK: - Setup

    private func setupRoomCaptureView() {
        roomCaptureView = RoomCaptureView(frame: view.bounds)
        roomCaptureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        roomCaptureView.delegate = self
        roomCaptureView.captureSession.delegate = self
        view.insertSubview(roomCaptureView, at: 0)
    }

    private func setupToolbar() {
        let cancel = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        let done = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapDone)
        )
        cancel.tintColor = .white
        done.tintColor = .white
        cancelButton = cancel
        doneButton = done

        navigationItem.leftBarButtonItem = cancel
        navigationItem.rightBarButtonItem = done
    }

    // MARK: - Session control

    private func startSession() {
        print("🟢 [RoomScan][VC] starting capture session")
        roomCaptureView?.captureSession.run(configuration: sessionConfig)
    }

    private func stopSession() {
        print("🟡 [RoomScan][VC] stopping capture session")
        roomCaptureView?.captureSession.stop()
    }

    // MARK: - Actions

    @objc private func didTapDone() {
        // Stop trigger il delegate captureView(shouldPresent:error:) → captureView(didPresent:error:)
        stopSession()
    }

    @objc private func didTapCancel() {
        hasFinished = true
        stopSession()
        onCancel?()
    }

    // MARK: - Public bridge (chiamato da SwiftUI overlay)

    func publicStopSession() {
        guard !hasFinished else { return }
        stopSession()
    }

    func publicCancelSession() {
        guard !hasFinished else { return }
        hasFinished = true
        stopSession()
        onCancel?()
    }

    // MARK: - RoomCaptureViewDelegate

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error {
            print("🔴 [RoomScan][VC] shouldPresent error — \(error.localizedDescription)")
            hasFinished = true
            onError?(error)
            return false
        }
        // Lasciamo che RoomPlan processi i dati e li passi a didPresent
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        if let error {
            print("🔴 [RoomScan][VC] didPresent error — \(error.localizedDescription)")
            hasFinished = true
            onError?(error)
            return
        }
        print("✅ [RoomScan][VC] captured — walls=\(processedResult.walls.count), doors=\(processedResult.doors.count), windows=\(processedResult.windows.count), objects=\(processedResult.objects.count)")
        hasFinished = true
        onComplete?(processedResult)
    }

    // MARK: - RoomCaptureSessionDelegate (instructional callbacks opzionali)

    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        // Le istruzioni di guida utente (move slower, etc.) sono già renderizzate
        // dalla UI di RoomCaptureView. Logghiamo solo per debug.
        print("🟢 [RoomScan][Session] instruction: \(instruction)")
    }
}
