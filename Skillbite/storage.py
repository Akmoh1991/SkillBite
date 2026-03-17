from pathlib import Path

from cloudinary_storage.storage import MediaCloudinaryStorage


class ResourceAwareCloudinaryStorage(MediaCloudinaryStorage):
    """Use Cloudinary image or video storage based on the uploaded file extension."""

    video_extensions = {
        ".mp4",
        ".webm",
        ".mov",
        ".avi",
        ".mkv",
        ".mpeg",
        ".mpg",
        ".wmv",
        ".flv",
        ".m4v",
        ".3gp",
        ".ogv",
    }

    video_path_markers = (
        "course_content_videos/",
    )

    raw_extensions = {
        ".pdf",
    }

    raw_path_markers = (
        "course_content_pdfs/",
    )

    def _get_resource_type(self, name):
        normalized_name = str(name).replace("\\", "/").lower()
        suffix = Path(normalized_name).suffix.lower()
        if suffix in self.video_extensions:
            return "video"
        if any(marker in normalized_name for marker in self.video_path_markers):
            return "video"
        if suffix in self.raw_extensions:
            return "raw"
        if any(marker in normalized_name for marker in self.raw_path_markers):
            return "raw"
        return "image"
