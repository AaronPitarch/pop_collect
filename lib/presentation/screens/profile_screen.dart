import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _usernameController = TextEditingController();
  User? _currentUser;
  String? _profileImageUrl;
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserProfile();
  }

  //Metodo para cargar los datos del usuario desde Firestore
  Future<void> _loadUserProfile() async {
    if (_currentUser != null) {
      final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _usernameController.text = userData['username'] ?? '';
          _profileImageUrl = userData['profileImageUrl'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontraron datos del usuario')),
        );
      }
    }
  }

  //Metodo para seleccionar una nueva foto de perfil
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if ( pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  //Metodo para subir la nueva foto de perfil a Firebase Storage
  Future<String?> _uploadProfileImage(File image) async {
    try {
      final storageRef = _storage.ref().child('profiles/${_currentUser!.uid}/profile.jpg');
      final uploadTask = await storageRef.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  //Metodo para actualizar el perfil de usiario
  Future<void> _updateUserProfile() async {
    String? newImageUrl = _profileImageUrl;

    //Subir nueva imagen si fue seleccionada
    if (_newProfileImage != null) {
      newImageUrl = await _uploadProfileImage(_newProfileImage!);
    }

    try {
      //Verificar si el documento del usuario existe antes de actualizarlo
      final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
      final userDocsSnapshot = await userDocRef.get();

      if (userDocsSnapshot.exists) {
        //Actualizar el documento si existe
        await userDocRef.update({
          'username': _usernameController.text.trim(),
          'profileImageUrl': newImageUrl,
        });
      } else {
        //Crear el documento si no existe
        await userDocRef.set({
          'username': _usernameController.text.trim(),
          'profileImageUrl': newImageUrl,
          'email': _currentUser!.email,
          'createdAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el perfil: $e')),
      );
    }

    //Actualizar la informacion del usuario en Firestore
    await _firestore.collection('users').doc(_currentUser!.uid).update({
      'username': _usernameController.text.trim(),
      'profileImageUrl': newImageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado con éxito.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //Mostrar imagen de perfil
            GestureDetector(
              onTap: _pickProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _newProfileImage != null
                  ? FileImage(_newProfileImage!)
                  : (_profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/default_profile.jpg')) as ImageProvider,
                child: _newProfileImage == null && _profileImageUrl == null
                  ? const Icon(Icons.camera_alt, size: 50)
                  : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateUserProfile, 
              child: const Text('Guardar cambios')
            ),
          ],
        ),
      ),
    );
  }
}