class CommunityComment {
  final String id;
  final String authorName;
  final String text;
  final bool isExpert; // Highlights expert badges in UI
  final bool isApproved;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.authorName,
    required this.text,
    this.isExpert = false,
    this.isApproved = false,
    required this.createdAt,
  });

  CommunityComment copyWith({
    String? id,
    String? authorName,
    String? text,
    bool? isExpert,
    bool? isApproved,
    DateTime? createdAt,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      text: text ?? this.text,
      isExpert: isExpert ?? this.isExpert,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      text: json['text'] as String,
      isExpert: json['isExpert'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'text': text,
      'isExpert': isExpert,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CommunityPost {
  final String id;
  final String systemType; // One of the 9 systems (e.g., HVAC, Automotive)
  final String deviceModel;
  final String issueDescription;
  final String successfulSolution;
  final String approximateCost;
  final bool isPublic;
  final bool isVerified;
  final bool isApproved;
  final String authorName; // Defaulted to 'عضو مجهول' if isPublic is true
  final List<CommunityComment> comments;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.systemType,
    required this.deviceModel,
    required this.issueDescription,
    required this.successfulSolution,
    required this.approximateCost,
    this.isPublic = false,
    this.isVerified = false,
    this.isApproved = false,
    this.authorName = 'عضو مجهول',
    required this.comments,
    required this.createdAt,
  });

  CommunityPost copyWith({
    String? id,
    String? systemType,
    String? deviceModel,
    String? issueDescription,
    String? successfulSolution,
    String? approximateCost,
    bool? isPublic,
    bool? isVerified,
    bool? isApproved,
    String? authorName,
    List<CommunityComment>? comments,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      systemType: systemType ?? this.systemType,
      deviceModel: deviceModel ?? this.deviceModel,
      issueDescription: issueDescription ?? this.issueDescription,
      successfulSolution: successfulSolution ?? this.successfulSolution,
      approximateCost: approximateCost ?? this.approximateCost,
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      authorName: authorName ?? this.authorName,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    var commentsList = json['comments'] as List? ?? [];
    List<CommunityComment> parsedComments = commentsList
        .map((c) => CommunityComment.fromJson(c as Map<String, dynamic>))
        .toList();

    return CommunityPost(
      id: json['id'] as String,
      systemType: json['systemType'] as String,
      deviceModel: json['deviceModel'] as String,
      issueDescription: json['issueDescription'] as String,
      successfulSolution: json['successfulSolution'] as String,
      approximateCost: json['approximateCost'] as String,
      isPublic: json['isPublic'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      authorName: json['authorName'] as String? ?? 'عضو مجهول',
      comments: parsedComments,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systemType': systemType,
      'deviceModel': deviceModel,
      'issueDescription': issueDescription,
      'successfulSolution': successfulSolution,
      'approximateCost': approximateCost,
      'isPublic': isPublic,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'authorName': authorName,
      'comments': comments.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
