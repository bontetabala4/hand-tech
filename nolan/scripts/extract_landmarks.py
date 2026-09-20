"""Extract one normalized landmarks file per isolated video.

Expected input layout: data/raw/LABEL/*.mp4 (or another OpenCV-readable format).
"""
from pathlib import Path

import numpy as np

from app.preprocessing import LandmarkExtractor


VIDEO_EXTENSIONS = {".mp4", ".webm", ".avi", ".mov", ".mkv"}


def main() -> None:
    source_root = Path("data/raw")
    destination_root = Path("data/processed")
    extractor = LandmarkExtractor()
    processed = 0
    for video_path in sorted(source_root.rglob("*")):
        if video_path.suffix.lower() not in VIDEO_EXTENSIONS:
            continue
        label = video_path.parent.name
        output_path = destination_root / label / f"{video_path.stem}.npy"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        sequence, duration = extractor.extract(video_path)
        np.save(output_path, sequence)
        print(f"{video_path} -> {output_path} ({sequence.shape[0]} frames, {duration:.2f}s)")
        processed += 1
    print(f"Processed {processed} videos")


if __name__ == "__main__":
    main()