//
//  SongDetailMenuView.swift
//  Lyrics
//
//  Created by Liam Willey on 4/21/24.
//

import SwiftUI

struct SongDetailMenuView: View {
    @Binding var value: Int
    @Binding var design: Font.Design
    @Binding var weight: Font.Weight
    @Binding var lineSpacing: Double
    @Binding var alignment: TextAlignment
    
    @ObservedObject var songViewModel = SongViewModel.shared
    var song: Song
    
    var body: some View {
        Menu {
            Menu {
                Button(action: {
                    value = 18
                    songViewModel.updateTextProperties(song, size: 18)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    value = 12
                    songViewModel.updateTextProperties(song, size: 12)
                }, label: {
                    Text("12")
                })
                Button(action: {
                    value = 14
                    songViewModel.updateTextProperties(song, size: 14)
                }, label: {
                    Text("14")
                })
                Button(action: {
                    value = 16
                    songViewModel.updateTextProperties(song, size: 16)
                }, label: {
                    Text("16")
                })
                Button(action: {
                    value = 18
                    songViewModel.updateTextProperties(song, size: 18)
                }, label: {
                    Text("18")
                })
                Button(action: {
                    value = 20
                    songViewModel.updateTextProperties(song, size: 20)
                }, label: {
                    Text("20")
                })
                Button(action: {
                    value = 24
                    songViewModel.updateTextProperties(song, size: 24)
                }, label: {
                    Text("24")
                })
                Button(action: {
                    value = 28
                    songViewModel.updateTextProperties(song, size: 28)
                }, label: {
                    Text("28")
                })
                Button(action: {
                    value = 30
                    songViewModel.updateTextProperties(song, size: 30)
                }, label: {
                    Text("30")
                })
            } label: {
                Text("Font Size")
            }
            Menu {
                Button(action: {
                    design = .default
                    songViewModel.updateTextProperties(song, design: 0)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    design = .default
                    songViewModel.updateTextProperties(song, design: 0)}, label: {
                        Text("Regular")
                    })
                Button(action: {
                    design = .monospaced
                    songViewModel.updateTextProperties(song, design: 1)
                }, label: {
                    Text("Monospaced")
                })
                Button(action: {
                    design = .rounded
                    songViewModel.updateTextProperties(song, design: 2)
                }, label: {
                    Text("Rounded")
                })
                Button(action: {
                    design = .serif
                    songViewModel.updateTextProperties(song, design: 3)
                }, label: {
                    Text("Serif")
                })
            } label: {
                Text("Font Style")
            }
            Menu {
                Button(action: {
                    weight = .regular
                    songViewModel.updateTextProperties(song, weight: 0)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    weight = .black
                    songViewModel.updateTextProperties(song, weight: 1)
                }, label: {
                    Text("Black")
                })
                Button(action: {
                    songViewModel.updateTextProperties(song, weight: 2)
                    weight = .bold
                }, label: {
                    Text("Bold")
                })
                Button(action: {
                    weight = .heavy
                    songViewModel.updateTextProperties(song, weight: 3)
                }, label: {
                    Text("Heavy")
                })
                Button(action: {
                    weight = .light
                    songViewModel.updateTextProperties(song, weight: 4)
                }, label: {
                    Text("Light")
                })
                Button(action: {
                    weight = .medium
                    songViewModel.updateTextProperties(song, weight: 5)
                }, label: {
                    Text("Medium")
                })
                Button(action: {
                    weight = .regular
                    songViewModel.updateTextProperties(song, weight: 6)
                }, label: {
                    Text("Regular")
                })
                Button(action: {
                    weight = .semibold
                    songViewModel.updateTextProperties(song, weight: 7)
                }, label: {
                    Text("Semibold")
                })
                Button(action: {
                    weight = .thin
                    songViewModel.updateTextProperties(song, weight: 8)
                }, label: {
                    Text("Thin")
                })
                Button(action: {
                    weight = .ultraLight
                    songViewModel.updateTextProperties(song, weight: 0)
                }, label: {
                    Text("Ultra Light")
                })
            } label: {
                Text("Font Weight")
            }
            Menu {
                Button(action: {
                    lineSpacing = 1
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    lineSpacing = 1
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("0.0")
                })
                Button(action: {
                    lineSpacing = 5
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("0.5")
                })
                Button(action: {
                    lineSpacing = 10
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("1.0")
                })
                Button(action: {
                    lineSpacing = 15
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("1.5")
                })
                Button(action: {
                    lineSpacing = 20
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("2.0")
                })
                Button(action: {
                    lineSpacing = 25
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("2.5")
                })
                Button(action: {
                    lineSpacing = 30
                    songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                }, label: {
                    Text("3.0")
                })
            } label: {
                Text("Line Spacing")
            }
            Menu {
                Button(action: {
                    alignment = .leading
                    songViewModel.updateTextProperties(song, alignment: 0)
                }, label: {
                    Text("Default")
                })
                Divider()
                Button(action: {
                    alignment = .leading
                    songViewModel.updateTextProperties(song, alignment: 0)
                }, label: {
                    Text("Left")
                })
                Button(action: {
                    alignment = .center
                    songViewModel.updateTextProperties(song, alignment: 1)
                }, label: {
                    Text("Center")
                })
                Button(action: {
                    alignment = .trailing
                    songViewModel.updateTextProperties(song, alignment: 2)
                }, label: {
                    Text("Right")
                })
            } label: {
                Text("Alignment")
            }
            Divider()
            Button {
                value = 18
                songViewModel.updateTextProperties(song, size: 18)
                
                design = .default
                songViewModel.updateTextProperties(song, design: 0)
                
                weight = .regular
                songViewModel.updateTextProperties(song, weight: 0)
                
                lineSpacing = 1
                songViewModel.updateTextProperties(song, lineSpacing: lineSpacing)
                
                alignment = .leading
                songViewModel.updateTextProperties(song, alignment: 0)
            } label: {
                Text("Restore to Defaults")
            }
        } label: {
            Image(systemName: "textformat.size")
                .modifier(NavBarButtonViewModifier())
        }
    }
}
