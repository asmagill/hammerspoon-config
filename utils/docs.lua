local docMaker = require("hs.doc")

docMaker.registerJSONFile(hs.configdir.."/local_config.json")
docMaker.registerJSONFile(docMaker.locateJSONFile("hs._asm.extras"))
docMaker.registerJSONFile(docMaker.locateJSONFile("hs._asm.filelistmenu"))
docMaker.registerJSONFile(docMaker.locateJSONFile("hs._asm.hotkey"))

return docMaker.fromRegisteredFiles()
