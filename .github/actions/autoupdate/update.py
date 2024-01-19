#!/usr/bin/env python

import re
import requests
from packaging import version

def get_most_recent_version(name):
    request = requests.get(
        "https://api.anaconda.org/package/gsoc2/" + name
    )
    request.raise_for_status()

    pkg = max(
        request.json()["files"], key=lambda x: version.parse(x["version"])
    )
    return pkg["version"]

agenda_version = get_most_recent_version("agenda")

with open("Soc2forge3/construct.yaml", "r") as f:
    content = f.read()

# Replace agenda version
content = re.sub(r"agenda [\d.]+$", f"agenda {agenda_version}", content, flags=re.M)

with open("Soc2forge3/construct.yaml", "w") as f:
    f.write(content)
