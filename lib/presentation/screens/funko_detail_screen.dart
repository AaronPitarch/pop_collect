import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FunkoDetailScreen extends StatefulWidget {
  final String funkoId;
  const FunkoDetailScreen({super.key, required this.funkoId});

  @override
  State<FunkoDetailScreen> createState() => _FunkoDetailScreenState();
}

class _FunkoDetailScreenState extends State<FunkoDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _image;
  String? _imageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadFunkoDetails();
  }

  //Metodo para cargar los detalles del funko desde Firestore
  Future<void> _loadFunkoDetails() async {
    final funkoDoc = await _firestore.collection('funkos').doc(widget.funkoId).get();
    final funkoData = funkoDoc.data() as Map<String, dynamic>;

    setState(() {
      _nameController.text = funkoData['name'];
      _descriptionController.text = funkoData['description'];
      _priceController.text = funkoData['price'].toString();
      _imageUrl = funkoData['imageUrl'];
    });
  }

  //Metodo para seleccionar una nueva imagen
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  //Metodo para subir la nueva imagen a Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = _storage.ref().child('funkos/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await storageRef.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  //Metodo para guardar los cambios en Firestore
  Future<void> _saveChanges() async {
    if(_formKey.currentState!.validate()) {
      String? newImageUrl = _imageUrl;
      //Subir la nueva imagen
      if (_image != null) {
        newImageUrl = await _uploadImage(_image!);
      }
      try {
        await _firestore.collection('funkos').doc(widget.funkoId).update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'imageUrl': newImageUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funko actualizado con éxito.')),
        );
        setState(() {
          _imageUrl = newImageUrl;
          _image = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar cambios.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Funko'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(_imageUrl != null && _image == null)
                Image.network(_imageUrl!, height: 200, fit: BoxFit.cover)
              else if(_image != null)
                Image.file(_image!, height: 200)
              else
                const Text('No hay imagen disponible'),

              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Funko',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del Funko';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Funko',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce una descripcion';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio del Funko',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce un precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, introduce un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt), 
                label: const Text('Cambiar Foto'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges, 
                child: const Text('Guardar cambios'),
              )
            ],
          )
        )
      ),
    );
  }
}