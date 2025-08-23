// assets/osmd_viewer/js/main.js

let osmd;

function initializeOSMD() {
  osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("score-container", {
    backend: "svg",
    defaultColorMusic: "#FFFFFF",
    drawCredits: false,
    drawTitle: false,
    drawSubtitle: false,
    drawComposer: false,
    drawLyricist: false,
    drawMetronomeMarks: false,
    drawPartNames: false,
    drawPartAbbreviations: false,
    drawMeasureNumbers: true,
    autoResize: true,
    stretchLastSystemLine: true,
  });
}

window.loadScore = function(musicXml) {
  if (!osmd) {
    initializeOSMD();
  }
  osmd.load(musicXml)
    .then(() => {
      osmd.render();
    })
    .catch((error) => {
      console.error("Error loading or rendering score:", error);
    });
};

// --- NOVAS FUNÇÕES DE COLORAÇÃO ---

// Colore uma nota específica pelo seu índice
window.colorNote = function(noteIndex, color) {
  if (!osmd || !osmd.graphic) return;
  
  let noteIdx = 0;
  for (const measure of osmd.graphic.measureList) {
    for (const staffEntry of measure) {
      for (const graphicalNote of staffEntry.graphicalNotes) {
        if (noteIdx === noteIndex) {
          graphicalNote.sourceNote.noteheadColor = color;
          // Força a re-renderização para aplicar a cor
          osmd.render(); 
          return;
        }
        noteIdx++;
      }
    }
  }
};

// Limpa a cor de todas as notas, voltando ao padrão
window.clearAllNoteColors = function() {
  if (!osmd || !osmd.graphic) return;

  for (const measure of osmd.graphic.measureList) {
    for (const staffEntry of measure) {
      for (const graphicalNote of staffEntry.graphicalNotes) {
         graphicalNote.sourceNote.noteheadColor = osmd.rules.DefaultColorMusic;
      }
    }
  }
  osmd.render();
};