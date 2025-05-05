import 'package:flutter/material.dart';
import 'package:innovator/screens/Feed/Update%20Feed/API_Service.dart';
import 'package:innovator/screens/Feed/Update%20Feed/Content_model.dart';


class ContentProvider extends ChangeNotifier {
  List<ContentModel> _contents = [];
  bool _isLoading = false;
  String _error = '';
  
  // Getters
  List<ContentModel> get contents => _contents;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // Update content status
  Future<bool> updateContentStatus(String id, String newStatus) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await ApiService.updateContent(id, newStatus);
      
      if (success) {
        // Update the local content list
        final index = _contents.indexWhere((content) => content.id == id);
        if (index != -1) {
          _contents[index].status = newStatus;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete files
  Future<bool> deleteFiles(List<String> filePaths) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await ApiService.deleteFiles(filePaths);
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}