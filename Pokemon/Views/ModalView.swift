import SwiftUI
import WebKit

struct ModalView: View {
    let pokemon: Pokemon
    let types: [String] = []
    
    @StateObject private var viewModel = PokemonViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var isPresented: Bool // Binding to control the visibility of the modal
    
    @State private var isLoading = true
    @State private var error: Error?
    @State private var imageUrl: URL?
    @State private var isStarred: Bool = false
    
    @State private var isShareSheetPresented = false
    
    var updateFavorites: ((Pokemon) -> Void)?
    
    var pokemonData: PokemonData {
        return viewModel.pokemonData ?? PokemonData(weight: 0.0, height: 0.0, types: [], sprites: nil)
    }
    
    var capitalizedPokemonName: String {
        let name = pokemon.name
        return name.capitalized
    }
    
    var weightInKilograms: String {
        let hectograms = pokemonData.weight
        let kilograms = hectograms * 0.1
        return String(format: "%.2f", kilograms)
    }
    
    var heightInMeters: String {
        let decimeters = pokemonData.height
        let meters = decimeters * 0.1
        return String(format: "%.2f", meters)
    }
    
    init(pokemon: Pokemon, isPresented: Binding<Bool>, updateFavorites: @escaping (Pokemon) -> Void) {
        self.pokemon = pokemon
        self._isPresented = isPresented
        self.updateFavorites = updateFavorites
        _isStarred = State(initialValue: pokemon.isFavorite ?? false ? true : false)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    self.isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .padding()
            }
            
            VStack(alignment: .center, spacing: 16) {
                ZStack {
                    Image("Background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 400, height: 200)
                        .cornerRadius(10)
                    
                    // The pokemon image
                    ImageView(url: imageUrl)
                    
                }
                
                Divider()
                
                Text("Name: \(capitalizedPokemonName)")
                    .font(Font.custom("Lato", size: 18).weight(.bold))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                    .redacted(when: isLoading)
                
                Divider()
                
                Text("Weight: \(weightInKilograms) kg")
                    .font(
                        Font.custom("Lato", size: 18)
                            .weight(.bold)
                    )
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                    .redacted(when: isLoading)
                
                Divider()
                
                Text("Height: \(heightInMeters) m")
                    .font(
                        Font.custom("Lato", size: 18)
                            .weight(.bold)
                    )
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                    .redacted(when: isLoading)
                
                Divider()
                
                Text("Types: \(getAllTypes(data: pokemonData))")
                    .font(
                        Font.custom("Lato", size: 18)
                            .weight(.bold)
                    )
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                    .redacted(when: isLoading)
            }
            .padding()
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    // Perform action for sharing
                    // Add your sharing logic here
                    isShareSheetPresented = true
                }) {
                    Text("Share to my friends")
                }
                .buttonStyle(ActionButtonStyle(selectedOption: .all))
                .padding(.leading, 50)
                .sheet(isPresented: $isShareSheetPresented, content: {
                    shareSheet
                })
                
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(isStarred ? .yellow : .gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(.trailing, 50)
            }
            Spacer()
        }
        .background(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                viewModel.fetchPokemonData(for: pokemon) { success in
                    if success {
                        self.imageUrl = URL(string: (pokemonData.sprites?.other?.officialArtwork!.frontDefault)!)
                        self.isLoading = false
                    }
                }
            }
        }
        .animation(.easeOut)
    }
    
    // Share Sheet view
    var shareSheet: some View {
        let textToShare = """
                Name: \(capitalizedPokemonName)
                Weight: \(weightInKilograms) kg
                Height: \(heightInMeters) m
                Types: \(getAllTypes(data: pokemonData))
            """
        
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        
        // Callback when share sheet is dismissed
        activityViewController.completionWithItemsHandler = { (activityType, completed, _, _) in
            if completed {
                // Handle completion
            }
            isShareSheetPresented = false // Dismiss the share sheet
        }
        
        // UIKit to SwiftUI bridge
        let viewController = UIApplication.shared.windows.first?.rootViewController
        viewController?.present(activityViewController, animated: true, completion: nil)
        
        return EmptyView()
    }
    
    func getAllTypes(data: PokemonData) -> String {
        if let types = data.types {
            let typeNames = types.map { $0.type.name }
            let joinedNames = typeNames.joined(separator: ", ")
            
            return joinedNames
        }
        return ""
    }
    
    func toggleFavorite() {
        isStarred.toggle()
        updateFavorites?(pokemon) // Call the closure to update favorites
    }
}

struct ImageView: View {
    
    var url: URL?
    
    var body: some View {
        AsyncImage(url: url) { img in
            img
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200, alignment: .center)
        } placeholder: {
            
        }
    }
}

struct ModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalView(pokemon: Pokemon(id: UUID(), name: "Pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/"), isPresented: .constant(true), updateFavorites: { _ in })
    }
}

