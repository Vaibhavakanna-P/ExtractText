import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Text Extractor (Web)',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ------------------ LOGIN PAGE ------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final userIdController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final roleController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextExtractionWebPage(
            name: nameController.text,
            userId: userIdController.text,
            email: emailController.text,
            contact: contactController.text,
            role: roleController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("User Information", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildTextField(nameController, "Full Name"),
              _buildTextField(userIdController, "User ID"),
              _buildTextField(emailController, "Email", keyboardType: TextInputType.emailAddress),
              _buildTextField(contactController, "Contact Number", keyboardType: TextInputType.phone),
              _buildTextField(roleController, "Role"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}

// ------------------ IMAGE TO TEXT PAGE ------------------
class TextExtractionWebPage extends StatefulWidget {
  final String Balaji, UID123, BalajiDavid@gmail.com, 9876543210, Doctor;

  const TextExtractionWebPage({
    super.key,
    required this.name,
    required this.userId,
    required this.email,
    required this.contact,
    required this.role,
  });

  @override
  State<TextExtractionWebPage> createState() => _TextExtractionWebPageState();
}

class _TextExtractionWebPageState extends State<TextExtractionWebPage> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndExtractText() async {
    final bytes = await ImagePickerWeb.getImageAsBytes();

    if (bytes != null) {
      setState(() {
        _imageBytes = bytes;
        _textController.clear();
        _isLoading = true;
      });

      final base64Image = base64Encode(bytes);
      final url = Uri.parse('https://api.ocr.space/parse/image');

      try {
        final response = await http.post(
          url,
          headers: {'apikey': 'helloworld'}, // Replace with real key
          body: {
            'base64Image': 'data:image/jpeg;base64,$base64Image',
            'language': 'eng',
            'isOverlayRequired': 'false',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final parsedResults = data['ParsedResults'];

          final extracted = parsedResults != null && parsedResults.isNotEmpty
              ? parsedResults[0]['ParsedText'] ?? 'No text found.'
              : 'No text found.';

          setState(() {
            _textController.text = extracted;
            _isLoading = false;
          });
        } else {
          setState(() {
            _textController.text = 'Failed to extract text. Status: ${response.statusCode}';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _textController.text = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePDF() async {
    final textToSave = _textController.text.trim();
    if (textToSave.isNotEmpty) {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Text(textToSave, style: const pw.TextStyle(fontSize: 16)),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Text Extractor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildUserInfoCard(),
            ElevatedButton.icon(
              onPressed: _pickImageAndExtractText,
              icon: const Icon(Icons.upload),
              label: const Text("Pick Image & Extract Text"),
            ),
            const SizedBox(height: 20),
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!, height: 200),
              ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepPurple.shade100),
                            ),
                            child: SingleChildScrollView(
                              child: TextField(
                                controller: _textController,
                                maxLines: null,
                                decoration: const InputDecoration.collapsed(
                                  hintText: 'Extracted text will appear here...',
                                ),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_textController.text.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: _generatePDF,
                            icon: const Icon(Icons.download),
                            label: const Text("Download PDF"),
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, ${widget.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("User ID: ${widget.userId}"),
            Text("Email: ${widget.email}"),
            Text("Contact: ${widget.contact}"),
            Text("Role: ${widget.role}"),
          ],
        ),
      ),
    );
  }
}
