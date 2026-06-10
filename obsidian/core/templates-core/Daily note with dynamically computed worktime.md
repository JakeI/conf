# Worktime

```dataviewjs
const today = dv.current().file.name;
if (!/^\d{4}-\d{2}-\d{2}$/.test(today)) {
    dv.paragraph(`*Dataview error:* Note title "${today}" is not in YYYY-MM-DD format.`);
} else {
    const file = app.vault.getAbstractFileByPath("utt-symlink/symlinked-utt-jounal.md");
    const content = await app.vault.read(file);
    let previousMinutes = null;
    const formatMinutes = (minutes) => `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
    const entries = content
        .split("\n")
        .filter(line => line.startsWith(today))
        .map(line => {
			const rest                          = line.slice(today.length).trim();
            const [time, project, ...descParts] = rest.split(/\s+/);
            const description                   = descParts.join(" ");
            const isBreak                       = description.includes("*");
            const isHello                       = project === "hello";
            const [hour, minute]                = time.split(":").map(Number);
            const minutes                       = hour * 60 + minute;
            let duration                        = -1;
            if (previousMinutes !== null && previousMinutes <= minutes)
                duration = minutes - previousMinutes;
            else if (!isHello)
                throw new Error(`Unexpected line format: "${line}"`);
			previousMinutes = minutes;
            return { time, duration, project, description, isBreak, isHello };
        })
        .filter(entry => !entry.isBreak && !entry.isHello);
    dv.table(
        ["Duration", "Project", "Description"],
        entries.map(entry => [
            formatMinutes(entry.duration),
            entry.project,
            entry.description
        ])
    );
    const totalMinutes = entries.reduce((sum, entry) => sum + entry.duration, 0);
    dv.paragraph(`**Total time:** ${formatMinutes(totalMinutes)}`);
}
```
