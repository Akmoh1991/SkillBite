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

    def _get_resource_type(self, name):
        suffix = Path(name).suffix.lower()
        if suffix in self.video_extensions:
            return "video"
        return "image"
