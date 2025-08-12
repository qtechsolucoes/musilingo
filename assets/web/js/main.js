// --- ALTERAÇÃO INÍCIO ---
// Adicionamos novas opções de configuração ao OSMD
const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmd-container", {
    backend: "svg",
    drawFromMeasureNumber: 1,
    drawUpToMeasureNumber: Number.MAX_SAFE_INTEGER,
    autoResize: true,
    // --- NOVAS OPÇÕES ---
    drawTitle: false, // Remove o texto "Untitled Score"
    zoom: 0.8, // Ajusta o zoom inicial para a pauta caber melhor
    // --- FIM DAS NOVAS OPÇÕES ---
    defaultColorMusic: "#FFFFFF",
    pageBackgroundColor: "#0f0f2d",
});
// --- ALTERAÇÃO FIM ---

window.loadScore = function(musicXml) {
    osmd
        .load(musicXml)
        .then(() => {
            osmd.render();
        })
        .catch((error) => {
            console.error("OSMD Error:", error);
        });
};