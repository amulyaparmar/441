import SwiftUI
import UIKit
import AVKit

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var sourceType: UIImagePickerController.SourceType?
    @Binding var image: UIImage?
    @Binding var videoUrl: URL?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType ?? .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.mediaTypes = ["public.image","public.movie"]
        picker.videoMaximumDuration = TimeInterval(5) // limit duration to help reduce upload size
        picker.videoQuality = .typeLow
        return picker
    }
    
    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {
        // No dynamic updates needed
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let controller: ImagePicker
        
        init(_ controller: ImagePicker) {
            self.controller = controller
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            controller.dismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
            if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
                if mediaType  == "public.image" {
                    controller.image = (info[UIImagePickerController.InfoKey.editedImage] as? UIImage ??
                                       info[UIImagePickerController.InfoKey.originalImage] as? UIImage)?
                        .resizeImage(targetSize: CGSize(width: 150, height: 181))!
                 } else if mediaType == "public.movie" {
                    controller.videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL
                }
            }
            controller.dismiss()
        }
    }
}

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage? {
        // Determine the scaling ratio
        let ratio = (targetSize.width > targetSize.height)
            ? targetSize.height / size.height
            : targetSize.width / size.width
        
        // Compute new size and draw
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

struct VideoView: View {
    let videoUrl: URL
    @State private var isPlaying = false

    var body: some View {
        let videoPlayer = AVPlayer(url: videoUrl)
        let playedToEnd = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)

        VideoPlayer(player: videoPlayer)
            .onTapGesture {
                isPlaying ? videoPlayer.pause() : videoPlayer.play()
                isPlaying.toggle()
            }
            .onReceive(playedToEnd) { _ in
                videoPlayer.seek(to: .zero)
            }
    }
}
