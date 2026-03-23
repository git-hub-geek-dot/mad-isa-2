import 'package:flutter/material.dart';
import 'package:dynamic_scenario_game/features/history/domain/models/game_run_history.dart';
import 'package:dynamic_scenario_game/features/history/domain/repositories/game_history_service.dart';

class GameNotesScreen extends StatefulWidget {
  const GameNotesScreen({
    Key? key,
    required this.gameRun,
    required this.historyService,
  }) : super(key: key);

  final GameRunHistory gameRun;
  final GameHistoryService historyService;

  @override
  State<GameNotesScreen> createState() => _GameNotesScreenState();
}

class _GameNotesScreenState extends State<GameNotesScreen> {
  late TextEditingController _noteController;
  late List<GameNote> _notes;
  String? _editingNoteId;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _notes = List.from(widget.gameRun.notes);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty')),
      );
      return;
    }

    try {
      await widget.historyService.addNote(
        widget.gameRun.sessionId,
        _noteController.text,
      );

      _noteController.clear();
      _loadNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding note: $e')),
      );
    }
  }

  Future<void> _updateNote(String noteId) async {
    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note cannot be empty')),
      );
      return;
    }

    try {
      await widget.historyService.updateNote(
        widget.gameRun.sessionId,
        noteId,
        _noteController.text,
      );

      _noteController.clear();
      setState(() => _editingNoteId = null);
      _loadNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e')),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await widget.historyService.deleteNote(
        widget.gameRun.sessionId,
        noteId,
      );

      _loadNotes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  void _loadNotes() {
    // Notes will be reloaded from Firestore
    // This is a workaround - ideally you'd use a stream
    widget.historyService.getGameRunDetails(widget.gameRun.sessionId).then((gameRun) {
      if (gameRun != null) {
        setState(() {
          _notes = List.from(gameRun.notes);
        });
      }
    });
  }

  void _startEditNote(GameNote note) {
    setState(() {
      _editingNoteId = note.id;
      _noteController.text = note.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingNoteId = null;
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Notes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Game Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.gameRun.categoryTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ending: ${widget.gameRun.endingTitle}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Add/Edit Note Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingNoteId == null ? 'Add a Note' : 'Edit Note',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your note here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_editingNoteId != null)
                      ElevatedButton(
                        onPressed: _cancelEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('Cancel'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _editingNoteId == null
                          ? _addNote
                          : () => _updateNote(_editingNoteId!),
                      child: Text(
                        _editingNoteId == null ? 'Add Note' : 'Update Note',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Text(
                      'No notes yet. Add one above!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.content,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Updated: ${note.updatedAt.toString().split('.')[0]}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _startEditNote(note),
                                        icon: const Icon(Icons.edit),
                                        iconSize: 18,
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteNote(note.id),
                                        icon: const Icon(Icons.delete),
                                        iconSize: 18,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
