# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-25

### Added
- YOLOv8 Pose-based hand/wrist detection (CPU-optimized)
- FastAPI framework for REST API
- WebSocket support for real-time updates
- Google Gemini AI integration for waste classification
- Health check endpoint
- Statistics tracking
- QR code generation for classified items
- Docker support with docker-compose
- Comprehensive documentation

### Changed
- Replaced MediaPipe with YOLOv8 Pose for better CPU performance
- Updated to google-genai SDK v0.2.2
- Improved hand detection accuracy
- Optimized for CPU-only deployment

### Removed
- MediaPipe dependency (replaced with YOLO Pose)
- TensorFlow dependency (not needed)
- GPU requirements

### Fixed
- Hand detection confidence thresholds
- Memory optimization for model loading
- Error handling for API failures

## [1.0.0] - 2024-XX-XX

### Added
- Initial release
- Basic waste classification
- YOLO object detection
- MediaPipe hand detection

---

## Release Notes

### Version 2.0.0
This is a major release with significant improvements:
- **Performance**: CPU-optimized, no GPU required
- **Dependencies**: Reduced complexity by removing MediaPipe
- **Accuracy**: Improved hand detection with YOLO Pose
- **Deployment**: Docker-ready with comprehensive documentation

### Migration from 1.x to 2.0
- Update Python dependencies: `pip install -r requirements.txt`
- Download YOLO Pose model: `yolov8n-pose.pt`
- Update environment variables (check .env.example)
- No API changes - backward compatible endpoints
