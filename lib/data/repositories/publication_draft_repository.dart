import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../presentation/widgets/publication_draft_helper.dart';

class PublicationDraftRepository {
  FirebaseFirestore? get _firestore => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;
  CollectionReference? get _publicationDraftsCollection =>
      _firestore?.collection('publication_drafts');

  Future<void> saveDraft(PublicationDraft draft) async {
    final collection = _publicationDraftsCollection;
    if (collection == null) return;
    await collection.add(draft.toJson());
  }

  // TODO: getPendingDrafts(...)
  // TODO: approveDraft(...)
  // TODO: rejectDraft(...)
}
