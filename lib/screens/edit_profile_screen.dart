import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../Helper/AppColors.dart';
import '../API/API.dart';
import '../API/ApiUrls.dart';

/// Name, mobile number, address and photo are editable — email is the
/// account's login identity and can't be changed from the app. Name
/// and mobile number are mandatory; the mobile number is NOT OTP-
/// verified, whatever the student types in gets saved as-is.
class EditProfileScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String address;
  final String? photoUrl;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    this.photoUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final ImagePicker _picker = ImagePicker();
  File? _pickedPhoto;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone);
    _addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1000, maxHeight: 1000);
    if (xfile == null) return;
    setState(() => _pickedPhoto = File(xfile.path));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number is required')));
      return;
    }
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 10-digit mobile number')));
      return;
    }

    setState(() => _isSaving = true);

    if (_pickedPhoto != null) {
      final photoRes = await APIService.uploadFile(
        context: context,
        url: ApiUrls.updateProfilePhoto,
        imageFile: _pickedPhoto!,
        fieldName: 'photo',
      );
      if (photoRes == "Error" || !mounted) {
        setState(() => _isSaving = false);
        return;
      }
    }

    final response = await APIService.putApiCaller(
      context: context,
      url: ApiUrls.updateProfile,
      body: {"name": name, "phone": phone, "address": _addressController.text.trim()},
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (response == "Error") return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.navy), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                        backgroundImage: _pickedPhoto != null
                            ? FileImage(_pickedPhoto!) as ImageProvider
                            : (widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null),
                        child: (_pickedPhoto == null && widget.photoUrl == null)
                            ? const Icon(Icons.person, color: AppColors.primaryBlue, size: 52)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text('Name *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Your full name',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '10-digit mobile number',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.call_outlined, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "This number isn't verified by OTP — whatever you enter is saved as-is.",
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              const Text('Address', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'House no., street, city, state, PIN',
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // Email is fixed intentionally — it's the account's login
              // identity and can't be edited from here.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Email address cannot be changed', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.5),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
