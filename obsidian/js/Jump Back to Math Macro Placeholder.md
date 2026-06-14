<%*
const editor = app.workspace.activeLeaf.view.sourceMode ? app.workspace.activeLeaf.view.editor : null;

if (editor) {
  const PLACEHOLDER_JUMP = '❉';
  const cursor = editor.getCursor();
  const line = editor.getLine(cursor.line);

  // Look for the previous PLACEHOLDER_JUMP before the cursor
  const textBeforeCursor = line.slice(0, cursor.ch);
  const pos = textBeforeCursor.lastIndexOf(PLACEHOLDER_JUMP);

  if (pos !== -1) {
    // Remove the placeholder and move the cursor there
    editor.replaceRange("", { line: cursor.line, ch: pos }, { line: cursor.line, ch: pos + PLACEHOLDER_JUMP.length });
    editor.setCursor({ line: cursor.line, ch: pos });
  } else {
    // No placeholder found, keep cursor where it is
    editor.setCursor(cursor);
  }
}
%>