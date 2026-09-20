from pathlib import Path

import numpy as np

try:
    import torch
    from torch import nn
except ImportError:  # pragma: no cover - gives a useful error at runtime
    torch = None
    nn = None


class ModelUnavailableError(RuntimeError):
    """Raised when inference is requested without a trained model."""


if nn is not None:
    class TemporalClassifier(nn.Module):
        def __init__(self, input_size: int, class_count: int, hidden_size: int = 128) -> None:
            super().__init__()
            self.encoder = nn.LSTM(input_size, hidden_size, batch_first=True, bidirectional=True)
            self.classifier = nn.Sequential(
                nn.LayerNorm(hidden_size * 2),
                nn.Linear(hidden_size * 2, class_count),
            )

        def forward(self, sequence: torch.Tensor) -> torch.Tensor:
            encoded, _ = self.encoder(sequence)
            pooled = encoded.mean(dim=1)
            return self.classifier(pooled)
else:
    class TemporalClassifier:  # type: ignore[no-redef]
        def __init__(self, *args: object, **kwargs: object) -> None:
            raise ModelUnavailableError("Install torch to use the temporal classifier")


class Classifier:
    def __init__(self, checkpoint_path: Path, labels: list[str], input_size: int) -> None:
        if torch is None:
            raise ModelUnavailableError("Install torch to run inference")
        if not checkpoint_path.exists():
            raise ModelUnavailableError(f"Model checkpoint not found: {checkpoint_path}")

        checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=True)
        self.model = TemporalClassifier(input_size, len(labels))
        self.model.load_state_dict(checkpoint["state_dict"])
        self.model.eval()
        self.labels = labels
        self.version = str(checkpoint.get("version", checkpoint_path.stem))

    def predict(self, sequence: np.ndarray) -> tuple[str, float]:
        if sequence.ndim != 2:
            raise ValueError(f"Expected sequence with two dimensions, got {sequence.shape}")
        tensor = torch.from_numpy(sequence).float().unsqueeze(0)
        with torch.inference_mode():
            probabilities = torch.softmax(self.model(tensor), dim=1)[0]
        index = int(torch.argmax(probabilities).item())
        return self.labels[index], float(probabilities[index].item())


class VideoMAEClassifier:
    def __init__(self, checkpoint_path: Path, labels: list[str]) -> None:
        if torch is None:
            raise ModelUnavailableError("Install torch to run inference")
        if not checkpoint_path.is_dir():
            raise ModelUnavailableError(f"VideoMAE checkpoint not found: {checkpoint_path}")
        try:
            from transformers import VideoMAEForVideoClassification, VideoMAEImageProcessor
        except ImportError as error:
            raise ModelUnavailableError("Install transformers to use VideoMAE") from error

        self.processor = VideoMAEImageProcessor.from_pretrained(checkpoint_path)
        self.model = VideoMAEForVideoClassification.from_pretrained(checkpoint_path)
        self.model.eval()
        self.labels = labels
        self.version = str(self.model.config.name_or_path or checkpoint_path.name)

    def predict_video(self, frames: list[np.ndarray]) -> tuple[str, float]:
        if not frames:
            raise ValueError("Video contains no readable frames")
        inputs = self.processor(frames, return_tensors="pt")
        with torch.inference_mode():
            probabilities = torch.softmax(self.model(**inputs).logits, dim=1)[0]
        index = int(torch.argmax(probabilities).item())
        return self.labels[index], float(probabilities[index].item())
