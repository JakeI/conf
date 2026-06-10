<%*
const editor = app.workspace.activeLeaf.view.sourceMode ? app.workspace.activeLeaf.view.editor : null;

if (editor) {
  const PLACEHOLDER_JUMP = '❉';
  const cursor = editor.getCursor();
  const line = editor.getLine(cursor.line);

  // Look for the next PLACEHOLDER_JUMP after the cursor
  const textAfterCursor = line.slice(cursor.ch);
  const pos = textAfterCursor.indexOf(PLACEHOLDER_JUMP);

  if (pos !== -1) {
    // Remove the placeholder and move the cursor there
    editor.replaceRange("", { line: cursor.line, ch: cursor.ch + pos }, { line: cursor.line, ch: cursor.ch + pos + PLACEHOLDER_JUMP.length });
    editor.setCursor({ line: cursor.line, ch: cursor.ch + pos });
  } else {
    // No placeholder found, keep cursor where it is
    editor.setCursor(cursor);
  }
}
%>