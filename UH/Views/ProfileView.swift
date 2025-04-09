import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showImagePicker = false
    
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                VStack(spacing: 20) {
                    Button(action: {
                        showImagePicker.toggle()
                    }) {
                        if let avatarImage = viewModel.avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 50)
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(selectedImage: $viewModel.avatarImage) {
                            viewModel.saveProfile()
                        }
                    }
                    
                    TextField("Введите имя", text: $viewModel.username, onCommit: {
                        viewModel.saveProfile()
                    })
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .frame(width: 300)
                    .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onDismiss: (() -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onDismiss?()
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
