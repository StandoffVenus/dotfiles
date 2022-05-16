{ writeTextFile }:

let 
  file = "coc-settings.json";
  settings = ''
    {
      "coc.source.file.enable": true,
      "coc.preferences.hoverTarget": "float",
      "coc.preferences.formatOnSaveFiletypes": [
        "go",
        "rust"
      ],
      "languageserver": {
        "golang": {
          "command": "gopls",
          "rootPatterns": [
            "go.mod"
          ],
          "disableWorkspaceFolders": true,
          "filetypes": [
            "go"
          ]
        }
      },
      "diagnostic.displayByAle": true,
      "suggest.autoTrigger": "always",
      "suggest.noselect": true,
      "suggest.minTriggerInputLength": 1,
      "suggest.enablePreview": false,
      "suggest.fixInsertedWord": true
    }
  '';
in writeTextFile {
  name = file;
  executable = false;
  text = settings;
}
