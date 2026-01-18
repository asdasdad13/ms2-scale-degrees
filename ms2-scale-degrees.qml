import MuseScore 1.0
import QtQuick 2.0

MuseScore {
  version: "2.0"
  description: "Adds scale degrees as lyrics."
  menuPath: "Plugins.Add Scale Degrees"

  function makeSolfaArray(){
    // Standard integers mapped to TPC positions
    return ("𝄫4,𝄫1,𝄫5,𝄫2,𝄫6,𝄫3,𝄫7,♭4,♭1,♭5,♭2,♭6,♭3,♭7,4,1,5,2,6,3,7,♯4,♯1,♯5,♯2,♯6,♯3,♯7,𝄪4,𝄪1,𝄪5,𝄪2,𝄪6,𝄪3,𝄪7").split(',')
  }

  function nameNote(solfaArray, note, key){
    var tpc = note.tpc;
    var index = tpc - key + 1; 
    
    if (index < 0 || index >= solfaArray.length) {
        return "?";
    }
    return solfaArray[index];
  }

  onRun: {
    if (typeof curScore === 'undefined')
      Qt.quit();

    var cursor = curScore.newCursor();
    var startStaff, endStaff, endTick;
    var fullScore = false;

    // Determine selection range
    cursor.rewind(1); // SELECTION_START
    if (!cursor.segment) {
      fullScore = true;
      startStaff = 0;
      endStaff = curScore.nstaves - 1;
    } else {
      startStaff = cursor.staffIdx;
      cursor.rewind(2); // SELECTION_END
      endStaff = cursor.staffIdx;
      endTick = (cursor.tick === 0) ? curScore.lastSegment.tick + 1 : cursor.tick;
    }

    var solfaArray = makeSolfaArray();

    curScore.startCmd();

    for (var s = startStaff; s <= endStaff; s++) {
      for (var v = 0; v < 4; v++) {
        cursor.staffIdx = s;
        cursor.voice = v;
        
        if (fullScore) {
          cursor.rewind(0);
        } else {
          cursor.rewind(1);
        }

        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
          if (cursor.element && cursor.element.type === Element.CHORD) {
            var text = newElement(Element.LYRICS);
            
            text.lineSpacing = 0.2;
            text.color = "#808080";

            text.text = "";
            var notes = cursor.element.notes;
            var sep = "";

            // Build string for chords (bottom to top)
            for (var i = 0; i < notes.length; i++) {
                var degree = nameNote(solfaArray, notes[i], cursor.keySignature);
                text.text = degree + sep + text.text;
                sep = "\n";
            }

            if (text.text !== "") {
              text.verse = v;
              cursor.element.add(text);
            }
          }
          cursor.next();
        }
      }
    }
    curScore.endCmd();
    Qt.quit();
  }
}