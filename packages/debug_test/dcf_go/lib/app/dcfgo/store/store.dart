import 'package:dcflight/framework/renderer/vdom/component/store.dart';
import '../models/note.dart';

// Sample notes for demo
final _sampleNotes = [
  Note(
    id: "1",
    title: "Welcome to DCFGo Notes!",
    content: "This is your first note in DCFGo! You can create, edit, and organize your thoughts here. Tap the + button to add new notes, and tap on any note to edit it.",
    avatarUrl: "https://picsum.photos/200/200?random=1",
    createdAt: DateTime.now().subtract(Duration(days: 2)),
    updatedAt: DateTime.now().subtract(Duration(days: 2)),
    tags: ["welcome", "tutorial"],
  ),
  Note(
    id: "2",
    title: "Meeting Notes - Project Alpha",
    content: "Discussed project timeline and deliverables. Key points:\n- Phase 1 completion by end of month\n- Need to review user feedback\n- Schedule follow-up meeting next week",
    avatarUrl: "https://picsum.photos/200/200?random=2",
    createdAt: DateTime.now().subtract(Duration(hours: 6)),
    updatedAt: DateTime.now().subtract(Duration(hours: 6)),
    tags: ["meeting", "work"],
  ),
  Note(
    id: "3",
    title: "Recipe Ideas",
    content: "Some delicious recipes to try this weekend:\n- Homemade pasta with garlic and herbs\n- Chocolate chip cookies\n- Vegetable stir-fry with ginger",
    avatarUrl: "https://picsum.photos/200/200?random=3",
    createdAt: DateTime.now().subtract(Duration(minutes: 30)),
    updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
    tags: ["cooking", "personal"],
  ),
];

// Global store for notes
final notesStore = Store<List<Note>>(_sampleNotes);

// Store for selected note (for editing)
final selectedNoteStore = Store<Note?>(null);

// Store for modal visibility
final addNoteModalStore = Store<bool>(false);
final imagePickerModalStore = Store<bool>(false);

// Store for current tab index
final currentTabStore = Store<int>(0);

// Store for search query
final searchQueryStore = Store<String>('');
