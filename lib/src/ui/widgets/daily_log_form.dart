import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class DailyLogForm extends StatefulWidget {
  final VoidCallback onProductivePressed;
  final VoidCallback onUnproductivePressed;
  final TextEditingController noteController;

  const DailyLogForm({
    Key? key,
    required this.onProductivePressed,
    required this.onUnproductivePressed,
    required this.noteController,
  }) : super(key: key);

  @override
  _DailyLogFormState createState() => _DailyLogFormState();
}

class _DailyLogFormState extends State<DailyLogForm> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      setState(() {
        _speechInitialized = available;
      });
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _speechInitialized = false;
      });
    }
  }

  Future<void> _checkMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      // Request permission
      await Permission.microphone.request();
    }
  }

  void _toggleListening() async {
    try {
      await _checkMicrophonePermission();
      
      if (!_isListening) {
        if (!_speechInitialized) {
          bool available = await _speech.initialize(
            onError: (error) => print('Speech recognition error: $error'),
            onStatus: (status) => print('Speech recognition status: $status'),
          );
          if (!available) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech recognition not available')),
            );
            return;
          }
        }
        
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() => widget.noteController.text = result.recognizedWords);
          },
          cancelOnError: true,
        );
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } catch (e) {
      print('Error with speech recognition: $e');
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'How was this hour?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slide(begin: Offset(0, -0.1)),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'Log your productivity for the last hour',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),
                  
                  SizedBox(height: 24),
                  
                  TextField(
                    controller: widget.noteController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? colorScheme.primary : null,
                        ),
                        onPressed: _toggleListening,
                        tooltip: _isListening ? 'Stop listening' : 'Start voice input',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      hintText: 'What were you doing?',
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms),
                  
                  SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onProductivePressed();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.check_circle_outline),
                          label: Text('Productive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 300.ms)
                        .scale(begin: Offset(0.95, 0.95)),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onUnproductivePressed();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.cancel_outlined),
                          label: Text('Unproductive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 400.ms)
                        .scale(begin: Offset(0.95, 0.95)),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      if (_isListening) {
        _speech.stop();
      }
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
    super.dispose();
  }
} 