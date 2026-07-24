"""Jupyter Server identity provider for HeLx per-user notebook pods.

With token auth disabled (--IdentityProvider.token=), jupyter-server assigns
each browser a random "Anonymous <moon>" identity. Collaborator cursors and
the RTC user list are built from this identity (the frontend copies /api/me
into the Y awareness state), so on HeLx we resolve it from the $USER env var
that tycho sets on every per-user pod instead.

Selected in init.sh via --ServerApp.identity_provider_class (PYTHONPATH
includes /helx/lib).
"""
import os

from jupyter_server.auth.identity import PasswordIdentityProvider, User


class HelxIdentityProvider(PasswordIdentityProvider):
    # Subclass PasswordIdentityProvider, NOT IdentityProvider: the server's
    # default provider is PasswordIdentityProvider, whose auth_enabled returns
    # False when token and password are both empty -- that is what lets
    # --IdentityProvider.token= disable the login page. The base class hardcodes
    # auth_enabled=True and would prompt for a password.
    def generate_anonymous_user(self, handler):
        name = os.environ.get("USER") or os.environ.get("NB_USER") or "jovyan"
        return User(
            username=name,
            name=name,
            display_name=name,
            initials=name[:2].upper(),
            avatar_url=None,
            color=None,
        )
