cd "$(pwd)/.."
xcodebuild test-without-building    \
  -project DropPdf.xcodeproj    \
  -scheme DropPdf    \
  -destination 'platform=macOS'    \
  -only-testing:DropPdfTests/SizeTestFormats

