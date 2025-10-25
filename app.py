#!/usr/bin/env python3
"""
Sortyx Cloud Backend - CPU Optimized Version
Hand detection using YOLOv8 Pose (NO MediaPipe - Pure CPU mode)
"""

import os
import sys

# ===== FORCE CPU-ONLY MODE =====
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

import io
import base64
import json
import time
import uuid
from datetime import datetime
from typing import Optional, List, Dict, Any
import logging
from pathlib import Path

# Web Framework
from fastapi import FastAPI, HTTPException, UploadFile, File, WebSocket, WebSocketDisconnect, BackgroundTasks
from fastapi.responses import HTMLResponse, JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi.templating import Jinja2Templates
from fastapi import Request

# AI/ML Libraries (CPU-optimized)
import cv2
import numpy as np
import torch

# ===== FIX FOR PYTORCH 2.6+ YOLO MODEL LOADING =====
# Allow YOLO model classes to be deserialized safely
try:
    from ultralytics.nn.modules import (
        Conv, C2f, SPPF, Detect, C2fAttn, ImagePoolingAttn,
        Bottleneck, C3, Concat, Upsample
    )
    from ultralytics.nn.tasks import DetectionModel, PoseModel, SegmentationModel
    
    # Add all necessary YOLO classes to safe globals
    torch.serialization.add_safe_globals([
        DetectionModel, PoseModel, SegmentationModel,
        Conv, C2f, SPPF, Detect, C2fAttn, ImagePoolingAttn,
        Bottleneck, C3, Concat, Upsample,
        torch.nn.modules.container.Sequential
    ])
    logger_init = logging.getLogger(__name__)
    logger_init.info("✅ PyTorch safe globals configured for YOLO model loading")
except ImportError as e:
    logger_init = logging.getLogger(__name__)
    logger_init.warning(f"⚠️ Could not import all YOLO modules for safe loading: {e}")
except Exception as e:
    logger_init = logging.getLogger(__name__)
    logger_init.warning(f"⚠️ Error configuring PyTorch safe globals: {e}")

from ultralytics import YOLO
from google import genai
from google.genai import types
from PIL import Image
import qrcode

# Environment and Configuration
from dotenv import load_dotenv
import uvicorn
from pydantic import BaseModel

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Sortyx Recyclable Waste Classification API",
    description="CPU-optimized waste classification system with YOLO-based hand detection",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files and templates
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# Pydantic models
class ClassificationRequest(BaseModel):
    image_base64: str
    bin_id: Optional[str] = None
    location: Optional[str] = "default"
    classification_method: Optional[str] = "model"

class ClassificationResponse(BaseModel):
    classification: str
    confidence: float
    item_name: str
    bin_color: str
    qr_code: Optional[str] = None
    explanation: str
    timestamp: str
    processing_time: float

class SensorData(BaseModel):
    sensor_id: str
    distance: float
    bin_level: float
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    location: str
    timestamp: str

class BinStatus(BaseModel):
    bin_id: str
    level: float
    status: str
    last_updated: str

# Global variables
yolo_detection_model = None
yolo_pose_model = None  # For hand/wrist detection
yolo_classification_model = None
connected_websockets: List[WebSocket] = []

# Waste categories
WASTE_CATEGORIES = {
    "Recyclable": {
        "color": "Green",
        "description": "Items that can be recycled: plastic bottles, metal cans, glass, paper, cardboard, electronics",
        "disposal_code": "REC"
    },
    "Non-Recyclable": {
        "color": "Black",
        "description": "Items that cannot be recycled: food waste, contaminated materials, styrofoam, ceramic",
        "disposal_code": "NR"
    }
}

class HandWristDetector:
    """
    CPU-optimized hand/wrist detection using YOLOv8 Pose estimation
    Replaces MediaPipe - works perfectly in CPU mode
    """
    
    def __init__(self):
        self.pose_model = None
        self.detection_model = None  # Fallback for person detection
        self.load_pose_model()
        
        # YOLO pose keypoint indices for hands/wrists
        self.LEFT_WRIST = 9
        self.RIGHT_WRIST = 10
        self.LEFT_ELBOW = 7
        self.RIGHT_ELBOW = 8
        self.LEFT_SHOULDER = 5
        self.RIGHT_SHOULDER = 6
    
    def load_pose_model(self):
        """Load YOLOv8 pose estimation model"""
        try:
            model_paths = [
                Path("models/yolov8n-pose.pt"),
                Path("/app/models/yolov8n-pose.pt"),
                Path("yolov8n-pose.pt")
            ]
            
            for path in model_paths:
                if path.exists():
                    self.pose_model = YOLO(str(path))
                    logger.info(f"✅ YOLOv8 Pose model loaded from {path}")
                    logger.info(f"   Model size: {path.stat().st_size / 1024 / 1024:.2f} MB")
                    
                    # Test the model with a dummy image to ensure it works
                    test_img = np.zeros((640, 640, 3), dtype=np.uint8)
                    test_result = self.pose_model(test_img, conf=0.1, verbose=False)
                    logger.info(f"   ✅ Model test successful")
                    return
            
            # Download if not found
            logger.info("📥 Downloading YOLOv8 Pose model...")
            self.pose_model = YOLO('yolov8n-pose.pt')
            
            # Save to models directory
            model_dir = Path("models")
            model_dir.mkdir(exist_ok=True)
            
            logger.info("✅ YOLOv8 Pose model downloaded and loaded")
            
        except Exception as e:
            logger.error(f"❌ Error loading pose model: {e}", exc_info=True)
            self.pose_model = None
    
    def detect_person_fallback(self, image: np.ndarray) -> Dict[str, Any]:
        """
        Fallback method: Use YOLO object detection to find person,
        then estimate hand region from upper body
        NOTE: This should ONLY be used as last resort and should indicate it's an estimate
        """
        if yolo_detection_model is None:
            return None
        
        try:
            h, w, _ = image.shape
            logger.info("🔄 Using fallback person detection...")
            
            # Detect person using YOLO object detection
            results = yolo_detection_model.predict(image, conf=0.15, verbose=False)
            
            for r in results:
                if hasattr(r, 'boxes') and r.boxes is not None:
                    for box in r.boxes:
                        class_id = int(box.cls[0])
                        class_name = r.names[class_id]
                        confidence = box.conf[0].item()
                        
                        if class_name.lower() == 'person':
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            logger.warning(f"⚠️ FALLBACK MODE: Person detected but NO WRIST KEYPOINTS (conf: {confidence:.2f})")
                            logger.warning(f"   📦 Person bbox: ({x1},{y1}) to ({x2},{y2})")
                            
                            # IMPORTANT: Return as NOT DETECTED since we don't have actual wrist data
                            # This forces the system to wait for proper wrist detection
                            logger.warning(f"   ❌ Cannot proceed without actual wrist detection - waiting for proper hand pose")
                            
                            return {
                                "hand_detected": False,
                                "wrist_detected": False,
                                "hand_bbox": None,
                                "wrist_position": None,
                                "confidence": 0.0,
                                "keypoints_count": 0,
                                "message": "Person detected but wrist keypoints not found. Please position hand clearly.",
                                "method": "fallback_failed"
                            }
            
            logger.warning("⚠️ Fallback: No person detected")
            return None
            
        except Exception as e:
            logger.error(f"❌ Fallback detection error: {e}")
            return None
    
    def detect_hand_wrist(self, image: np.ndarray) -> Dict[str, Any]:
        """
        Detect hand and wrist using YOLO Pose estimation
        Returns hand region and wrist keypoints
        """
        if self.pose_model is None:
            logger.warning("⚠️ Pose model not loaded!")
            # Try fallback method
            fallback_result = self.detect_person_fallback(image)
            if fallback_result:
                return fallback_result
            
            return {
                "hand_detected": False,
                "wrist_detected": False,
                "hand_bbox": None,
                "wrist_position": None,
                "confidence": 0.0,
                "keypoints_count": 0,
                "message": "Pose model not loaded and fallback failed"
            }
        
        try:
            h, w, _ = image.shape
            logger.info(f"📸 Processing image: {w}x{h} pixels")
            
            # Run pose detection with VERY LOW confidence threshold for better detection
            results = self.pose_model(image, conf=0.1, iou=0.5, verbose=False)  # Lowered from 0.2 to 0.1
            
            logger.info(f"🔍 Pose detection completed, checking for keypoints...")
            
            for r in results:
                if hasattr(r, 'keypoints') and r.keypoints is not None:
                    keypoints = r.keypoints.data
                    logger.info(f"📊 Found {len(keypoints)} person(s) in image")
                    
                    if len(keypoints) > 0:
                        # Get first person's keypoints
                        kpts = keypoints[0].cpu().numpy()
                        logger.info(f"👤 Person detected with {len(kpts)} keypoints")
                        
                        # Extract wrist and arm positions
                        left_wrist = kpts[self.LEFT_WRIST]
                        right_wrist = kpts[self.RIGHT_WRIST]
                        left_elbow = kpts[self.LEFT_ELBOW]
                        right_elbow = kpts[self.RIGHT_ELBOW]
                        left_shoulder = kpts[self.LEFT_SHOULDER]
                        right_shoulder = kpts[self.RIGHT_SHOULDER]
                        
                        logger.info(f"🔹 Left wrist confidence: {left_wrist[2]:.3f}")
                        logger.info(f"🔹 Right wrist confidence: {right_wrist[2]:.3f}")
                        logger.info(f"🔹 Left elbow confidence: {left_elbow[2]:.3f}")
                        logger.info(f"🔹 Right elbow confidence: {right_elbow[2]:.3f}")
                        
                        # Check which wrist has higher confidence
                        wrist_detected = False
                        wrist_position = None
                        hand_bbox = None
                        hand_confidence = 0.0
                        
                        # STRICT WRIST DETECTION: Require minimum confidence of 0.3 (increased from 0.15)
                        # This ensures we have actual wrist keypoints, not just person detection
                        WRIST_CONFIDENCE_THRESHOLD = 0.30
                        
                        if left_wrist[2] > WRIST_CONFIDENCE_THRESHOLD or right_wrist[2] > WRIST_CONFIDENCE_THRESHOLD:
                            if left_wrist[2] > right_wrist[2]:
                                # Use left hand
                                wrist_x, wrist_y, wrist_conf = left_wrist
                                elbow_x, elbow_y, elbow_conf = left_elbow
                                shoulder_x, shoulder_y, _ = left_shoulder
                                logger.info(f"✋ Using LEFT hand (wrist conf: {wrist_conf:.3f}, elbow conf: {elbow_conf:.3f})")
                            else:
                                # Use right hand
                                wrist_x, wrist_y, wrist_conf = right_wrist
                                elbow_x, elbow_y, elbow_conf = right_elbow
                                shoulder_x, shoulder_y, _ = right_shoulder
                                logger.info(f"✋ Using RIGHT hand (wrist conf: {wrist_conf:.3f}, elbow conf: {elbow_conf:.3f})")
                            
                            wrist_detected = True
                            hand_confidence = float(wrist_conf)
                            
                            # Convert to pixel coordinates
                            wrist_x = int(wrist_x)
                            wrist_y = int(wrist_y)
                            elbow_x = int(elbow_x)
                            elbow_y = int(elbow_y)
                            
                            wrist_position = {"x": wrist_x, "y": wrist_y}
                            
                            # Calculate hand region
                            # If elbow confidence is low, use shoulder instead
                            if elbow_conf < 0.2:
                                logger.info(f"⚠️ Low elbow confidence, using shoulder for direction")
                                dx = wrist_x - int(shoulder_x)
                                dy = wrist_y - int(shoulder_y)
                            else:
                                dx = wrist_x - elbow_x
                                dy = wrist_y - elbow_y
                            
                            # Extend beyond wrist to capture hand
                            hand_center_x = int(wrist_x + dx * 0.35)  # Slightly more extension
                            hand_center_y = int(wrist_y + dy * 0.35)
                            
                            # Create bounding box around hand (LARGER for better detection)
                            box_size = 250  # Increased from 200 pixels
                            hand_x_min = max(0, hand_center_x - box_size)
                            hand_y_min = max(0, hand_center_y - box_size)
                            hand_x_max = min(w, hand_center_x + box_size)
                            hand_y_max = min(h, hand_center_y + box_size)
                            
                            hand_bbox = {
                                "x_min": hand_x_min,
                                "y_min": hand_y_min,
                                "x_max": hand_x_max,
                                "y_max": hand_y_max
                            }
                            
                            logger.info(f"✅ Hand/Wrist detected successfully!")
                            logger.info(f"   📍 Wrist position: ({wrist_x}, {wrist_y})")
                            logger.info(f"   📦 Hand bbox: ({hand_x_min},{hand_y_min}) to ({hand_x_max},{hand_y_max})")
                            logger.info(f"   📏 Hand region size: {hand_x_max-hand_x_min}x{hand_y_max-hand_y_min}")
                            logger.info(f"   🎯 Confidence: {hand_confidence:.2f}")
                            
                            return {
                                "hand_detected": True,
                                "wrist_detected": wrist_detected,
                                "hand_bbox": hand_bbox,
                                "wrist_position": wrist_position,
                                "confidence": hand_confidence,
                                "keypoints_count": len(kpts),
                                "message": "Hand and wrist detected successfully",
                                "method": "pose"
                            }
                        else:
                            logger.warning(f"⚠️ Wrist confidence too low (L:{left_wrist[2]:.3f}, R:{right_wrist[2]:.3f})")
                            logger.info("🔄 Trying fallback detection method...")
                    else:
                        logger.warning("⚠️ No keypoints found in detection")
                else:
                    logger.warning("⚠️ No keypoints attribute in results")
            
            # If pose detection failed, try fallback method
            logger.info("🔄 Pose detection failed, attempting fallback...")
            fallback_result = self.detect_person_fallback(image)
            if fallback_result:
                return fallback_result
            
            logger.info("❌ No person or hands detected in image (both methods failed)")
            return {
                "hand_detected": False,
                "wrist_detected": False,
                "hand_bbox": None,
                "wrist_position": None,
                "confidence": 0.0,
                "keypoints_count": 0,
                "message": "No person or hands detected"
            }
            
        except Exception as e:
            logger.error(f"❌ Hand detection error: {e}", exc_info=True)
            
            # Try fallback on error
            try:
                fallback_result = self.detect_person_fallback(image)
                if (fallback_result):
                    return fallback_result
            except:
                pass
            
            return {
                "hand_detected": False,
                "wrist_detected": False,
                "hand_bbox": None,
                "wrist_position": None,
                "confidence": 0.0,
                "keypoints_count": 0,
                "message": f"Error: {str(e)}"
            }

class RecyclableWasteClassifier:
    """Enhanced recyclable waste classification system"""
    
    def __init__(self):
        self.hand_detector = HandWristDetector()
        self.load_models()
        self.configure_gemini()
        self.stats = {
            'total_classifications': 0,
            'category_counts': {category: 0 for category in WASTE_CATEGORIES.keys()},
            'daily_stats': {},
            'model_classifications': 0,
            'llm_classifications': 0
        }
    
    def load_models(self):
        """Load YOLO models"""
        try:
            global yolo_detection_model, yolo_classification_model
            
            model_dir = Path("models")
            model_dir.mkdir(exist_ok=True)
            
            # Load detection model
            detection_paths = [
                model_dir / "yolov8n.pt",
                Path("/app/models/yolov8n.pt"),
                Path("yolov8n.pt")
            ]
            
            for path in detection_paths:
                if path.exists():
                    yolo_detection_model = YOLO(str(path))
                    logger.info(f"✅ YOLO detection model loaded from {path}")
                    break
            else:
                logger.info("📥 Downloading YOLOv8n detection model...")
                yolo_detection_model = YOLO('yolov8n.pt')
                logger.info("✅ YOLOv8n detection model downloaded")
            
            # Load classification model
            classification_paths = [
                Path("/app/models/best.pt"),
                Path("models/best.pt"),
                Path("best.pt")
            ]
            
            for path in classification_paths:
                if path.exists():
                    yolo_classification_model = YOLO(str(path))
                    logger.info(f"✅ Classification model loaded from {path}")
                    break
            else:
                logger.warning("⚠️ Classification model not found - will use LLM only")
                
        except Exception as e:
            logger.error(f"Error loading models: {e}")
    
    def configure_gemini(self):
        """Configure Gemini API with new google-genai SDK"""
        try:
            api_key = os.getenv('GEMINI_API_KEY')
            if (api_key):
                # Initialize the client with API key
                self.genai_client = genai.Client(api_key=api_key)
                logger.info("✅ Gemini API configured with google-genai SDK")

                # Test the API with a simple call to verify it works
                try:
                    # Try to list models to verify connection
                    logger.info("✅ Gemini client initialized successfully")
                except Exception as test_error:
                    logger.warning(f"⚠️ Could not verify Gemini connection: {test_error}")
            else:
                logger.warning("⚠️ GEMINI_API_KEY not found")
                self.genai_client = None
        except Exception as e:
            logger.error(f"Error configuring Gemini: {e}")
            self.genai_client = None
    
    def classify_with_yolo_model(self, image: np.ndarray) -> Dict[str, Any]:
        """Classify waste using YOLO model"""
        if yolo_classification_model is None:
            return self.classify_with_gemini(image)
        
        try:
            results = yolo_classification_model(image, verbose=False)
            
            if results and hasattr(results[0], 'probs') and results[0].probs is not None:
                top_class = results[0].probs.top1
                confidence = results[0].probs.top1conf.item()
                class_name = results[0].names[top_class]
                
                classification = self.map_class_to_category(class_name, confidence)
                
                return {
                    "classification": classification["category"],
                    "item_name": class_name.title(),
                    "explanation": f"AI model: {confidence*100:.1f}% confidence. {classification['reason']}",
                    "bin_color": WASTE_CATEGORIES[classification["category"]]["color"],
                    "disposal_code": WASTE_CATEGORIES[classification["category"]]["disposal_code"],
                    "confidence": confidence,
                    "method": "yolo_model"
                }
            else:
                return self.classify_with_gemini(image)
                
        except Exception as e:
            logger.error(f"YOLO classification error: {e}")
            return self.classify_with_gemini(image)
    
    def map_class_to_category(self, class_name: str, confidence: float) -> Dict[str, Any]:
        """Map class to recyclable/non-recyclable"""
        class_lower = class_name.lower()
        
        recyclable = ['plastic', 'bottle', 'can', 'metal', 'aluminum', 'glass', 
                     'paper', 'cardboard', 'box', 'container', 'jar', 'tin']
        non_recyclable = ['food', 'organic', 'waste', 'styrofoam', 'ceramic', 'fabric']
        
        if any(k in class_lower for k in recyclable):
            return {"category": "Recyclable", "reason": "This item can be recycled."}
        elif any(k in class_lower for k in non_recyclable):
            return {"category": "Non-Recyclable", "reason": "This item cannot be recycled."}
        else:
            return {
                "category": "Recyclable" if confidence > 0.7 else "Non-Recyclable",
                "reason": "Classification based on AI analysis."
            }
    
    def classify_with_gemini(self, image: np.ndarray) -> Dict[str, Any]:
        """Classify using Gemini AI with new google-genai SDK"""
        if not hasattr(self, 'genai_client') or self.genai_client is None:
            logger.error("❌ Gemini client not initialized")
            return self.get_fallback_classification()
        
        try:
            # Convert numpy array to PIL Image
            pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))

            
            
            # Save PIL image to bytes for upload
            img_byte_arr = io.BytesIO()
            pil_image.save(img_byte_arr, format='JPEG')
            img_byte_arr.seek(0)
            
            prompt = """Classify this item as RECYCLABLE or NON-RECYCLABLE.

RECYCLABLE: plastic bottles, metal cans, glass, paper, cardboard, clean containers
NON-RECYCLABLE: food waste, styrofoam, contaminated materials, ceramics

Format: "Category: Item Name. Explanation"
Example: "Recyclable: Plastic Bottle. Clean plastic can be recycled."
"""
            
            # Try different Gemini models with new SDK
            model_names = ['gemini-2.0-flash-exp', 'gemini-2.5-flash', 'gemini-2.5-pro']
            
            for model_name in model_names:
                try:
                    logger.info(f"🧠 Attempting Gemini classification with model: {model_name}")
                    
                    # Upload the image file using new SDK
                    uploaded_file = self.genai_client.files.upload(
                        file=img_byte_arr,
                        config=types.UploadFileConfig(
                            mime_type='image/jpeg',
                            display_name='waste_item.jpg'
                        )
                    )
                    
                    # Generate content using the new SDK with proper Part construction
                    response = self.genai_client.models.generate_content(
                        model=model_name,
                        contents=[
                            prompt,
                            uploaded_file
                        ],
                        config=types.GenerateContentConfig(
                            temperature=0.4,
                            top_p=0.95,
                            top_k=40,
                            max_output_tokens=1024
                        )
                    )
                    
                    # Delete the uploaded file after use
                    try:
                        self.genai_client.files.delete(name=uploaded_file.name)
                    except:
                        pass
                    
                    if response and response.text:
                        logger.info(f"✅ Gemini classification successful with {model_name}")
                        return self.parse_gemini_response(response.text)
                        
                except Exception as model_error:
                    logger.warning(f"⚠️ Model {model_name} failed: {str(model_error)}")
                    # Try to clean up uploaded file if it exists
                    try:
                        if 'uploaded_file' in locals():
                            self.genai_client.files.delete(name=uploaded_file.name)
                    except:
                        pass
                    continue
            
            # If all models fail, use fallback
            logger.error("❌ All Gemini models failed")
            return self.get_fallback_classification()
                
        except Exception as e:
            logger.error(f"Gemini error: {e}")
            return self.get_fallback_classification()
    
    def parse_gemini_response(self, text: str) -> Dict[str, Any]:
        """Parse Gemini response"""
        text_lower = text.lower()
        classification = "Non-Recyclable"
        item_name = "Unknown Item"
        
        if "recyclable" in text_lower and "non-recyclable" not in text_lower:
            classification = "Recyclable"
        
        if ":" in text:
            try:
                parts = text.split(":", 1)
                if len(parts) > 1:
                    item_info = parts[1].strip()
                    end = item_info.find(".")
                    if end != -1:
                        item_name = item_info[:end].strip()
            except:
                pass
        
        category_info = WASTE_CATEGORIES[classification]
        return {
            "classification": classification,
            "item_name": item_name,
            "explanation": text,
            "bin_color": category_info["color"],
            "disposal_code": category_info["disposal_code"],
            "confidence": 0.85,
            "method": "llm"
        }
    
    def get_fallback_classification(self) -> Dict[str, Any]:
        """Fallback classification"""
        return {
            "classification": "Non-Recyclable",
            "item_name": "Unknown Item",
            "explanation": "Could not classify - defaulting to non-recyclable for safety.",
            "bin_color": "Black",
            "disposal_code": "NR",
            "confidence": 0.50,
            "method": "fallback"
        }
    
    def generate_qr_code(self, classification_data: Dict[str, Any]) -> str:
        """Generate QR code"""
        try:
            qr_data = {
                "id": str(uuid.uuid4()),
                "classification": classification_data["classification"],
                "item": classification_data["item_name"],
                "timestamp": datetime.now().isoformat()
            }
            
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(json.dumps(qr_data))
            qr.make(fit=True)
            
            qr_image = qr.make_image(fill_color="black", back_color="white")
            buffer = io.BytesIO()
            qr_image.save(buffer, format="PNG")
            qr_base64 = base64.b64encode(buffer.getvalue()).decode()
            
            return f"data:image/png;base64,{qr_base64}"
        except Exception as e:
            logger.error(f"QR code error: {e}")
            return None

# Initialize classifier
classifier = RecyclableWasteClassifier()

# API Routes
@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    """Serve main interface"""
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/health")
async def health_check():
    """Health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "models_loaded": {
            "yolo_detection": yolo_detection_model is not None,
            "yolo_pose": classifier.hand_detector.pose_model is not None,
            "yolo_classification": yolo_classification_model is not None,
            "gemini_configured": bool(os.getenv('GEMINI_API_KEY'))
        },
        "hand_detection": "YOLOv8 Pose (CPU-optimized, no MediaPipe)"
    }

@app.post("/detect-hand-wrist")
async def detect_hand_wrist(request: ClassificationRequest):
    """
    Detect hand and wrist using YOLOv8 Pose estimation
    CPU-optimized - no GPU or MediaPipe required
    """
    try:
        # Decode image
        image_data = base64.b64decode(
            request.image_base64.split(',')[1] if ',' in request.image_base64 else request.image_base64
        )
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            return {
                "hand_detected": False,
                "wrist_detected": False,
                "object_in_hand": False,
                "message": "Invalid image"
            }
        
        h, w, _ = image.shape
        
        # Detect hand and wrist using YOLO Pose
        hand_result = classifier.hand_detector.detect_hand_wrist(image)
        
        if not hand_result["hand_detected"] or not hand_result["wrist_detected"]:
            return {
                **hand_result,
                "object_in_hand": False,
                "cropped_image": None,
                "object_bbox": None,
                "detected_objects": []
            }
        
        hand_bbox = hand_result["hand_bbox"]
        
        # Detect objects in hand region using YOLO
        if yolo_detection_model is None:
            return {**hand_result, "object_in_hand": False, "message": "Detection model not loaded"}
        
        results = yolo_detection_model.predict(image, conf=0.3, iou=0.45, verbose=False)
        
        object_in_hand = False
        object_bbox = None
        cropped_image = None
        max_confidence = 0.0
        detected_objects = []
        
        for r in results:
            if hasattr(r, 'boxes') and r.boxes is not None:
                for box in r.boxes:
                    class_id = int(box.cls[0])
                    class_name = r.names[class_id]
                    confidence = box.conf[0].item()
                    
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    center_x = (x1 + x2) // 2
                    center_y = (y1 + y2) // 2
                    
                    detected_objects.append({
                        "class": class_name,
                        "confidence": confidence,
                        "bbox": [x1, y1, x2, y2]
                    })
                    
                    # Skip person class
                    if class_name.lower() == 'person':
                        continue
                    
                    # Check if object is in hand region
                    if (hand_bbox['x_min'] <= center_x <= hand_bbox['x_max'] and
                        hand_bbox['y_min'] <= center_y <= hand_bbox['y_max']):
                        
                        object_in_hand = True
                        object_bbox = {
                            "x_min": x1, "y_min": y1,
                            "x_max": x2, "y_max": y2,
                            "class": class_name,
                            "confidence": confidence
                        }
                        max_confidence = max(max_confidence, confidence)
                        
                        # Crop object region
                        crop_x1 = max(0, x1 - 20)
                        crop_y1 = max(0, y1 - 20)
                        crop_x2 = min(w, x2 + 20)
                        crop_y2 = min(h, y2 + 20)
                        
                        cropped = image[crop_y1:crop_y2, crop_x1:crop_x2]
                        
                        if cropped.size > 0:
                            _, buffer = cv2.imencode('.jpg', cropped)
                            cropped_base64 = base64.b64encode(buffer).decode('utf-8')
                            cropped_image = f"data:image/jpeg;base64,{cropped_base64}"
                        
                        logger.info(f"🎯 Object '{class_name}' in hand - {confidence:.2f} confidence")
                        break
                
                if object_in_hand:
                    break
        
        return {
            **hand_result,
            "object_in_hand": object_in_hand,
            "cropped_image": cropped_image,
            "object_bbox": object_bbox,
            "detected_objects": detected_objects,
            "confidence": float(max_confidence) if object_in_hand else hand_result["confidence"],
            "message": "Hand, wrist, and object detected" if object_in_hand else "Hand/wrist detected, waiting for object"
        }
        
    except Exception as e:
        logger.error(f"Detection error: {e}", exc_info=True)
        return {
            "hand_detected": False,
            "wrist_detected": False,
            "object_in_hand": False,
            "message": f"Error: {str(e)}"
        }

# Add alias endpoint for backward compatibility
@app.post("/detect-hand")
async def detect_hand(request: ClassificationRequest):
    """
    Alias for /detect-hand-wrist endpoint
    Detects hand using YOLOv8 Pose estimation
    """
    return await detect_hand_wrist(request)

@app.post("/classify", response_model=ClassificationResponse)
async def classify_waste(request: ClassificationRequest, background_tasks: BackgroundTasks):
    """Classify waste item"""
    start_time = time.time()
    
    try:
        image_data = base64.b64decode(
            request.image_base64.split(',')[1] if ',' in request.image_base64 else request.image_base64
        )
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image")
        
        method = (request.classification_method or "model").lower()
        
        if method == "model":
            result = classifier.classify_with_yolo_model(image)
            classifier.stats['model_classifications'] += 1
        else:
            result = classifier.classify_with_gemini(image)
            classifier.stats['llm_classifications'] += 1
        
        qr_code = classifier.generate_qr_code(result)
        
        classifier.stats['total_classifications'] += 1
        classifier.stats['category_counts'][result['classification']] += 1
        
        processing_time = time.time() - start_time
        
        if connected_websockets:
            background_tasks.add_task(notify_websocket_clients, {
                "type": "classification_complete",
                "data": result
            })
        
        return ClassificationResponse(
            classification=result["classification"],
            confidence=result["confidence"],
            item_name=result["item_name"],
            bin_color=result["bin_color"],
            qr_code=qr_code,
            explanation=result["explanation"],
            timestamp=datetime.now().isoformat(),
            processing_time=processing_time
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Classification error: {e}", exc_info=True)
        fallback = classifier.get_fallback_classification()
        return ClassificationResponse(
            classification=fallback["classification"],
            confidence=fallback["confidence"],
            item_name=fallback["item_name"],
            bin_color=fallback["bin_color"],
            qr_code=None,
            explanation=f"Error: {str(e)}. Using fallback.",
            timestamp=datetime.now().isoformat(),
            processing_time=time.time() - start_time
        )

@app.get("/bins/status")
async def get_bin_status():
    """Get bin status"""
    bins = [
        {"bin_id": "recyclable_bin", "level": 45, "status": "normal", "last_updated": datetime.now().isoformat()},
        {"bin_id": "non_recyclable_bin", "level": 68, "status": "warning", "last_updated": datetime.now().isoformat()}
    ]
    return {"bins": bins, "timestamp": datetime.now().isoformat()}

@app.get("/stats")
async def get_statistics():
    """Get statistics"""
    return {
        "total_classifications": classifier.stats['total_classifications'],
        "category_breakdown": classifier.stats['category_counts'],
        "model_classifications": classifier.stats['model_classifications'],
        "llm_classifications": classifier.stats['llm_classifications'],
        "timestamp": datetime.now().isoformat()
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint"""
    await websocket.accept()
    connected_websockets.append(websocket)
    logger.info("WebSocket connected")
    
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        connected_websockets.remove(websocket)
        logger.info("WebSocket disconnected")

async def notify_websocket_clients(message: Dict[str, Any]):
    """Notify WebSocket clients"""
    if not connected_websockets:
        return
    for ws in connected_websockets.copy():
        try:
            await ws.send_json(message)
        except:
            connected_websockets.remove(ws)

if __name__ == "__main__":
    Path("models").mkdir(exist_ok=True)
    Path("static").mkdir(exist_ok=True)
    Path("templates").mkdir(exist_ok=True)
    
    logger.info("🚀 Starting Sortyx Cloud Backend (CPU-optimized, no MediaPipe)")
    logger.info("✅ Hand detection: YOLOv8 Pose estimation")
    
    # Use PORT from environment for Render compatibility
    port = int(os.getenv("PORT", 8000))
    
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=port,
        reload=False,  # Disable reload in production
        log_level="info"
    )