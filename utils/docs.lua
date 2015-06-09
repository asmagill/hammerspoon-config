local docMaker = require("hs._asm.doc")

docMaker.registerJSONFile(docMaker.locateJSONFile("hs._asm.doc"))
docMaker.registerJSONFile(docMaker.locateJSONFile("hs._asm.extras"))
docMaker.registerJSONFile(docMaker.locateJSONFile("hs._asm.filelistmenu"))

return docMaker.fromRegisteredFiles()
