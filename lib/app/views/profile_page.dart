import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/social_auth_controller.dart';
import '../services/logout_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final SocialAuthController controller = Get.find<SocialAuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _showLogoutDialog(context, controller);
                  break;
                case 'delete':
                  _showDeleteAccountDialog(context, controller);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('تسجيل الخروج'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    'حذف الحساب',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return const Center(child: Text('لم يتم العثور على بيانات المستخدم'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 3),
                ),
                child: CircleAvatar(
                  radius: 57,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      user.avatar != null && user.avatar!.isNotEmpty
                      ? NetworkImage(user.avatar!)
                      : null,
                  child: user.avatar == null || user.avatar!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade600,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 24),

              // User Info Cards
              _buildInfoCard(
                icon: Icons.person,
                title: 'الاسم',
                value: user.name.isNotEmpty ? user.name : 'غير محدد',
              ),

              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.email,
                title: 'البريد الإلكتروني',
                value: user.email.isNotEmpty ? user.email : 'غير محدد',
              ),

              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.verified_user,
                title: 'حالة التحقق',
                value: user.emailVerifiedAt != null ? 'محقق' : 'غير محقق',
                valueColor: user.emailVerifiedAt != null
                    ? Colors.green
                    : Colors.orange,
              ),

              if (user.socialAccounts != null &&
                  user.socialAccounts!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: _getProviderIcon(user.socialAccounts!.first.provider),
                  title: 'مقدم الخدمة',
                  value: _getProviderName(user.socialAccounts!.first.provider),
                  valueColor: _getProviderColor(
                    user.socialAccounts!.first.provider,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'تاريخ الإنشاء',
                value: _formatDate(user.createdAt?.toIso8601String()),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.loadUserProfile(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('تحديث البيانات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, controller),
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.account_circle;
    }
  }

  String _getProviderName(String provider) {
    switch (provider.toLowerCase()) {
      case 'facebook':
        return 'Facebook';
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      default:
        return provider;
    }
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'google':
        return const Color(0xFF4285F4);
      case 'apple':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _showLogoutDialog(
    BuildContext context,
    SocialAuthController controller,
  ) {
    LogoutService.logoutWithConfirmation(
      context: context,
      onSuccess: (message) {
        // Clear controller state
        controller.currentUser.value = null;
        controller.isAuthenticated.value = false;
      },
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    SocialAuthController controller,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text(
            'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'حذف نهائياً',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
