// assets/web/main.js

const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmd-container", {
    backend: "svg",
    autoResize: true,
    drawTitle: false,
    drawPartNames: false,
    zoom: 0.9,
    // --- CORREÇÃO DE CORES ---
    defaultColorMusic: "#FFFFFF", // Cor das notas e linhas da pauta
    pageBackgroundColor: "#0f0f2d", // Cor de fundo para combinar com o app
    // --- FIM DA CORREÇÃO ---
});

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