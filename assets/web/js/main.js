// assets/web/main.js

// Adicionamos novas opções de configuração ao OSMD
const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmd-container", {
    backend: "svg",
    autoResize: true,
    drawTitle: false,
    drawPartNames: false, // <-- NOVO: Remove o nome da parte (ex: "Music") e economiza espaço
    zoom: 0.9, // <-- NOVO: Zoom ligeiramente maior para otimizar o espaço
    defaultColorMusic: "#FFFFFF",
    pageBackgroundColor: "#0f0f2d",
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