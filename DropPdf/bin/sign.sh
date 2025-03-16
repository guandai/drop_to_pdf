export PUBLISH_KEY=4116EBC16ACE4702F6C509D3B3385B9AF6D8EFAB
codesign --force --sign ${PUBLISH_KEY} --entitlements ./DropPDF/bin/bin.entitlements ./DropPDF/bin/antiword  \
&& codesign --force --sign ${PUBLISH_KEY} --entitlements ./DropPDF/bin/bin.entitlements ./DropPDF/bin/catdoc  \
&& codesign --force --sign ${PUBLISH_KEY} --entitlements ./DropPDF/bin/bin.entitlements ./DropPDF/bin/soffice  \
&& ./DropPdf/bin/soffice   /Users/zhengdai/Downloads/doc.doc 
