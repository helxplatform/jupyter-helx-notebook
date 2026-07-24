"""File ID manager for the HeLx collaboration broker.

The broker's root_dir is a *shared* filesystem: it contains directories owned by
many different users, and normal multi-user storage always has some
owner-only (mode 0700) directories -- trash (``.Trash-*/info``), private
scratch, ssh keys, etc. The broker runs as a single uid that is not the owner
of those directories, so it cannot open them.

Stock ``LocalFileIdManager`` walks the entire tree at startup
(``_index_all`` -> ``_index_dir_recursively``) and again lazily on access
(``index`` -> ``_sync_all`` -> ``_sync_dir``), using a bare ``os.scandir`` with
no error handling. The first unreadable directory raises ``PermissionError``,
which aborts indexing and takes the whole ``jupyter_server_fileid`` extension
(and therefore ``jupyter_server_ydoc``) down with it.

This subclass makes both scans tolerant: an unreadable directory is logged and
skipped instead of aborting. Skipped directories are exactly the ones that are
owner-only, which by definition cannot be collaboratively edited by other
users -- so nothing that qualifies for real-time collaboration is lost. Every
directory the broker *can* read (the group-shared collaboration folders) is
still indexed normally, and ``index()`` keeps its disk-checking behavior
(returns None for paths not present under root_dir), which the resty proxy
relies on to fall back to a user's own pod for private files.

NOTE: this overrides two private methods of LocalFileIdManager (0.9.3). If
jupyter-server-fileid is upgraded, re-verify that these method names/bodies
still match; the pin lives in minimal-poetry-notebook's Dockerfile.
"""
import os

from jupyter_server_fileid.manager import LocalFileIdManager


class HelxLocalFileIdManager(LocalFileIdManager):
    def _scandir_safe(self, dir_path):
        """os.scandir that yields nothing (with a warning) if the directory
        cannot be opened, instead of raising. Mirrors _stat's existing
        tolerance of unreadable paths."""
        try:
            return os.scandir(dir_path)
        except OSError as e:
            self.log.warning(
                "HelxLocalFileIdManager: skipping unreadable directory "
                f"{dir_path!r} during indexing: {e}"
            )
            return None

    def _index_dir_recursively(self, dir_path, stat_info):
        """Recursively indexes all directories under a given path, skipping any
        directory that cannot be opened."""
        self.index(dir_path, stat_info=stat_info, commit=False)

        scan_iter = self._scandir_safe(dir_path)
        if scan_iter is None:
            return
        with scan_iter:
            for entry in scan_iter:
                if entry.is_dir():
                    self._index_dir_recursively(entry.path, self._stat(entry.path))

    def _sync_dir(self, dir_path):
        """Syncs the contents of a directory, skipping it if it cannot be
        opened."""
        scan_iter = self._scandir_safe(dir_path)
        if scan_iter is None:
            return
        with scan_iter:
            for entry in scan_iter:
                stat_info = self._stat(entry.path)
                # _stat returns None for an entry that vanished or cannot be
                # lstat'd; the stock method would AttributeError on it. Skip.
                if stat_info is None:
                    continue
                id = self._sync_file(entry.path, stat_info)

                if stat_info.is_dir and id is None:
                    self._create(entry.path, stat_info)
                    self._sync_dir(entry.path)
