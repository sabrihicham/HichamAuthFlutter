class UserModel {
  final int? id;
  final String name;
  final String email;
  final String? avatar;
  final String? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SocialAccount>? socialAccounts;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.socialAccounts,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      socialAccounts: _parseSocialAccounts(json),
    );
  }

  // Helper method to parse social accounts from different structures
  static List<SocialAccount>? _parseSocialAccounts(Map<String, dynamic> json) {
    // If social_accounts array exists, use it
    if (json['social_accounts'] != null) {
      return List<SocialAccount>.from(
        json['social_accounts'].map((x) => SocialAccount.fromJson(x)),
      );
    }

    // If single provider info exists, create a social account
    if (json['provider'] != null) {
      String providerId = '';

      // Try different provider ID field patterns
      if (json['provider_id'] != null) {
        providerId = json['provider_id'].toString();
      } else if (json['${json['provider']}_id'] != null) {
        providerId = json['${json['provider']}_id'].toString();
      } else if (json['facebook_id'] != null &&
          json['provider'] == 'facebook') {
        providerId = json['facebook_id'].toString();
      } else if (json['google_id'] != null && json['provider'] == 'google') {
        providerId = json['google_id'].toString();
      } else if (json['apple_id'] != null && json['provider'] == 'apple') {
        providerId = json['apple_id'].toString();
      }

      return [
        SocialAccount(
          provider: json['provider'],
          providerId: providerId,
          avatar: json['avatar'],
        ),
      ];
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'social_accounts': socialAccounts?.map((x) => x.toJson()).toList(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SocialAccount>? socialAccounts,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      socialAccounts: socialAccounts ?? this.socialAccounts,
    );
  }
}

class SocialAccount {
  final int? id;
  final String provider;
  final String providerId;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SocialAccount({
    this.id,
    required this.provider,
    required this.providerId,
    this.avatar,
    this.createdAt,
    this.updatedAt,
  });

  factory SocialAccount.fromJson(Map<String, dynamic> json) {
    return SocialAccount(
      id: json['id'],
      provider: json['provider'] ?? '',
      providerId: json['provider_id'] ?? '',
      avatar: json['avatar'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'provider_id': providerId,
      'avatar': avatar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
