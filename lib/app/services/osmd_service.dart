import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/solfege_exercise.dart';

class OSMDService {
  late WebViewController controller;

  Future<void> initialize() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    // Carregar HTML com OSMD
    final htmlContent = await _getOSMDHtml();
    await controller.loadHtmlString(htmlContent);

    // Aguardar carregamento
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<String> _getOSMDHtml() async {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: Arial, sans-serif;
            background: transparent;
        }
        #osmdCanvas {
            width: 100%;
            background: white;
            border-radius: 10px;
            padding: 20px;
        }
        .note-active {
            fill: #FFD700 !important;
            stroke: #FFD700 !important;
        }
        .note-correct {
            fill: #00FF00 !important;
            stroke: #00FF00 !important;
        }
        .note-incorrect {
            fill: #FF0000 !important;
            stroke: #FF0000 !important;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@1.8.1/build/opensheetmusicdisplay.min.js"></script>
</head>
<body>
    <div id="osmdCanvas"></div>
    
    <script>
        let osmd = null;
        let currentNoteIndex = 0;
        let noteElements = [];
        
        async function initializeOSMD() {
            osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmdCanvas", {
                autoResize: true,
                backend: "svg",
                drawingParameters: "compact",
                drawPartNames: false,
                drawTitle: false,
                drawSubtitle: false,
                drawComposer: false,
                drawLyricist: false
            });
            
            // Enviar mensagem quando estiver pronto
            window.flutter_inappwebview?.callHandler('osmdReady', true);
        }
        
        function generateMusicXML(exercise) {
            const timeSignature = exercise.timeSignature || "4/4";
            const tempo = exercise.tempo || 100;
            const keySignature = exercise.keySignature || "C";
            
            let measuresXML = '';
            let currentMeasure = '<measure number="1">\\n';
            let currentBeats = 0;
            const beatsPerMeasure = parseInt(timeSignature.split('/')[0]);
            
            exercise.noteSequence.forEach((note, index) => {
                const duration = getDurationValue(note.duration);
                const beats = getBeatsForDuration(note.duration);
                
                if (currentBeats + beats > beatsPerMeasure) {
                    currentMeasure += '</measure>\\n';
                    measuresXML += currentMeasure;
                    currentMeasure = '<measure number="' + (measuresXML.split('</measure>').length + 1) + '">\\n';
                    currentBeats = 0;
                }
                
                const [pitch, octave] = note.note.match(/([A-G]#?)(\\d)/).slice(1);
                currentMeasure += \`
                    <note>
                        <pitch>
                            <step>\${pitch.charAt(0)}</step>
                            \${pitch.includes('#') ? '<alter>1</alter>' : ''}
                            <octave>\${octave}</octave>
                        </pitch>
                        <duration>\${duration}</duration>
                        <type>\${note.duration}</type>
                        <lyric>
                            <syllabic>single</syllabic>
                            <text>\${note.lyric}</text>
                        </lyric>
                    </note>\\n\`;
                
                currentBeats += beats;
            });
            
            currentMeasure += '</measure>';
            measuresXML += currentMeasure;
            
            return \`<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 3.1 Partwise//EN" 
    "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="3.1">
    <part-list>
        <score-part id="P1">
            <part-name>Solfejo</part-name>
        </score-part>
    </part-list>
    <part id="P1">
        <measure number="1">
            <attributes>
                <divisions>1</divisions>
                <key>
                    <fifths>0</fifths>
                </key>
                <time>
                    <beats>\${timeSignature.split('/')[0]}</beats>
                    <beat-type>\${timeSignature.split('/')[1]}</beat-type>
                </time>
                <clef>
                    <sign>G</sign>
                    <line>2</line>
                </clef>
            </attributes>
            <direction placement="above">
                <direction-type>
                    <metronome>
                        <beat-unit>quarter</beat-unit>
                        <per-minute>\${tempo}</per-minute>
                    </metronome>
                </direction-type>
            </direction>
        </measure>
        \${measuresXML}
    </part>
</score-partwise>\`;
        }
        
        function getDurationValue(duration) {
            const values = {
                'whole': 4, 'half': 2, 'quarter': 1,
                'eighth': 0.5, 'sixteenth': 0.25
            };
            return values[duration] || 1;
        }
        
        function getBeatsForDuration(duration) {
            const beats = {
                'whole': 4, 'half': 2, 'quarter': 1,
                'eighth': 0.5, 'sixteenth': 0.25
            };
            return beats[duration] || 1;
        }
        
        async function loadExercise(exerciseData) {
            try {
                const exercise = JSON.parse(exerciseData);
                const musicXML = generateMusicXML(exercise);
                
                await osmd.load(musicXML);
                await osmd.render();
                
                // Capturar elementos das notas
                noteElements = document.querySelectorAll('.vf-stavenote');
                
                return true;
            } catch (error) {
                console.error('Erro ao carregar exercício:', error);
                return false;
            }
        }
        
        function highlightNote(index, status) {
            if (index >= 0 && index < noteElements.length) {
                // Remover classes anteriores
                noteElements[index].classList.remove('note-active', 'note-correct', 'note-incorrect');
                
                // Adicionar nova classe
                if (status === 'active') {
                    noteElements[index].classList.add('note-active');
                } else if (status === 'correct') {
                    noteElements[index].classList.add('note-correct');
                } else if (status === 'incorrect') {
                    noteElements[index].classList.add('note-incorrect');
                }
            }
        }
        
        function resetHighlights() {
            noteElements.forEach(element => {
                element.classList.remove('note-active', 'note-correct', 'note-incorrect');
            });
        }
        
        // Inicializar quando a página carregar
        window.addEventListener('load', initializeOSMD);
    </script>
</body>
</html>
''';
  }

  Future<void> loadExercise(SolfegeExercise exercise) async {
    final exerciseJson = jsonEncode({
      'timeSignature': exercise.timeSignature,
      'tempo': exercise.tempo,
      'keySignature': exercise.keySignature,
      'noteSequence': exercise.noteSequence.map((n) => n.toJson()).toList(),
    });

    await controller.runJavaScript('loadExercise(`$exerciseJson`)');
  }

  Future<void> highlightNote(int index, String status) async {
    // status: 'active', 'correct', 'incorrect', 'neutral'
    await controller.runJavaScript('highlightNote($index, "$status")');
  }

  Future<void> resetHighlights() async {
    await controller.runJavaScript('resetHighlights()');
  }
}
