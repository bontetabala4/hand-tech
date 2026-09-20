import json
from pathlib import Path

from app.config import Settings
from app.model import Classifier, VideoMAEClassifier
from app.preprocessing import LANDMARK_SIZE, LandmarkExtractor
from app.schemas import GlossPrediction, RecognitionResponse


class RecognitionEngine:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.extractor = LandmarkExtractor()
        self.classifier: Classifier | VideoMAEClassifier | None = None
        if settings.videomae_model_path.is_dir():
            labels = json.loads(settings.labels_path.read_text(encoding="utf-8"))
            self.classifier = VideoMAEClassifier(settings.videomae_model_path, labels)
        elif settings.model_path.exists():
            labels = json.loads(settings.labels_path.read_text(encoding="utf-8"))
            self.classifier = Classifier(settings.model_path, labels, input_size=LANDMARK_SIZE)

    @property
    def is_ready(self) -> bool:
        return self.classifier is not None

    def recognize(self, video_path: str | Path) -> RecognitionResponse:
        if self.classifier is None:
            raise RuntimeError("No trained model is configured")
        if isinstance(self.classifier, VideoMAEClassifier):
            frames, duration = self.extractor.extract_rgb_frames(video_path, self.settings.max_video_seconds)
            label, confidence = self.classifier.predict_video(frames)
        else:
            sequence, duration = self.extractor.extract(video_path, self.settings.max_video_seconds)
            label, confidence = self.classifier.predict(sequence)
        if confidence < self.settings.confidence_threshold:
            label = "UNKNOWN"
        return RecognitionResponse(
            model_version=self.classifier.version,
            glosses=[GlossPrediction(label=label, confidence=confidence, start=0.0, end=duration)],
        )
