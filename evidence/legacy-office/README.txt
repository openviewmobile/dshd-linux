# Legacy Office (.doc/.xls/.ppt) conversion evidence

Date: 2026-11-10
Backend: bundled @deepseek-ai/libreoffice-kit 0.1.5, wasm
Command: node lib/cli.js convert --input <legacy-file> --output <pdf>; then render --pages all --dpi 110

Fixtures (Apache POI test-data at commit cdcdcf18, Apache-2.0):
  https://raw.githubusercontent.com/apache/poi/cdcdcf1833beb8483229be5989db1ee3b98232c2/test-data/document/SampleDoc.doc
  https://raw.githubusercontent.com/apache/poi/cdcdcf1833beb8483229be5989db1ee3b98232c2/test-data/spreadsheet/1900DateWindowing.xls
  https://raw.githubusercontent.com/apache/poi/cdcdcf1833beb8483229be5989db1ee3b98232c2/test-data/slideshow/SampleShow.ppt

/tmp/legacy/SampleDoc.doc:         Composite Document File V2 Document, Little Endian, Os: Windows, Version 5.1, Code page: 1252, Title: Test Document, Subject: This is a sample document, Author: Nick Burch, Keywords: Testing Sample, Comments: This document is used for testing text and metadata extraction, Template: Normal, Last Saved By: Nick Burch, Revision Number: 2, Name of Creating Application: Microsoft Office Word, Create Time/Date: Fri Jan  4 09:15:00 2008, Last Saved Time/Date: Fri Jan  4 09:15:00 2008, Number of Pages: 2, Number of Words: 20, Number of Characters: 118, Security: 0
/tmp/legacy/1900DateWindowing.xls: Composite Document File V2 Document, Little Endian, Os: MacOS, Version 10.3, Code page: 10000, Author: Dan Sherman, Last Saved By: Alex Jacoby, Create Time/Date: Mon Dec  2 23:48:02 2002, Name of Creating Application: Microsoft Excel, Security: 0
/tmp/legacy/SampleShow.ppt:        Composite Document File V2 Document, Little Endian, Os: Windows, Version 6.1, Code page: 1252, Title: SlideShow Sample, Subject: A sample slideshow, Author: Nick Burch, Keywords: Sample Testing, Comments: This is a sample slideshow, for use with testing etc, Last Saved By: kiwiwings, Revision Number: 5, Name of Creating Application: Microsoft Office PowerPoint, Create Time/Date: Fri Jan  4 11:58:07 2008, Last Saved Time/Date: Wed May 16 21:07:51 2018, Number of Words: 67

717585c0a88f20862c86220163dd03da87cd743970354c6b29add32725f2e833  /tmp/legacy/SampleDoc.doc
7fe0d8901353b8846e8e0543b893eea4283008bc89ae971674b8a9b480fcd15c  /tmp/legacy/1900DateWindowing.xls
64275a6685b8f267827178037dcc59de927475e56385725916f4c6039c7ce7f6  /tmp/legacy/SampleShow.ppt
0454c46255c6d166bc9754083c449031c77ef509ac99c45f626bc8864d84dd20  evidence/legacy-office/1900DateWindowing.pdf
6bad5f7c7dda0e72f78eaf097a092b429984f6800f02f9e6f343bc600d5ce566  evidence/legacy-office/SampleDoc.pdf
1ebb89af3e6664891ace062411b4a49ea1fb9744482f7527af5b7bfa6d6ea198  evidence/legacy-office/SampleShow.pdf

Results:
  .doc  SampleDoc.doc   -> SampleDoc.pdf   2 pages, 21K, text visible
  .xls  1900DateWindowing.xls -> .pdf 1 page, 9.9K, dates visible
  .ppt  SampleShow.ppt -> SampleShow.pdf 2 pages, 28K, title/subtitle visible

Manifests: *-manifest.json (pdfium raster, pageCount, sha256, missingFonts).
