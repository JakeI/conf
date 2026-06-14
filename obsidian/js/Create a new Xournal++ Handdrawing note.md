<%*
const folder = "xournalpp-notes";
const templateBase = "xournalpp-template";
const xoppExtension = ".xopp";
const pdfExtension = "_kommentiert.pdf";  // that's what xournalpp uses by default, using this Extension I can just hit save without changing the filename at all

// 1. Get selected text
let name = tp.file.selection();

// 2. Fallback to timestamp if empty
if (!name || name.trim() === "") {
    const now = new Date();
    const pad = (n) => n.toString().padStart(2, '0');

    name = `handwritten_${now.getFullYear()}-${pad(now.getMonth()+1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
} else {
    name = name.trim().replace(/[\\/#^|[\]:*?"<>]/g, "-");
}

// Paths
const xoppPath = `${folder}/${name}${xoppExtension}`;
const pdfPath  = `${folder}/${name}${pdfExtension}`;

const templateXopp = `${folder}/${templateBase}${xoppExtension}`;
const templatePdf  = `${folder}/${templateBase}${pdfExtension}`;

// 3. Get files
const tXopp = app.vault.getAbstractFileByPath(templateXopp);
const tPdf  = app.vault.getAbstractFileByPath(templatePdf);

if (!tXopp || !tPdf) {
    new Notice("Template files not found! Aborting template creation");
    return;
}

// Prevent overwrite
if (app.vault.getAbstractFileByPath(xoppPath) || app.vault.getAbstractFileByPath(pdfPath)) {
    new Notice("File already exists! Aborting template creation");
    return;
}

// 4. Read + create new files
const xoppData = await app.vault.readBinary(tXopp);
await app.vault.createBinary(xoppPath, xoppData);

const pdfData = await app.vault.readBinary(tPdf);
await app.vault.createBinary(pdfPath, pdfData);

// 5. Insert link
tR += `![${name}](<${pdfPath}>)\n🖊️ [Edit](<${xoppPath}>)`;
%>