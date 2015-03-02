var cheerio = require('cheerio'),
    fs = require('fs'),
    path = require("path")

function embedTemplates(hostDocumentPath, templateDirectoryPath, outfilePath){
    var indexDocument = fs.readFileSync(hostDocumentPath, "utf8").toString()
    var templateDirectory = fs.readdirSync(templateDirectoryPath)
    var handle = initializeTemplateContainer(indexDocument)
    for(var i = 0; i < templateDirectory.length; i++){
        var templatePath = path.join(templateDirectoryPath, templateDirectory[i])
        var templateContent = fs.readFileSync(templatePath, "utf8").toString()
        var wrappedContent = surroundInScriptTags(templateContent, templatePath)
        handle("#ng-template-container").append(wrappedContent)
    }
    fs.writeFileSync(outfilePath, handle.html())
    return true;
}

function surroundInScriptTags(content, idPath){
    var netPath = idPath.split(path.sep).join("/")
    var wrapped = "<script type='text/ng-template' id='" + netPath + "'>\n"
    wrapped += content//.replace(/'/g, '\'')
    wrapped += "</script>"
    return wrapped
}

function initializeTemplateContainer(doc){
    $ = cheerio.load(doc)
    var container = $("body").find("div#ng-template-container")
    if(container.length > 0) container.html("")
    else $("body").append("<div id='ng-template-container'></div>")
    return $
}


module.exports.embedTemplates = embedTemplates

