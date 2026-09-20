"""Train a baseline temporal classifier from data/processed/LABEL/*.npy."""
import json
import random
from pathlib import Path

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader, TensorDataset

from app.model import TemporalClassifier
from app.preprocessing import LANDMARK_SIZE

SEED = 42


def load_dataset(root: Path, labels: list[str], frames: int = 120) -> tuple[np.ndarray, np.ndarray]:
    sequences: list[np.ndarray] = []
    targets: list[int] = []
    for class_index, label in enumerate(labels):
        for path in sorted((root / label).glob("*.npy")):
            sequence = np.load(path).astype(np.float32)
            if sequence.shape[1] != LANDMARK_SIZE:
                raise ValueError(f"Unexpected feature size in {path}: {sequence.shape}")
            if len(sequence) >= frames:
                sequence = sequence[:frames]
            else:
                padding = np.zeros((frames - len(sequence), LANDMARK_SIZE), dtype=np.float32)
                sequence = np.concatenate([sequence, padding])
            sequences.append(sequence)
            targets.append(class_index)
    if not sequences:
        raise ValueError(f"No processed samples found under {root}")
    return np.stack(sequences), np.asarray(targets, dtype=np.int64)


def split_dataset(
    features: np.ndarray,
    targets: np.ndarray,
    validation_fraction: float = 0.25,
    seed: int = SEED,
) -> tuple[np.ndarray, np.ndarray]:
    """Create deterministic, class-balanced train and validation indices."""
    if not 0.0 < validation_fraction < 1.0:
        raise ValueError("validation_fraction must be between 0 and 1")

    generator = np.random.default_rng(seed)
    train_indices: list[int] = []
    validation_indices: list[int] = []
    for class_index in np.unique(targets):
        class_indices = np.flatnonzero(targets == class_index)
        generator.shuffle(class_indices)
        if len(class_indices) == 1:
            train_indices.extend(class_indices.tolist())
            continue
        validation_count = max(1, int(round(len(class_indices) * validation_fraction)))
        validation_count = min(validation_count, len(class_indices) - 1)
        validation_indices.extend(class_indices[:validation_count].tolist())
        train_indices.extend(class_indices[validation_count:].tolist())

    if not validation_indices:
        raise ValueError("At least two samples are required for validation")
    if not train_indices:
        raise ValueError("At least one training sample is required")
    return np.asarray(train_indices, dtype=np.int64), np.asarray(validation_indices, dtype=np.int64)


def main() -> None:
    random.seed(SEED)
    np.random.seed(SEED)
    torch.manual_seed(SEED)
    labels = json.loads(Path("configs/labels.json").read_text(encoding="utf-8"))
    features, targets = load_dataset(Path("data/processed"), labels)
    train_indices, validation_indices = split_dataset(features, targets)
    train_dataset = TensorDataset(
        torch.from_numpy(features[train_indices]), torch.from_numpy(targets[train_indices])
    )
    validation_dataset = TensorDataset(
        torch.from_numpy(features[validation_indices]), torch.from_numpy(targets[validation_indices])
    )
    loader = DataLoader(train_dataset, batch_size=min(16, len(train_dataset)), shuffle=True)
    validation_loader = DataLoader(validation_dataset, batch_size=len(validation_dataset))
    model = TemporalClassifier(LANDMARK_SIZE, len(labels))
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
    loss_function = nn.CrossEntropyLoss()
    best_validation_loss = float("inf")

    for epoch in range(20):
        model.train()
        total_training_loss = 0.0
        for batch_features, batch_targets in loader:
            optimizer.zero_grad()
            loss = loss_function(model(batch_features), batch_targets)
            loss.backward()
            optimizer.step()
            total_training_loss += loss.item()

        model.eval()
        with torch.inference_mode():
            validation_features, validation_targets = next(iter(validation_loader))
            validation_loss = loss_function(
                model(validation_features), validation_targets
            ).item()
        training_loss = total_training_loss / len(loader)
        print(
            f"epoch={epoch + 1:02d} loss={training_loss:.4f} "
            f"val_loss={validation_loss:.4f}"
        )

        if validation_loss < best_validation_loss:
            best_validation_loss = validation_loss
            best_state = {
                name: parameter.detach().cpu().clone()
                for name, parameter in model.state_dict().items()
            }

    Path("models").mkdir(exist_ok=True)
    model.load_state_dict(best_state)
    torch.save({"version": "0.2.0", "state_dict": model.state_dict()}, "models/model.pt")
    print(f"Saved models/model.pt (best val_loss={best_validation_loss:.4f})")


if __name__ == "__main__":
    main()
