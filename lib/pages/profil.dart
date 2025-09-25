import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfilPage extends StatefulWidget {
  final int userId;

  const ProfilPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late Future<User> _userFuture;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    setState(() {
      _userFuture = UserService.getUserProfile(widget.userId);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = await _userFuture;
      List<int>? imageBytes;

      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
      }

      await UserService.updateUserProfile(widget.userId, user, imageBytes);

      _showSuccess('Profil berhasil diperbarui');

      // Reload data
      _loadUserProfile();
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showEditDialog(User user) {
    TextEditingController usernameController = TextEditingController(
      text: user.username,
    );
    TextEditingController emailController = TextEditingController(
      text: user.email,
    );
    TextEditingController companyController = TextEditingController(
      text: user.companyName,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (user.profileImage != null
                                  ? NetworkImage(
                                      '${dotenv.env['API_BASE_URL']}/uploads/profiles/${user.profileImage}',
                                    )
                                  : const AssetImage(
                                      'assets/default_profile.png',
                                    ))
                              as ImageProvider,
                    child: _selectedImage == null && user.profileImage == null
                        ? Icon(Icons.camera_alt, size: 30, color: Colors.white)
                        : null,
                  ),
                ),
                SizedBox(height: 10),
                Text('Tap foto untuk mengubah', style: TextStyle(fontSize: 12)),
                SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: companyController,
                  decoration: InputDecoration(
                    labelText: 'Nama Perusahaan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    companyController.text.isEmpty) {
                  _showError('Semua field harus diisi');
                  return;
                }

                final updatedUser = User(
                  id: user.id,
                  username: usernameController.text,
                  email: emailController.text,
                  companyName: companyController.text,
                  profileImage: user.profileImage,
                );

                Navigator.pop(context); // Tutup dialog dulu
                await _updateProfile();
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement logout logic here
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Pengguna'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Memuat data profil...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Gagal memuat profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Data profil tidak ditemukan'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: Text('Muat Ulang'),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;

          return Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Photo
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(
                              '${dotenv.env['API_BASE_URL']}/uploads/profiles/${user.profileImage}',
                            )
                          : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                      child: user.profileImage == null
                          ? Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Company Name (TPK)
                Text(
                  user.companyName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text('TPK', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 30),

                // User Info Cards
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.blue),
                    title: Text('Username'),
                    subtitle: Text(
                      user.username.isNotEmpty ? user.username : '-',
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.email, color: Colors.blue),
                    title: Text('Email'),
                    subtitle: Text(user.email.isNotEmpty ? user.email : '-'),
                  ),
                ),

                Spacer(),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showEditDialog(user),
                        icon: Icon(Icons.edit),
                        label: Text('Edit Profil'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: Icon(Icons.logout),
                        label: Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
