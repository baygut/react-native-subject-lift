import UIKit
import VisionKit
import React

@available(iOS 16.0, *)
@objc(SubjectLiftView)
class SubjectLiftView: UIView {

  // MARK: - RN Props

  @objc var imageUri: String = "" {
    didSet { loadImage() }
  }

  @objc var preferredInteractionTypes: String = "automatic" {
    didSet { updateInteractionTypes() }
  }

  @objc var onAnalysisComplete: RCTBubblingEventBlock?
  @objc var onSubjectLifted: RCTBubblingEventBlock?

  // MARK: - Private

  private let imageView = UIImageView()
  private var interaction: ImageAnalysisInteraction?
  private let analyzer = ImageAnalyzer()
  private var analysisTask: Task<Void, Never>?

  private var hadActiveTextSelection = false
  private var lastSelectedTextPreview = ""
  private var textSelectionBeganEmitted = false

  /// Poll after `.imageSubject` began — `highlightedSubjects` is often empty during lift; also watch `activeInteractionTypes`.
  private var highlightedSubjectsMonitorTimer: Timer?
  private weak var highlightedSubjectsMonitorInteraction: ImageAnalysisInteraction?
  private var lastNonEmptyHighlightedSubjects: Set<ImageAnalysisInteraction.Subject>?
  private var highlightedSubjectsMonitorDeadline: Date?
  private var lastSubjectLiftPoint: CGPoint = .zero
  private var subjectResolvedAtLiftPoint: ImageAnalysisInteraction.Subject?
  private var previousHighlightedSubjectCount: Int = 0
  private var sawImageSubjectActiveDuringLift: Bool = false
  private var hadActiveImageSubjectPulse: Bool = false
  private var subjectLiftSessionStart: Date?
  private var idleTicksWhileNoHighlightAndNoActiveSubject: Int = 0
  private var didEmitLiftFinishForSession: Bool = false
  private var liftFinishAsyncFetchInFlight: Bool = false

  /// Fallback if lift-end heuristics never fire (short value helps debug; production apps often use 30–60s).
  private let subjectLiftMonitorTimeout: TimeInterval = 45

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupImageView()
    setupInteraction()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

  deinit {
    stopHighlightedSubjectsMonitoring()
  }

  // MARK: - Setup

  private func setupImageView() {
    imageView.contentMode = .scaleAspectFit
    imageView.isUserInteractionEnabled = true
    imageView.clipsToBounds = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(imageView)

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  private func setupInteraction() {
    let interaction = ImageAnalysisInteraction()
    interaction.delegate = self
    imageView.addInteraction(interaction)
    self.interaction = interaction
  }

  // MARK: - Image Loading

  private func loadImage() {
    guard !imageUri.isEmpty else { return }

    analysisTask?.cancel()

    let uri = imageUri
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }

      let image: UIImage?
      if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
        guard let url = URL(string: uri), let data = try? Data(contentsOf: url) else {
          self.emitAnalysisError("Failed to load remote image")
          return
        }
        image = UIImage(data: data)
      } else {
        let path = uri.replacingOccurrences(of: "file://", with: "")
        image = UIImage(contentsOfFile: path)
      }

      guard let image else {
        self.emitAnalysisError("Invalid image at path: \(uri)")
        return
      }

      DispatchQueue.main.async {
        self.resetInteractionTracking()
        self.imageView.image = image
        self.runAnalysis(on: image)
      }
    }
  }

  // MARK: - Analysis

  private func runAnalysis(on image: UIImage) {
    analysisTask = Task { [weak self] in
      guard let self else { return }
      do {
        // `.machineReadableCode` enables QR / barcodes in Live Text (not subject-lift — use taps / data detectors).
        let config = ImageAnalyzer.Configuration([.text, .visualLookUp, .machineReadableCode])
        let analysis = try await self.analyzer.analyze(image, configuration: config)

        await MainActor.run {
          self.interaction?.analysis = analysis
          self.updateInteractionTypes()
          self.onAnalysisComplete?(["status": "ready"])
        }
      } catch {
        await MainActor.run {
          self.emitAnalysisError(error.localizedDescription)
        }
      }
    }
  }

  private func updateInteractionTypes() {
    guard let interaction else { return }
    switch preferredInteractionTypes {
    case "subjectLiftOnly":
      if #available(iOS 17.0, *) {
        interaction.preferredInteractionTypes = .imageSubject
      } else {
        interaction.preferredInteractionTypes = .automatic
      }
    case "automatic":
      fallthrough
    default:
      if #available(iOS 17.0, *) {
        interaction.preferredInteractionTypes = [.automatic, .imageSubject]
      } else {
        interaction.preferredInteractionTypes = .automatic
      }
    }
  }

  private func emitAnalysisError(_ message: String) {
    onAnalysisComplete?(["status": "error", "message": message])
  }

  private func resetInteractionTracking() {
    hadActiveTextSelection = false
    lastSelectedTextPreview = ""
    textSelectionBeganEmitted = false
    stopHighlightedSubjectsMonitoring()
  }

  private func startHighlightedSubjectsMonitoring(interaction: ImageAnalysisInteraction) {
    stopHighlightedSubjectsMonitoring()
    highlightedSubjectsMonitorInteraction = interaction
    lastNonEmptyHighlightedSubjects = nil
    subjectResolvedAtLiftPoint = nil
    previousHighlightedSubjectCount = 0
    sawImageSubjectActiveDuringLift = false
    hadActiveImageSubjectPulse = false
    subjectLiftSessionStart = Date()
    idleTicksWhileNoHighlightAndNoActiveSubject = 0
    didEmitLiftFinishForSession = false
    liftFinishAsyncFetchInFlight = false
    highlightedSubjectsMonitorDeadline = Date().addingTimeInterval(subjectLiftMonitorTimeout)

    if #available(iOS 17.0, *) {
      let point = lastSubjectLiftPoint
      Task { [weak self] in
        guard let self else { return }
        let ix = self.highlightedSubjectsMonitorInteraction
        guard let ix else { return }
        if let subject = await ix.subject(at: point) {
          await MainActor.run {
            if self.highlightedSubjectsMonitorInteraction === ix {
              self.subjectResolvedAtLiftPoint = subject
            }
          }
        }
      }
    }

    let timer = Timer(timeInterval: 0.12, repeats: true) { [weak self] _ in
      self?.tickHighlightedSubjectsMonitor()
    }
    highlightedSubjectsMonitorTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  private func stopHighlightedSubjectsMonitoring() {
    highlightedSubjectsMonitorTimer?.invalidate()
    highlightedSubjectsMonitorTimer = nil
    highlightedSubjectsMonitorInteraction = nil
    lastNonEmptyHighlightedSubjects = nil
    highlightedSubjectsMonitorDeadline = nil
    subjectResolvedAtLiftPoint = nil
  }

  private func tickHighlightedSubjectsMonitor() {
    guard let interaction = highlightedSubjectsMonitorInteraction else {
      stopHighlightedSubjectsMonitoring()
      return
    }
    if let deadline = highlightedSubjectsMonitorDeadline, Date() > deadline {
      if !didEmitLiftFinishForSession, let s = subjectResolvedAtLiftPoint {
        didEmitLiftFinishForSession = true
        emitImageCutoutBase64(subjects: [s], interaction: interaction)
      }
      stopHighlightedSubjectsMonitoring()
      return
    }

    let highlighted = interaction.highlightedSubjects
    let count = highlighted.count
    if !highlighted.isEmpty {
      lastNonEmptyHighlightedSubjects = highlighted
    }

    let endedHighlightSession = previousHighlightedSubjectCount > 0 && count == 0
    previousHighlightedSubjectCount = count

    var endedImageSubjectSession = false
    if #available(iOS 17.0, *) {
      let activeNow = interaction.activeInteractionTypes.contains(.imageSubject)
      if activeNow {
        hadActiveImageSubjectPulse = true
      }
      if activeNow || count > 0 || subjectResolvedAtLiftPoint != nil {
        sawImageSubjectActiveDuringLift = true
      }

      let elapsed = Date().timeIntervalSince(subjectLiftSessionStart ?? Date())
      if !activeNow && count == 0 {
        idleTicksWhileNoHighlightAndNoActiveSubject += 1
      } else {
        idleTicksWhileNoHighlightAndNoActiveSubject = 0
      }
      // Prefer: `activeInteractionTypes` briefly contains `.imageSubject`, then clears when the lift ends.
      let endAfterActivePulse = hadActiveImageSubjectPulse && !activeNow && count == 0 && elapsed > 0.12
      // Some OS versions never report `.imageSubject` in `activeInteractionTypes`; require a few
      // consecutive idle ticks so we don't emit mid-gesture when `activeNow` is always false.
      let endIdleWithResolvedSubject =
        subjectResolvedAtLiftPoint != nil && idleTicksWhileNoHighlightAndNoActiveSubject >= 6 && elapsed > 0.8
      endedImageSubjectSession = endAfterActivePulse || endIdleWithResolvedSubject
      if endedImageSubjectSession {
        sawImageSubjectActiveDuringLift = false
        hadActiveImageSubjectPulse = false
        idleTicksWhileNoHighlightAndNoActiveSubject = 0
      }
    }

    let shouldFinish = endedHighlightSession || endedImageSubjectSession
    if shouldFinish && !didEmitLiftFinishForSession && !liftFinishAsyncFetchInFlight {
      let subjects: Set<ImageAnalysisInteraction.Subject>?
      if let snap = lastNonEmptyHighlightedSubjects, !snap.isEmpty {
        subjects = snap
      } else if let one = subjectResolvedAtLiftPoint {
        subjects = [one]
      } else {
        subjects = nil
      }

      if let subs = subjects, !subs.isEmpty {
        didEmitLiftFinishForSession = true
        lastNonEmptyHighlightedSubjects = nil
        stopHighlightedSubjectsMonitoring()
        emitImageCutoutBase64(subjects: subs, interaction: interaction)
        return
      }

      if endedImageSubjectSession, #available(iOS 17.0, *) {
        let point = lastSubjectLiftPoint
        let ix = interaction
        liftFinishAsyncFetchInFlight = true
        Task { [weak self] in
          let s = await ix.subject(at: point)
          await MainActor.run {
            guard let self else { return }
            self.liftFinishAsyncFetchInFlight = false
            guard !self.didEmitLiftFinishForSession else { return }
            if let s {
              self.didEmitLiftFinishForSession = true
              self.stopHighlightedSubjectsMonitoring()
              self.emitImageCutoutBase64(subjects: [s], interaction: ix)
            }
          }
        }
      }
    }
  }

  // MARK: - onSubjectLifted

  private func mapLiftType(_ interactionType: ImageAnalysisInteraction.InteractionTypes) -> String {
    if interactionType.contains(.imageSubject) { return "image" }
    if interactionType.contains(.textSelection) { return "text" }
    if interactionType.contains(.dataDetectors) { return "dataDetector" }
    return "interaction"
  }

  private func emitSubjectLifted(type: String, data: String) {
    onSubjectLifted?(["type": type, "data": data])
  }

  private func emitTextSelectionBeganJSON(text: String) {
    let payload: [String: Any] = [
      "phase": "selectionBegan",
      "text": text,
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
       let json = String(data: jsonData, encoding: .utf8) {
      emitSubjectLifted(type: "text", data: json)
    }
  }

  /// Emit once per selection session when we first see non-empty selected text (iOS 17+).
  private func emitTextSelectionBeganIfNeeded(interaction: ImageAnalysisInteraction) {
    guard #available(iOS 17.0, *) else { return }
    guard !textSelectionBeganEmitted else { return }
    guard interaction.hasActiveTextSelection else { return }
    let t = interaction.selectedText ?? ""
    guard !t.isEmpty else { return }
    textSelectionBeganEmitted = true
    emitTextSelectionBeganJSON(text: t)
  }

  /// `selectedText` is often empty at `shouldBeginAt`; poll briefly for the first non-empty selection.
  private func attemptEagerTextSelectionSnapshot(interaction: ImageAnalysisInteraction) {
    Task { [weak self] in
      for _ in 0..<36 {
        try? await Task.sleep(nanoseconds: 50_000_000)
        let done = await MainActor.run { () -> Bool in
          guard let self else { return true }
          guard self.interaction === interaction else { return true }
          self.emitTextSelectionBeganIfNeeded(interaction: interaction)
          return self.textSelectionBeganEmitted
        }
        if done { return }
      }
    }
  }

  private func emitBegan(interactionType: ImageAnalysisInteraction.InteractionTypes) {
    let typeStr = mapLiftType(interactionType)
    let payload: [String: Any] = [
      "phase": "began",
      "interactionTypeRaw": NSNumber(value: interactionType.rawValue),
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
       let json = String(data: jsonData, encoding: .utf8) {
      emitSubjectLifted(type: typeStr, data: json)
    } else {
      emitSubjectLifted(type: typeStr, data: "{\"phase\":\"began\"}")
    }
  }

  private func emitImageCutoutBase64(subjects: Set<ImageAnalysisInteraction.Subject>, interaction: ImageAnalysisInteraction) {
    guard !subjects.isEmpty else { return }
    Task { [weak self] in
      guard let self else { return }
      do {
        let img = try await interaction.image(for: subjects)
        guard let png = img.pngData() else {
          await MainActor.run { self.emitSubjectLifted(type: "image", data: "") }
          return
        }
        let b64 = png.base64EncodedString()
        await MainActor.run { self.emitSubjectLifted(type: "image", data: b64) }
      } catch {
        await MainActor.run { self.emitSubjectLifted(type: "image", data: "") }
      }
    }
  }

  /// VisionKit does not expose a cutout in `shouldBeginAt` — only a point + interaction type. The
  /// background-removed bitmap is produced asynchronously; `image(for:)` often throws or is empty
  /// if called before segmentation for this lift is ready. We still try once here; monitoring covers the rest.
  @available(iOS 17.0, *)
  private func attemptEagerSubjectCutout(interaction: ImageAnalysisInteraction, point: CGPoint) {
    Task { [weak self] in
      guard let self else { return }
      do {
        guard let subject = await interaction.subject(at: point) else { return }
        let img = try await interaction.image(for: Set([subject]))
        guard let png = img.pngData() else { return }
        let b64 = png.base64EncodedString()
        await MainActor.run {
          guard !self.didEmitLiftFinishForSession else { return }
          self.didEmitLiftFinishForSession = true
          self.stopHighlightedSubjectsMonitoring()
          self.emitSubjectLifted(type: "image", data: b64)
        }
      } catch {
        // Normal on many builds — finish will arrive via highlight / activeInteractionTypes / timeout.
      }
    }
  }
}

// MARK: - ImageAnalysisInteractionDelegate

@available(iOS 16.0, *)
extension SubjectLiftView: ImageAnalysisInteractionDelegate {
  func interaction(
    _ interaction: ImageAnalysisInteraction,
    shouldBeginAt point: CGPoint,
    for interactionType: ImageAnalysisInteraction.InteractionTypes
  ) -> Bool {
    emitBegan(interactionType: interactionType)
    if interactionType.contains(.imageSubject) {
      lastSubjectLiftPoint = point
      startHighlightedSubjectsMonitoring(interaction: interaction)
      if #available(iOS 17.0, *) {
        attemptEagerSubjectCutout(interaction: interaction, point: point)
      }
    }
    if interactionType.contains(.textSelection), #available(iOS 17.0, *) {
      attemptEagerTextSelectionSnapshot(interaction: interaction)
    }
    return true
  }

  func textSelectionDidChange(_ interaction: ImageAnalysisInteraction) {
    let hasSel = interaction.hasActiveTextSelection
    if hasSel {
      if #available(iOS 17.0, *) {
        lastSelectedTextPreview = interaction.selectedText ?? ""
        emitTextSelectionBeganIfNeeded(interaction: interaction)
      } else {
        lastSelectedTextPreview = ""
      }
    }
    if hadActiveTextSelection && !hasSel {
      emitSubjectLifted(type: "text", data: lastSelectedTextPreview)
      textSelectionBeganEmitted = false
    }
    hadActiveTextSelection = hasSel
  }
}
