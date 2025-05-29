import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import '../models/note.dart';
import '../store/store.dart';
import 'image_picker_modal.dart';

class AddNoteModal extends StatefulComponent {
  @override
  DCFComponentNode render() {
    final selectedNote = useStore(selectedNoteStore);
    final imagePickerVisible = useStore(imagePickerModalStore);
    
    final isEditing = selectedNote.state != null;
    final title = useState(isEditing ? selectedNote.state!.title : "");
    final content = useState(isEditing ? selectedNote.state!.content : "");
    final avatarUrl = useState(isEditing ? selectedNote.state!.avatarUrl : "https://picsum.photos/200/200?random=1");
    final tags = useState<List<String>>(isEditing ? selectedNote.state!.tags : []);

    return DCFView(
      layout: LayoutProps(
        flex: 1,
        alignItems: YogaAlign.center,
        justifyContent: YogaJustifyContent.center,
        padding: 20,
      ),
      children: [
        DCFView(
          layout: LayoutProps(
        
        height: 120,
            padding: 24,
          ),
          style: StyleSheet(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowColor: Colors.black.withOpacity(0.2),
            shadowRadius: 12,
            shadowOffsetY: 4,
          ),
          children: [
            // Header
            DCFView(
              layout: LayoutProps(
                height: 100,
                flexDirection: YogaFlexDirection.row,
                justifyContent: YogaJustifyContent.spaceBetween,
                alignItems: YogaAlign.center,
                marginBottom: 24,
              ),
              children: [
                DCFText(
                  content: isEditing ? "Edit Note" : "New Note",
                  textProps: TextProps(
                    fontSize: 20,
                    fontWeight: "bold",
                    color: Colors.grey[900],
                  ),
                ),
                DCFTouchableOpacity(
                  onPress: (v) {
                    _closeModal();
                  },
                  layout: LayoutProps(
                    width: 32,
                    height: 32,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                  ),
                  children: [
                    DCFIcon(
                      iconProps: IconProps(
                        name: DCFIcons.x,
                        color: Colors.grey[600],
                      ),
                      layout: LayoutProps(width: 20, height: 20),
                    ),
                  ],
                ),
              ],
            ),

            DCFScrollView(
              layout: LayoutProps(flex: 1),
              showsScrollIndicator: false,
              children: [
                // Avatar selection
                DCFView(
                  layout: LayoutProps(
                    alignItems: YogaAlign.center,
                    marginBottom: 24,
                  ),
                  children: [
                    DCFTouchableOpacity(
                      onPress: (v) {
                        imagePickerModalStore.setState(true);
                      },
                      children: [
                        DCFView(
                          layout: LayoutProps(
                            width: 80,
                            height: 80,
                            marginBottom: 8,
                          ),
                          style: StyleSheet(
                            borderRadius: 40,
                            backgroundColor: Colors.grey[200],
                            borderWidth: 3,
                            borderColor: Colors.blue.withOpacity(0.3),
                          ),
                          children: [
                            DCFImage(
                              imageProps: ImageProps(
                                source: avatarUrl.value,
                                resizeMode: ImageResizeMode.cover,
                              ),
                              layout: LayoutProps(
                                width: 80,
                                height: 80,
                              ),
                              style: StyleSheet(
                                borderRadius: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    DCFText(
                      content: "Tap to change avatar",
                      textProps: TextProps(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: "500",
                      ),
                    ),
                  ],
                ),

                // Title input
                DCFView(
                  layout: LayoutProps(marginBottom: 16),
                  children: [
                    DCFText(
                      content: "Title",
                      textProps: TextProps(
                        fontSize: 14,
                        fontWeight: "600",
                        color: Colors.grey[700],
                      ),
                      layout: LayoutProps(marginBottom: 8),
                    ),
                    DCFView(
                      layout: LayoutProps(
                        height: 50,
                        padding: 12,
                      ),
                      style: StyleSheet(
                        backgroundColor: Colors.grey[50],
                        borderRadius: 8,
                        borderWidth: 1,
                        borderColor: Colors.grey[300],
                      ),
                      children: [
                        DCFTextInput(
                          placeholder: "Enter note title...",
                          value: title.value,
                          fontSize: 16,
                          onChangeText: (text) {
                            title.setValue(text);
                          },
                          layout: LayoutProps(flex: 1),
                          style: StyleSheet(
                            borderWidth: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Content input
                DCFView(
                  layout: LayoutProps(marginBottom: 16),
                  children: [
                    DCFText(
                      content: "Content",
                      textProps: TextProps(
                        fontSize: 14,
                        fontWeight: "600",
                        color: Colors.grey[700],
                      ),
                      layout: LayoutProps(marginBottom: 8),
                    ),
                    DCFView(
                      layout: LayoutProps(
                        height: 120,
                        padding: 12,
                      ),
                      style: StyleSheet(
                        backgroundColor: Colors.grey[50],
                        borderRadius: 8,
                        borderWidth: 1,
                        borderColor: Colors.grey[300],
                      ),
                      children: [
                        DCFTextInput(
                          placeholder: "Write your note here...",
                          value: content.value,
                          multiline: true,
                          fontSize: 16,
                          onChangeText: (text) {
                            content.setValue(text);
                          },
                          layout: LayoutProps(flex: 1),
                          style: StyleSheet(
                            borderWidth: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Action buttons
            DCFView(
              layout: LayoutProps(
                height: 100,
                flexDirection: YogaFlexDirection.row,
                justifyContent: YogaJustifyContent.spaceBetween,
                marginTop: 24,
              ),
              children: [
                DCFTouchableOpacity(
                  onPress: (v) {
                    _closeModal();
                  },
                  layout: LayoutProps(
                    flex: 1,
                    height: 50,
                    marginRight: 8,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                  ),
                  style: StyleSheet(
                    backgroundColor: Colors.grey[100],
                    borderRadius: 8,
                  ),
                  children: [
                    DCFText(
                      content: "Cancel",
                      textProps: TextProps(
                        fontSize: 16,
                        fontWeight: "600",
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                DCFTouchableOpacity(
                  onPress: (v) {
                    _saveNote(title.value, content.value, avatarUrl.value, tags.value, isEditing);
                  },
                  layout: LayoutProps(
                    flex: 1,
                    height: 50,
                    marginLeft: 8,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                  ),
                  style: StyleSheet(
                    backgroundColor: Colors.blue,
                    borderRadius: 8,
                  ),
                  children: [
                    DCFText(
                      content: isEditing ? "Update" : "Save",
                      textProps: TextProps(
                        fontSize: 16,
                        fontWeight: "600",
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Image Picker Modal
        DCFModal(
          visible: imagePickerVisible.state,
          backgroundColor: "rgba(0,0,0,0.5)",
          onDismiss: () {
            imagePickerModalStore.setState(false);
          },
          children: [
            ImagePickerModal(
              onImageSelected: (url) {
                avatarUrl.setValue(url);
                imagePickerModalStore.setState(false);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _closeModal() {
    addNoteModalStore.setState(false);
    selectedNoteStore.setState(null);
  }

  void _saveNote(String title, String content, String avatarUrl, List<String> tags, bool isEditing) {
    if (title.trim().isEmpty || content.trim().isEmpty) return;

    final notes = notesStore.state;
    final now = DateTime.now();

    if (isEditing) {
      final selectedNote = selectedNoteStore.state!;
      final updatedNote = selectedNote.copyWith(
        title: title.trim(),
        content: content.trim(),
        avatarUrl: avatarUrl,
        updatedAt: now,
        tags: tags,
      );
      
      final updatedNotes = notes.map((note) => 
        note.id == selectedNote.id ? updatedNote : note
      ).toList();
      
      notesStore.setState(updatedNotes);
    } else {
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        content: content.trim(),
        avatarUrl: avatarUrl,
        createdAt: now,
        updatedAt: now,
        tags: tags,
      );
      
      notesStore.setState([newNote, ...notes]);
    }

    _closeModal();
  }
}
