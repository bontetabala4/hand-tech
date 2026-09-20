import numpy as np
import pytest

from app.preprocessing import LANDMARK_SIZE, normalize_sequence


def test_normalize_sequence_preserves_shape() -> None:
    sequence = np.ones((4, LANDMARK_SIZE), dtype=np.float32)
    normalized = normalize_sequence(sequence)
    assert normalized.shape == (4, LANDMARK_SIZE)
    assert normalized.dtype == np.float32


def test_normalize_sequence_rejects_invalid_feature_size() -> None:
    with pytest.raises(ValueError, match="Expected shape"):
        normalize_sequence(np.zeros((4, 3), dtype=np.float32))
