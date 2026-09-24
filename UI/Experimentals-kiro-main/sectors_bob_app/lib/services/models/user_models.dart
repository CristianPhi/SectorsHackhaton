/// The signed-in user.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.isGoogle = false,
  });

  final String id;
  final String email;
  final String displayName;

  /// True when the account came from the Google sign-in flow.
  final bool isGoogle;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      isGoogle: json['isGoogle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'isGoogle': isGoogle,
    };
  }
}
