#!/usr/bin/env python3

import bibtexparser
import sys
from pathlib import Path

library = bibtexparser.parse_file(Path("~/Zotero/bib-files/refs.bib").expanduser()) #sys.argv[0])

# The pdf file we want to find the .org notes file for
pdf_file = sys.argv[1]

for entry in library.entries:
    for key in entry.fields:
        if key.key == "file":
            # key.value might have more than one file, e.g. errata.pdf or some html file.
            files = key.value.split(";")
            for f in files:
                if Path(f).name == Path(pdf_file).name:
                    sys.exit(entry.key + ".org")
