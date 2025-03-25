cd "$(pwd)/.."
xcodebuild test  \
  -project DropPdf.xcodeproj  \
  -scheme DropPdf  \
  -destination 'platform=macOS'  \
  -only-testing:DropPdfTests  \
  CODE_SIGNING_ALLOWED=NO
