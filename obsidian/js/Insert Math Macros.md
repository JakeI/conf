<%*
const editor = app.workspace.activeLeaf.view.sourceMode ? app.workspace.activeLeaf.view.editor : null;

if (editor) {
  
  // Use an array of pairs: [regex, replacement]
  // use \1 though \8 for the capture groups
  // use \v for the desired courser position
  // use \f for future courser positions
  // use \r for the current file name without md
  // use \t and \n as tab and newline a always
  // oder is important those are checked sequentially
  const patterns = [
	[/^breadmaid$/, '```breadcrumbs\ntype: mermaid\nstart-note: "\r.md"\nfields: [down]\ndepth: [10]\n```\n' ],
	[                             /tp$/, '^\\mathsf{T}'                                                   ],
	[                          /(0|1)$/, '\\mathbf{\1}'                                                   ],
	[                            /inv$/, '^{-1}'                                                          ],
	[                             /sf$/, '\\mathsf{\v}\f'                                                 ],
	[                             /bf$/, '\\mathbf{\v}\f'                                                 ],
	[                             /\~$/, '\\tilde{\v}\f'                                                  ],
	[                             /\^$/, '\\hat{\v}\f'                                                    ],
	[                             /\.$/, '\\dot{\v}\f'                                                    ],
	[                             /\:$/, '\\ddot{\v}\f'                                                   ],
	[                             /\-$/, '\\bar{\v}\f'                                                    ],
	[                              /d$/, '\\mathsf{d}'                                                    ],
	[               /^(\s*)(.*)mat\s*$/, '\1\2\\begin{bmatrix}\n\1\t\v\n\1\\end{bmatrix}'                 ],
	[                              /t$/, '\1\\text{\v}\f'                                                 ],
	[                              /∂$/, '\\frac{∂\v}{∂\f}\f'                                             ],
	[                              /δ$/, '\\frac{δ\v}{δ\f}\f'                                             ],
	[                            /exp$/, '\\mathsf{e}^{\v}\f'                                             ],
	[                              /e$/, '\\mathsf{e}'                                                    ],
	[                          /\(\s*$/, '\\left(\v\\right)\f'                                            ],
	[                          /\[\s*$/, '\\left[\v\\right]\f'                                            ],
	[                          /\{\s*$/, '\\left{\v\\right}\f'                                            ],
	[                          /\|\s*$/, '\\left|\v\\right|\f'                                            ],
	[                           /∥\s*$/, '\left\lVert\v\right\rVert\f'                                    ],
	[    /^(\s*)(.*)beg\s+([^\s]+)\s*$/, '\1\2\\begin{\3}\n\1\t\v\n\1\\end{\3}'                           ],
	[              /^(\s*)(.*)case\s*$/, '\1\2\\left\\{\\begin{array}{rl}\n\1\t\v\n\1\\end{array}\\right.'],
	[                   /(frac|\/)\s*$/, '\\frac{\v}{\f}\f'                                               ],
	[  /frac\s+([^\s]*)\s+([^\s]*)\s*$/, '\\frac{\1}{\2}'                                                 ],
	[                              /½$/, '\\tfrac{1}{2}'                                                  ],
	[                       /tfrac\s*$/, '\\tfrac{\v}{\f}\f'                                              ],
	[ /tfrac\s+([^\s]*)\s+([^\s]*)\s*$/, '\\tfrac{\1}{\2}'                                                ],
	[                      /^align\s*$/, '$$\n\\begin{aligned}\n\t\v\n\\end{aligned}\n$$'                 ],
	[                        /sqrt\s*$/, '\\sqrt{\v}'                                                     ],
	[             /sqrt\s+([^\s]*)\s*$/, '\\sqrt{\1}'                                                     ],
  ];

  const PLACEHOLDER_JUMP = '❉' // ⌘ ◈ 🗘 ░ ▒ ፨ ⇣ ⇡ ❉
  function jsify(replacement) {  
	return replacement
		.replace(/\$/g, '$$$$')
		.replace(/\f/g, PLACEHOLDER_JUMP)
		.replace(/[\x01-\x08]/g, (m) => `$${m.charCodeAt(0)}`);  // \9 is the \t (tab) char so I have to make due with a max of 8 groups and than its \t -> 9, \n -> 10, \v -> 11, \f -> 12
  }
  
  const cursor = editor.getCursor();
  const line = editor.getLine(cursor.line);
  const textBeforeCursor = line.slice(0, cursor.ch);
  
  let foundMatch = false;
  for (const [pattern, replacement] of patterns) {
    if (pattern.test(textBeforeCursor)) {
	  const rep = jsify(replacement).replace(/\r/, tp.file.title);
      const newText = textBeforeCursor.replace(pattern, rep);
      editor.replaceRange(newText.replace(/\v/, ""), { line: cursor.line, ch: 0 }, cursor);
      const position = newText.indexOf('\v');  // Search for the first cursor marker
      if (position !== -1)
        editor.setCursor({ line: cursor.line, ch: position });
      foundMatch = true;
      break;
    }
  }
  if (!foundMatch) { // manually implemented for else because this language doesn't have an else on the for  
	const textAfterCursor = line.slice(cursor.ch, line.length);
	const pos = textAfterCursor.indexOf(PLACEHOLDER_JUMP);
	console.log(`found pos ${pos}`);
	if (pos !== -1) {  
	  editor.replaceRange("", { line: cursor.line, ch: cursor.ch + pos }, { line: cursor.line, ch: cursor.ch + pos + PLACEHOLDER_JUMP.length });  
	  editor.setCursor({ line: cursor.line, ch: cursor.ch + pos })
	} else {  
	  editor.setCursor(cursor); // If no match, keep the cursor in the original position  
	}  
  }
}
%>