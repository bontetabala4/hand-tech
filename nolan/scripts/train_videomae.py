"""Fine-tune a VideoMAE classifier on isolated videos under data/raw/LABEL."""
import json
import random
from pathlib import Path

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader, Dataset
from transformers import VideoMAEForVideoClassification, VideoMAEImageProcessor


MODEL_NAME = "MCG-NJU/videomae-base"
SEED = 42
FRAME_COUNT = 16
VIDEO_EXTENSIONS = {".mp4", ".webm", ".avi", ".mov", ".mkv"}


class VideoDataset(Dataset[tuple[list[np.ndarray], int]]):
    def __init__(self, samples: list[tuple[Path, int]], max_seconds: float = 15.0) -> None:
        self.samples = samples
        self.max_seconds = max_seconds

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, index: int) -> tuple[list[np.ndarray], int]:
        import cv2

        video_path, label = self.samples[index]
        capture = cv2.VideoCapture(str(video_path))
        if not capture.isOpened():
            raise ValueError(f"Cannot open video: {video_path}")
        fps = capture.get(cv2.CAP_PROP_FPS) or 30.0
        frames: list[np.ndarray] = []
        try:
            while len(frames) < max(1, int(fps * self.max_seconds)):
                ok, frame = capture.read()
                if not ok:
                    break
                frames.append(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        finally:
            capture.release()
        if not frames:
            raise ValueError(f"Video contains no readable frames: {video_path}")
        indices = np.linspace(0, len(frames) - 1, FRAME_COUNT).round().astype(int)
        return [frames[index] for index in indices], label


def collect_samples(root: Path, labels: list[str]) -> list[tuple[Path, int]]:
    samples = [
        (video_path, class_index)
        for class_index, label in enumerate(labels)
        for video_path in sorted((root / label).glob("*"))
        if video_path.suffix.lower() in VIDEO_EXTENSIONS
    ]
    if not samples:
        raise ValueError(f"No videos found under {root}")
    return samples


def collate_batch(
    batch: list[tuple[list[np.ndarray], int]], processor: VideoMAEImageProcessor
) -> tuple[torch.Tensor, torch.Tensor]:
    videos, labels = zip(*batch)
    pixel_values = processor(list(videos), return_tensors="pt").pixel_values
    return pixel_values, torch.tensor(labels, dtype=torch.long)


def main() -> None:
    random.seed(SEED)
    np.random.seed(SEED)
    torch.manual_seed(SEED)
    labels = json.loads(Path("configs/labels.json").read_text(encoding="utf-8"))
    samples = collect_samples(Path("data/raw"), labels)
    if len(samples) < 4:
        raise ValueError("At least four videos are required for a train/validation split")
    random.Random(SEED).shuffle(samples)
    validation_count = max(2, int(round(len(samples) * 0.2)))
    validation_count = min(validation_count, len(samples) - 2)
    validation_samples = samples[:validation_count]
    training_samples = samples[validation_count:]

    processor = VideoMAEImageProcessor.from_pretrained(MODEL_NAME)
    model = VideoMAEForVideoClassification.from_pretrained(
        MODEL_NAME,
        num_labels=len(labels),
        id2label={index: label for index, label in enumerate(labels)},
        label2id={label: index for index, label in enumerate(labels)},
        ignore_mismatched_sizes=True,
    )
    for parameter in model.videomae.parameters():
        parameter.requires_grad = False

    train_loader = DataLoader(
        VideoDataset(training_samples),
        batch_size=2,
        shuffle=True,
        collate_fn=lambda batch: collate_batch(batch, processor),
    )
    validation_loader = DataLoader(
        VideoDataset(validation_samples),
        batch_size=2,
        shuffle=False,
        collate_fn=lambda batch: collate_batch(batch, processor),
    )
    optimizer = torch.optim.AdamW(model.classifier.parameters(), lr=1e-3)
    best_validation_loss = float("inf")
    best_state: dict[str, torch.Tensor] | None = None

    for epoch in range(10):
        model.train()
        total_loss = 0.0
        for pixel_values, targets in train_loader:
            optimizer.zero_grad()
            loss = model(pixel_values=pixel_values, labels=targets).loss
            loss.backward()
            optimizer.step()
            total_loss += float(loss.item())

        model.eval()
        validation_loss = 0.0
        with torch.inference_mode():
            for pixel_values, targets in validation_loader:
                validation_loss += float(
                    model(pixel_values=pixel_values, labels=targets).loss.item()
                )
        validation_loss /= len(validation_loader)
        print(f"epoch={epoch + 1:02d} loss={total_loss / len(train_loader):.4f} val_loss={validation_loss:.4f}")
        if validation_loss < best_validation_loss:
            best_validation_loss = validation_loss
            best_state = {
                name: parameter.detach().cpu().clone()
                for name, parameter in model.state_dict().items()
            }

    if best_state is None:
        raise RuntimeError("VideoMAE training did not produce a checkpoint")
    model.load_state_dict(best_state)
    output_path = Path("models/videomae")
    output_path.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(output_path)
    processor.save_pretrained(output_path)
    print(f"Saved {output_path} (best val_loss={best_validation_loss:.4f})")


if __name__ == "__main__":
    main()