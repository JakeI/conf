<%*
const path = await navigator.clipboard.readText();
const selected = tp.file.selection();
const isMultiline = str => str && str.includes("\n");
if (isMultiline(path) || isMultiline(selected)) {
	tr += path;
	return;
}
const hasScheme = p => /^(?:[a-zA-Z][a-zA-Z0-9+.-]*:\/\/|mailto:|obsidian:)/.test(p);
const fix = p => "<" + (hasScheme(p) ? "" : "file://") + p + ">";
const clean = fix(path.replace(/^"|"$/g, "").replace(/\\/g, "/"));
const hasText =  str => str && str.length > 0;
tR += hasText(selected) ? `[${selected}](${clean})` : clean;
%>