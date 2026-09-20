from pathlib import Path

import numpy as np

HAND_FEATURE_SIZE = 21 * 3
POSE_FEATURE_SIZE = 33 * 4
POSE_START = HAND_FEATURE_SIZE * 2
LANDMARK_SIZE = POSE_START + POSE_FEATURE_SIZE


class VideoProcessingError(ValueError):
    """Raised when a video cannot be decoded or contains no usable frames."""


def _flatten_landmarks(hand_landmarks: object | None) -> list[float]:
    if hand_landmarks is None:
        return [0.0] * (21 * 3)
    return [coordinate for landmark in hand_landmarks.landmark for coordinate in (landmark.x, landmark.y, landmark.z)]


def _flatten_pose(pose_landmarks: object | None) -> list[float]:
    if pose_landmarks is None:
        return [0.0] * (33 * 4)
    return [
        coordinate
        for landmark in pose_landmarks.landmark
        for coordinate in (landmark.x, landmark.y, landmark.z, landmark.visibility)
    ]


def normalize_sequence(sequence: np.ndarray) -> np.ndarray:
    """Center landmarks on the torso and scale them by shoulder width."""
    if sequence.ndim != 2 or sequence.shape[1] != LANDMARK_SIZE:
        raise ValueError(f"Expected shape (frames, {LANDMARK_SIZE}), got {sequence.shape}")

    normalized = sequence.astype(np.float32, copy=True)
    pose = normalized[:, POSE_START:]
    left_shoulder = pose[:, 11 * 4 : 11 * 4 + 3]
    right_shoulder = pose[:, 12 * 4 : 12 * 4 + 3]
    center = (left_shoulder + right_shoulder) / 2.0
    width = np.linalg.norm(left_shoulder - right_shoulder, axis=1, keepdims=True)
    width[width < 1e-6] = 1.0

    for block_start in (0, HAND_FEATURE_SIZE, POSE_START):
        block_size = HAND_FEATURE_SIZE if block_start < POSE_START else POSE_FEATURE_SIZE
        block = normalized[:, block_start : block_start + block_size]
        dimensions = 3 if block_start < POSE_START else 4
        block[:, 0::dimensions] = (block[:, 0::dimensions] - center[:, 0:1]) / width
        block[:, 1::dimensions] = (block[:, 1::dimensions] - center[:, 1:2]) / width
        block[:, 2::dimensions] = (block[:, 2::dimensions] - center[:, 2:3]) / width

    return normalized


class LandmarkExtractor:
    def __init__(self) -> None:
        try:
            import cv2
            import mediapipe as mp
        except ImportError as error:
            raise RuntimeError("Install opencv-python and mediapipe to extract landmarks") from error
        self.cv2 = cv2
        self.mp = mp

    def extract(self, video_path: str | Path, max_seconds: float = 10.0) -> tuple[np.ndarray, float]:
        capture = self.cv2.VideoCapture(str(video_path))
        if not capture.isOpened():
            raise VideoProcessingError(f"Cannot open video: {video_path}")

        fps = capture.get(self.cv2.CAP_PROP_FPS) or 30.0
        max_frames = max(1, int(fps * max_seconds))
        frames: list[list[float]] = []

        try:
            with self.mp.solutions.holistic.Holistic(
                static_image_mode=False,
                model_complexity=1,
                enable_segmentation=False,
                refine_face_landmarks=False,
            ) as holistic:
                while len(frames) < max_frames:
                    ok, frame = capture.read()
                    if not ok:
                        break
                    rgb_frame = self.cv2.cvtColor(frame, self.cv2.COLOR_BGR2RGB)
                    result = holistic.process(rgb_frame)
                    frames.append(
                        _flatten_landmarks(result.left_hand_landmarks)
                        + _flatten_landmarks(result.right_hand_landmarks)
                        + _flatten_pose(result.pose_landmarks)
                    )
        finally:
            capture.release()

        if not frames:
            raise VideoProcessingError(f"Video contains no readable frames: {video_path}")
        sequence = normalize_sequence(np.asarray(frames, dtype=np.float32))
        return sequence, float(len(frames) / fps)

    def extract_rgb_frames(
        self, video_path: str | Path, max_seconds: float = 10.0, frame_count: int = 16
    ) -> tuple[list[np.ndarray], float]:
        capture = self.cv2.VideoCapture(str(video_path))
        if not capture.isOpened():
            raise VideoProcessingError(f"Cannot open video: {video_path}")

        fps = capture.get(self.cv2.CAP_PROP_FPS) or 30.0
        max_frames = max(1, int(fps * max_seconds))
        frames: list[np.ndarray] = []
        try:
            while len(frames) < max_frames:
                ok, frame = capture.read()
                if not ok:
                    break
                frames.append(self.cv2.cvtColor(frame, self.cv2.COLOR_BGR2RGB))
        finally:
            capture.release()

        if not frames:
            raise VideoProcessingError(f"Video contains no readable frames: {video_path}")
        indices = np.linspace(0, len(frames) - 1, frame_count).round().astype(int)
        return [frames[index] for index in indices], float(len(frames) / fps)
