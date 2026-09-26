import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/app_snackbar.dart';
import '../../models/user_session.dart';
import '../../routes/app_routes.dart';
import '../../services/google_sheets_service.dart';
import '../../widgets/custom_button.dart';

/// Resume Screen for picking, validating, chunked uploading, and opening PDF resumes.
class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final _apiService = GoogleSheetsService();

  // State Variables
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _currentChunkIndex = 0;
  int _totalChunks = 0;
  String? _statusMessage;
  String? _errorMessage;
  String? _uploadedDriveUrl;
  String? _uploadedFileName;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  Future<void> _pickResumeFile() async {
    if (_isUploading) return;
    setState(() {
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // Selection cancelled
      }

      if (!mounted) return;

      final file = result.files.first;

      // 1. File Extension Validation
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        AppSnackBar.show(
          context,
          message: AppStrings.errInvalidFileType,
          isError: true,
        );
        return;
      }

      // 2. File Size Validation
      if (file.size > _maxFileSizeBytes) {
        AppSnackBar.show(
          context,
          message: AppStrings.errFileTooLarge,
          isError: true,
        );
        return;
      }

      // Extract file bytes safely
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          bytes = await ioFile.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: 'Unable to read selected PDF file.',
          isError: true,
        );
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileBytes = bytes;
        _uploadedDriveUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: AppStrings.errFilePickerFailed,
        isError: true,
      );
    }
  }

  Future<void> _uploadResume() async {
    if (_isUploading) return;
    final String? userId = UserSession().userId;
    if (userId == null || userId.isEmpty) {
      AppSnackBar.show(
        context,
        message: AppStrings.errSessionRequired,
        isError: true,
      );
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    if (_selectedFile == null || _fileBytes == null) {
      AppSnackBar.show(
        context,
        message: 'Please select a resume PDF file first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
      _statusMessage = 'Preparing resume file for upload...';
    });

    final String fileName = _selectedFile!.name;
    final Uint8List bytes = _fileBytes!;
    final int totalBytes = bytes.length;
    final int chunkSize = GoogleSheetsService.resumeChunkSizeBytes;
    final int totalChunks = (totalBytes / chunkSize).ceil();
    final String uploadId =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';

    setState(() {
      _totalChunks = totalChunks;
      _currentChunkIndex = 0;
    });

    // 1. Upload Chunks Sequentially (1-based indexing for Apps Script)
    for (int chunkIndex = 1; chunkIndex <= totalChunks; chunkIndex++) {
      if (!mounted) return;

      final int start = (chunkIndex - 1) * chunkSize;
      final int end = min(start + chunkSize, totalBytes);
      final Uint8List chunkBytes = bytes.sublist(start, end);

      // Web-safe Base64 encoding compatible with Apps Script Utilities.base64DecodeWebSafe()
      final String encodedChunk = base64UrlEncode(chunkBytes);

      setState(() {
        _currentChunkIndex = chunkIndex;
        _statusMessage = 'Uploading chunk $chunkIndex of $totalChunks...';
      });

      final response = await _apiService.uploadResumeChunk(
        uploadId: uploadId,
        userId: userId,
        chunkIndex: chunkIndex,
        totalChunks: totalChunks,
        fileName: fileName,
        chunk: encodedChunk,
      );

      if (response['success'] != true) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _errorMessage = response['message']?.toString() ??
              'Failed to upload chunk $chunkIndex of $totalChunks.';
        });
        AppSnackBar.show(
          context,
          message: _errorMessage!,
          isError: true,
        );
        return; // HALT upload immediately on failure
      }

      setState(() {
        _uploadProgress = chunkIndex / totalChunks;
      });
    }

    // 2. Finalize Upload
    setState(() {
      _statusMessage = 'Finalizing resume upload with Google Drive...';
    });

    final finishResponse = await _apiService.finishResumeUpload(
      uploadId: uploadId,
      userId: userId,
      fileName: fileName,
      totalChunks: totalChunks,
    );

    if (!mounted) return;

    if (finishResponse['success'] == true) {
      final String? driveUrl = finishResponse['driveUrl']?.toString();
      setState(() {
        _isUploading = false;
        _statusMessage = null;
        _uploadedDriveUrl = driveUrl;
        _uploadedFileName = fileName;
      });

      AppSnackBar.show(
        context,
        message: AppStrings.resumeUploadSuccess,
      );
    } else {
      setState(() {
        _isUploading = false;
        _errorMessage = finishResponse['message']?.toString() ??
            'Failed to finalize resume upload.';
      });

      AppSnackBar.show(
        context,
        message: _errorMessage!,
        isError: true,
      );
    }
  }

  Future<void> _openDriveUrl() async {
    if (_uploadedDriveUrl != null && _uploadedDriveUrl!.isNotEmpty) {
      final Uri uri = Uri.parse(_uploadedDriveUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: 'Unable to open Google Drive link.',
          isError: true,
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.resumeTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.article_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                AppStrings.resumeTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                AppStrings.resumeSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upload States Body
                  if (_uploadedDriveUrl != null) ...[
                    // Success State Card
                    _buildSuccessCard(),
                  ] else if (_isUploading) ...[
                    // Uploading State Progress Card
                    _buildProgressCard(),
                  ] else if (_selectedFile != null) ...[
                    // Selected File Preview Card
                    _buildSelectedFileCard(),
                  ] else ...[
                    // Empty State Card
                    _buildEmptyStateCard(),
                  ],

                  if (_errorMessage != null && !_isUploading) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            AppStrings.noResumeUploaded,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a PDF file (Max 5 MB) from your device.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: AppStrings.selectResume,
            icon: Icons.attach_file_rounded,
            width: 220,
            onPressed: _pickResumeFile,
          ),
        ],
      ),
    );
  }


  Widget _buildSelectedFileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${_formatFileSize(_selectedFile!.size)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: _errorMessage != null
                ? AppStrings.retryUpload
                : AppStrings.uploadResume,
            icon: Icons.cloud_upload_rounded,
            onPressed: _uploadResume,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: AppStrings.changeFile,
            icon: Icons.folder_open_rounded,
            isOutlined: true,
            onPressed: _pickResumeFile,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final int progressPercent = (_uploadProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _statusMessage ?? 'Uploading...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chunk $_currentChunkIndex of $_totalChunks',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.resumeUploadSuccess,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _uploadedFileName ?? 'resume.pdf',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: AppStrings.openInDrive,
            icon: Icons.open_in_new_rounded,
            onPressed: _openDriveUrl,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Upload New Version',
            icon: Icons.upload_file_rounded,
            isOutlined: true,
            onPressed: _pickResumeFile,
          ),
        ],
      ),
    );
  }
}

