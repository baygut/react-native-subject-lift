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
  @objc var onSubjectLiftBegan: RCTBubblingEventBlock?
  @objc var onSubjectLiftEnded: RCTBubblingEventBlock?

  // MARK: - Private

  private let imageView = UIImageView()
  private var interaction: ImageAnalysisInteraction?
  private let analyzer = ImageAnalyzer()
  private var analysisTask: Task<Void, Never>?

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupImageView()
    setupInteraction()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

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

    // Cancel any in-flight analysis
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
        let config = ImageAnalyzer.Configuration([.visualLookUp])
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
      // Subject lift only — no Live Text, no Visual Look Up
      interaction.preferredInteractionTypes = []
    case "automatic":
      interaction.preferredInteractionTypes = .automatic
    default:
      interaction.preferredInteractionTypes = .automatic
    }
  }

  private func emitAnalysisError(_ message: String) {
    onAnalysisComplete?(["status": "error", "message": message])
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
    return true
  }
}
