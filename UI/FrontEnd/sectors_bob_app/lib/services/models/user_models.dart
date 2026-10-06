/// The signed-in user.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.isGoogle = false,
    this.emailVerified = false,
    this.developmentCode,
  });

  final String id;
  final String email;
  final String displayName;

  /// True when the account came from the Google sign-in flow.
  final bool isGoogle;

  /// True when the account has passed email verification.
  final bool emailVerified;

  final String? developmentCode;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] ?? '').toString();
    final String email = (json['email'] ?? '').toString();
    final String displayName =
        (json['displayName'] ?? json['name'] ?? email).toString();

    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      isGoogle: json['isGoogle'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      developmentCode: json['developmentCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'isGoogle': isGoogle,
      'emailVerified': emailVerified,
    };
  }
}
