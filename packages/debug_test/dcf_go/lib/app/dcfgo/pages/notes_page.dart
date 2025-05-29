import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import '../store/store.dart';
import '../components/note_card.dart';
import '../components/add_note_modal.dart';
import '../components/top_bar.dart';


class NotesPage extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final notes = useStore(notesStore);
    final addModalVisible = useStore(addNoteModalStore);
    final searchQuery = useStore(searchQueryStore);

    // Filter notes based on search query
    final filteredNotes = searchQuery.state.isEmpty
        ? notes.state
        : notes.state.where((note) =>
            note.title.toLowerCase().contains(searchQuery.state.toLowerCase()) ||
            note.content.toLowerCase().contains(searchQuery.state.toLowerCase())).toList();

    return DCFView(
      layout: LayoutProps(flex: 1),
      style: StyleSheet(backgroundColor: Colors.grey[50]),
      children: [
        TopBar(),
        
        // Main content
        DCFView(
          layout: LayoutProps(
            flex: 1,
            padding: 16,
          ),
          children: [
            // Search bar
            DCFView(
              layout: LayoutProps(
                height: 50,
                width: "100%",
                marginBottom: 20,
                flexDirection: YogaFlexDirection.row,
                alignItems: YogaAlign.center,
              ),
              style: StyleSheet(
                backgroundColor: Colors.white,
                borderRadius: 25,
                shadowColor: Colors.black.withOpacity(0.1),
                shadowRadius: 4,
                shadowOffsetY: 2,
              ),
              children: [
                DCFView(
                  layout: LayoutProps(
                    width: 50,
                    height: 50,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                  ),
                  children: [
                    DCFIcon(
                      iconProps: IconProps(
                        name: DCFIcons.search,
                        color: Colors.grey[600],
                      ),
                      layout: LayoutProps(width: 20, height: 20),
                    ),
                  ],
                ),
                DCFTextInput(
                  placeholder: "Search notes...",
                  value: searchQuery.state,
                  fontSize: 16,
                  onChangeText: (text) {
                    print("text changed: $text");
                    searchQuery.setState(text);
                  },
                  layout: LayoutProps(
                    flex: 1,
                    height: 50,
                    paddingRight: 20,
                  ),
                  style: StyleSheet(
                    borderWidth: 0,
                  ),
                ),
              ],
            ),

            // Notes list
            filteredNotes.isEmpty
                ? DCFView(
                    layout: LayoutProps(
                      flex: 1,
                      alignItems: YogaAlign.center,
                      justifyContent: YogaJustifyContent.center,
                    ),
                    children: [
                      DCFIcon(
                        iconProps: IconProps(
                          name: DCFIcons.bookOpen,
                          color: Colors.grey[400],
                        ),
                        layout: LayoutProps(width: 80, height: 80, marginBottom: 20),
                      ),
                      DCFText(
                        content: searchQuery.state.isEmpty 
                            ? "No notes yet" 
                            : "No notes found",
                        textProps: TextProps(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: "600",
                        ),
                      ),
                      DCFText(
                        content: searchQuery.state.isEmpty 
                            ? "Tap the + button to create your first note" 
                            : "Try a different search term",
                        textProps: TextProps(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        layout: LayoutProps(marginTop: 8),
                      ),
                    ],
                  )
                : DCFScrollView(
                    layout: LayoutProps(flex: 1),
                    showsScrollIndicator: false,
                    children: filteredNotes.map((note) => NoteCard(note: note)).toList(),
                  ),
          ],
        ),

        // Floating Action Button
        DCFTouchableOpacity(
          onPress: (v) {
            addNoteModalStore.setState(true);
          },
          layout: LayoutProps(
            position: YogaPositionType.absolute,
            bottom: 30,
            right: 30,
            width: 60,
            height: 60,
            alignItems: YogaAlign.center,
            justifyContent: YogaJustifyContent.center,
          ),
          style: StyleSheet(
            backgroundColor: Colors.blue,
            borderRadius: 30,
            shadowColor: Colors.blue.withOpacity(0.4),
            shadowRadius: 8,
            shadowOffsetY: 4,
          ),
          children: [
            DCFIcon(
              iconProps: IconProps(
                name: DCFIcons.plus,
                color: Colors.white,
              ),
              layout: LayoutProps(width: 24, height: 24),
            ),
          ],
        ),

        // Add Note Modal
        DCFModal(
          visible: addModalVisible.state,
          backgroundColor: "rgba(0,0,0,0.5)",
          onDismiss: () {
            addNoteModalStore.setState(false);
          },
          children: [
            AddNoteModal(),
          ],
        ),
      ],
    );
  }
}
