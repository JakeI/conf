<%*
const editor = app.workspace.activeLeaf.view.editor;
const cursor = editor.getCursor().line;

// Scan upward until finding a heading
let level = null;
for (let i = cursor; i >= 0; i--) {
  const line = editor.getLine(i);
  const m = line.match(/^(#+)\s/);
  if (m) {
    level = m[1].length;
    break;
  }
}

if (!level) level = 1;

// Insert heading
const heading = "#".repeat(level) + " ";
const insertLine = cursor + 1;

editor.replaceRange("\n" + heading, { line: cursor, ch: Infinity });
// Move the cursor to the beginning of the new heading line
editor.setCursor({ line: insertLine, ch: heading.length });
-%>
