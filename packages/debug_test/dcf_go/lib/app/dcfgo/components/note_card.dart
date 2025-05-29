import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import '../models/note.dart';
import '../store/store.dart';

class NoteCard extends StatefulComponent {
  final Note note;

  NoteCard({required this.note});

  @override
  DCFComponentNode render() {
    return DCFTouchableOpacity(
      onPress: (v) {
        selectedNoteStore.setState(note);
        addNoteModalStore.setState(true);
      },
      layout: LayoutProps(
        width: "100%",
        marginBottom: 8,
      ),
      children: [
        DCFView(
          layout: LayoutProps(
            width: "100%",
            padding: 16,
            flexDirection: YogaFlexDirection.row,
          ),
          style: StyleSheet(
            backgroundColor: Colors.white,
            borderRadius: 12,
            shadowColor: Colors.black.withOpacity(0.1),
            shadowRadius: 4,
            shadowOffsetY: 2,
          ),
          children: [
            // Avatar
            DCFView(
              layout: LayoutProps(
                width: 50,
                height: 50,
                marginRight: 16,
              ),
              style: StyleSheet(
                borderRadius: 25,
                backgroundColor: Colors.grey[200],
              ),
              children: [
                DCFImage(
                  imageProps: ImageProps(
                    source: note.avatarUrl,
                    resizeMode: ImageResizeMode.cover,
                  ),
                  layout: LayoutProps(
                    width: 50,
                    height: 50,
                  ),
                  style: StyleSheet(
                    borderRadius: 25,
                  ),
                ),
              ],
            ),
            // Content
            DCFView(
              layout: LayoutProps(
                flex: 1,
                justifyContent: YogaJustifyContent.spaceBetween,
              ),
              children: [
                DCFText(
                  content: note.title,
                  textProps: TextProps(
                    fontSize: 16,
                    fontWeight: "600",
                    color: Colors.grey[900]!,
                  ),
                ),
                DCFText(
                  content: note.content.length > 100
                      ? '${note.content.substring(0, 100)}...'
                      : note.content,
                  textProps: TextProps(
                    fontSize: 14,
                    color: Colors.grey[600]!,
                  ),
                  layout: LayoutProps(marginTop: 4),
                ),
                DCFView(
                  layout: LayoutProps(
                    flexDirection: YogaFlexDirection.row,
                    justifyContent: YogaJustifyContent.spaceBetween,
                    alignItems: YogaAlign.center,
                    marginTop: 8,
                  ),
                  children: [
                    DCFText(
                      content: _formatDate(note.updatedAt),
                      textProps: TextProps(
                        fontSize: 12,
                        color: Colors.grey[500]!,
                      ),
                    ),
                    if (note.tags.isNotEmpty)
                      DCFView(
                        layout: LayoutProps(
                          height: 20,
                          flexDirection: YogaFlexDirection.row,
                        ),
                        children: note.tags.map((tag) => DCFView(
                       
                          style: StyleSheet(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            borderRadius: 5,
                          ),
                          children: [
                            DCFText(
                              content: tag,
                              textProps: TextProps(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: "500",
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                  ],
                ),
              ],
            ),
            // Menu button
            DCFTouchableOpacity(
              onPress: (v) => _showDeleteConfirmation(),
              layout: LayoutProps(
                width: 32,
                height: 32,
                alignItems: YogaAlign.center,
                justifyContent: YogaJustifyContent.center,
              ),
              children: [
                DCFIcon(
                  iconProps: IconProps(
                    name: DCFIcons.delete,
                    color: Colors.grey[400]!,
                  ),
                  layout: LayoutProps(width: 16, height: 16),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteConfirmation() {
    // TODO: Show confirmation dialog
    final currentNotes = notesStore.state;
    notesStore.setState(currentNotes.where((n) => n.id != note.id).toList());
  }
}