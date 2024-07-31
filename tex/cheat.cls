%  pgf-fix %{{{
\newif\ifhtlatex
\ifx\HCode\UnDeFiNeD
  \htlatexfalse
\else
  \htlatextrue
\fi
\ifdefined\HCode
   \def\pgfsysdriver{pgfsys-dvisvgm4ht.def}
\fi
%  %}}}

\ProvidesClass{cheat}

%  Parse options %{{{
\newcommand{\useline}{yes}
\DeclareOption{noline}{\renewcommand{\useline}{no}}
\DeclareOption{line}{\renewcommand{\useline}{yes}}
\newcommand{\cols}{3}
\DeclareOption{cols=0}{\renewcommand{\cols}{0}}
\DeclareOption{cols=1}{\renewcommand{\cols}{1}}
\DeclareOption{cols=2}{\renewcommand{\cols}{2}}
\DeclareOption{cols=3}{\renewcommand{\cols}{3}}
\DeclareOption{cols=4}{\renewcommand{\cols}{4}}
\DeclareOption{cols=5}{\renewcommand{\cols}{5}}
\DeclareOption{cols=6}{\renewcommand{\cols}{6}}
\DeclareOption{cols=7}{\renewcommand{\cols}{7}}
\DeclareOption{cols=8}{\renewcommand{\cols}{8}}
\DeclareOption{cols=9}{\renewcommand{\cols}{9}}
\newcommand{\orientation}{landscape}
\DeclareOption{landscape}{\renewcommand{\orientation}{landscape}}
\DeclareOption{portrait}{\renewcommand{\orientation}{}}
\newcommand{\usenumbers}{yes} % Numbered sections vs bulleted sections
\newcommand{\numbers}{\renewcommand{\usenumbers}{yes}}
\newcommand{\nonumbers}{\renewcommand{\usenumbers}{no}}
\DeclareOption{numbers}{\numbers}
\DeclareOption{nonumbers}{\nonumbers}
\newcommand{\usewidemargin}{no}
\DeclareOption{widemargin}{\renewcommand{\usewidemargin}{yes}}
\DeclareOption{nowidemargin}{\renewcommand{\usewidemargin}{no}}
\newcommand{\usemobilefmt}{no}
\DeclareOption{mobile}{\renewcommand{\usemobilefmt}{yes}}
\DeclareOption{nomobile}{\renewcommand{\usemobilefmt}{no}}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\RequirePackage{ifthen}
\ifthenelse{\equal{\orientation}{portrait}}{}{%
    \PassOptionsToClass{landscape}{article}%
}
%  %}}}

\LoadClass{article}

% Avoid `too many math alphabets error` %{{{
\newcommand\hmmax{0}
\newcommand\bmmax{0}
% %}}}

%  raisedrule {{{
\newcommand{\raisedrule}[2][0em]{\leavevmode\xleaders\hbox{\rule[#1]{1pt}{#2}}\hfill}
\newcommand{\dottedraisedrule}[2][0em]{\leavevmode\xleaders\hbox{\rule[#1]{1pt}{#2}~}\hfill}
%  }}}

%  Require Packages %{{{
\RequirePackage[utf8]{inputenc}
\RequirePackage[ngerman]{babel}
\RequirePackage[T1]{fontenc}
\RequirePackage[dvipsnames,table]{xcolor}
\RequirePackage{tikz}
\usetikzlibrary{shapes,positioning,arrows,fit,calc,graphs,graphs.standard,graphdrawing,babel}
\usegdlibrary{trees}
\usegdlibrary{layered}
\RequirePackage{pgfplots}
\RequirePackage{pgf-pie}
\RequirePackage[nosf]{kpfonts}
\RequirePackage{iftex}
\ifLuaTeX
    % Use Pro from here https://github.com/hung1001/font-awesome-pro
    % apparently the fontawesome
    \RequirePackage[pro]{fontawesome5}
    \def\fontawesomepro{yes}
    % check using \ifthenelse{\isundefined{fontawesomepro}}{no}{yes}
\else
    \RequirePackage{fontawesome5}
\fi%
\RequirePackage[t1]{sourcesanspro}
\RequirePackage{nicefrac}
\RequirePackage{lastpage}
\RequirePackage{multicol}
\ifthenelse{\equal{\useline}{yes}}{\RequirePackage{multicolrule}}{}
\RequirePackage{wrapfig}
\RequirePackage{geometry}%
\RequirePackage[framemethod=tikz]{mdframed}
\RequirePackage{microtype}
\ifhtlatex
\else
\RequirePackage{pdfpages}
\fi
\RequirePackage{dashrule}
\RequirePackage{upgreek}
\RequirePackage{bm}
\RequirePackage{trfsigns}
\RequirePackage{mathrsfs}
\let\Perp\relax  % Handle name clash
\let\Bot\relax  % Handle name clash
\let\Top\relax  % Handle name clash
\RequirePackage{logix}  % for Tortoise Brakcets and other special symbols wold clash with unicode-math if loaded the other way around
\RequirePackage{unicode-math}

\RequirePackage{tabularx, booktabs, threeparttable, caption}
%  %}}}

%  Page geometry {{{
\ifthenelse{\equal{\usewidemargin}{yes}}{%
    \geometry{headheight=1mm,top=18mm,bottom=15mm,left=10mm,right=10mm}
}{%
    \geometry{headheight=1mm,top=12mm,bottom=5mm,left=5mm,right=5mm}
}
\ifthenelse{\equal{\usemobilefmt}{yes}}{
    \geometry{paperheight=21cm,paperwidth=11cm}
}{}
%  }}}

% Clock Format %{{{
% Work with custom analog-clock pandoc filter
% maybe use this: https://tex.stackexchange.com/questions/132321/generate-analog-clock-with-numbered-face/


% Options: Setting them to any string means don't use this but an empty string means use
\def\useanalogclock{n}
\def\useemojiclock{n}
\def\usesevensegmentclock{}

\if\relax\useanalogclock\relax%
    \RequirePackage[clock]{ifsym}%
\else\if\relax\usesevensegmentclock\relax%
        \RequirePackage{ifsym}%
    \fi%
\fi
\if\relax\useemojiclock\relax%
    \ifLuaTeX%
        \RequirePackage{emoji}%
    \fi%
\fi
\newcommand{\digitalClock}[2]{%
    \if\relax\usesevensegmentclock\relax%
        {%
            \fontsize{7}{10}\selectfont%
            \textifsym{#1}%
            \textsuperscript{%
                { \tiny\textcolor{black}{\textifsym{#2}} }%
            }%
        }%
    \fi%
}
\newcommand{\analogClock}[2]{%
    \if\relax\useanalogclock\relax%
        {%
            \fontsize{7}{10}\selectfont%
            \showclock{#1}{#2}%
        }%
    \fi%
}
\newcommand{\emojiClock}[1]{%
    \if\relax\useemojiclock\relax%
        \ifLuaTeX%
            {%
                \fontsize{7}{10}\selectfont%
                \emoji{#1}%
            }%
        \fi%
    \fi%
}
\newcommand{\fallbackClock}[2]{%
    \if\relax\useanalogclock\relax\else%
        \if\relax\usesevensegmentclock\relax\else%
            \if\relax\useemojiclock\relax%
                \ifLuaTeX\else%
                    #1:#2%
                \fi%
            \else%
                #1:#2%
            \fi%
        \fi%
    \fi%
}
\newcommand{\clockFmt}[5]{%
    % \clockFmt{hour}{minute}{twelf_hour_clock}{five_min_nearest_min}{emoji_name_nearest}
    \mbox{%
        \analogClock{#3}{#4}%
        \emojiClock{#5}%
        \digitalClock{#1}{#2}%
        \fallbackClock{#1}{#2}%
    }%
}
% %}}}

%  Date format {{{
% \RequirePackage[most]{tcolorbox}
\RequirePackage{ctex}

\newcommand{\dateFmtMoreArgTrick}[3]{}  % dummy declaration
\newcommand{\dateFmtSeperator}[2][1]{\raisebox{.3ex}{
        {\color{myblue}{\tiny \kern-#1ex #2\kern-1ex}}
}}
\newcommand{\formatDate}[3]{%
    #1\dateFmtSeperator{年}%
    #2\dateFmtSeperator{月}%
    #3\dateFmtSeperator[1.4]{日}%
}
\newcommand{\dateFmtWrongDowMsg}{{\color{red} WRONG Day of Week in Markdown file}}
\newcommand{\dateFmt}[9]{%
    % \dateFmt
    %   {dow_us}                   %  1
    %   {year_century}             %  2
    %   {year}                     %  3
    %   {zero_padded_year}         %  4
    %   {month_name_us}            %  5
    %   {month_number}             %  6
    %   {zero_padded_month_number} %  7
    %   {day}                      %  8
    %   {zero_padded_day}          %  9
    %   {dow_de}                   % 10
    %   {month_name_de}            % 11
    %   {is_dow_correct}           % 12
    \renewcommand{\dateFmtMoreArgTrick}[3]{%
                \raisebox{.3ex}{%
                    {\color{myblue}{\tiny ##1}}%
                }%
                \formatDate{#4}{#7}{#9}%
                \ifthenelse{\equal{##3}{False}}{\dateFmtWrongDowMsg}{}%
    }%
    \dateFmtMoreArgTrick%
}

%  }}}

%  Ligatures %{{{
%  commands{{{
\newcommand{\colmath}[1]{% Keep color for text mode when switching to math mode
    \colorlet{colmathinternalcolor}{.}%
    \ensuremath{{\color{colmathinternalcolor} #1}}%
}
\newcommand{\ligatureOf}[1]{#1~}
%  }}}

%  arrows {{{
%  squigly {{{
\newcommand{\ligatureArrowSquiglyLeft}{\ligatureOf{\colmath{\leftsquigarrow}%
    }}  % <~
\newcommand{\ligatureArrowSquiglyRight}{\ligatureOf{\colmath{\rightsquigarrow}%
    }}  % ~>
\newcommand{\ligatureArrowSquiglyBoth}{\ligatureOf{\colmath{\leftrightsquigarrow}%
    }}  % <~>
%  }}}
%  normal {{{
\newcommand{\ligatureArrowLeft}{\ligatureOf{\faLongArrowAltLeft}}  % <-
\newcommand{\ligatureArrowRight}{\ligatureOf{\faLongArrowAltRight}}  % ->
\newcommand{\ligatureArrowBoth}{\ligatureOf{\faArrowsAltH}}  % <->
\newcommand{\ligatureArrowMap}{\ligatureOf{\colmath{\mapsto}%
    }}  % |->
\newcommand{\ligatureArrowCircledLeft}{\ligatureOf{\faArrowAltCircleLeft[regular]}} % (<-)
\newcommand{\ligatureArrowCircledRight}{\ligatureOf{\faArrowAltCircleRight[regular]}} % (<-)
%  }}}
%  double {{{
\newcommand{\ligatureArrowDoubleRight}{\ligatureOf{\colmath{\Rightarrow}%
    }}  % =>
\newcommand{\ligatureArrowDoubleRightLong}{\ligatureOf{\colmath{\Longrightarrow}%
    }}  % ==>
\newcommand{\ligatureArrowDoubleBoth}{\ligatureOf{\colmath{\Leftrightarrow}%
    }}  % <=>
%  }}}
%  }}}

%  emoji {{{
%  Smile {{{
\newcommand{\ligatureEmojiSmileAlt}{\ligatureOf{\faSmile}}  % :)
\newcommand{\ligatureEmojiSmile}{\ligatureOf{\faSmile[regular]}}  % :-)
\newcommand{\ligatureEmojiWinkAlt}{\ligatureOf{\faSmileWink}}  % ;)
\newcommand{\ligatureEmojiWink}{\ligatureOf{\faSmileWink[regular]}}  % ;-)
%  }}}
%  Tongue {{{
\newcommand{\ligatureEmojiTongueAlt}{\ligatureOf{\faGrinTongue}}  % :P
\newcommand{\ligatureEmojiTongue}{\ligatureOf{\faGrinTongue[regular]}}  % :-P
\newcommand{\ligatureEmojiTongueWinkAlt}{\ligatureOf{\faGrinTongueWink}}  % ;P
\newcommand{\ligatureEmojiTongueWink}{\ligatureOf{\faGrinTongueWink[regular]}}  % ;-P
%  }}}
%  Grin {{{  % Consider replacing grin with \faLaugh etc.
\newcommand{\ligatureEmojiGrinAlt}{\ligatureOf{\faGrin}}  % :D
\newcommand{\ligatureEmojiGrin}{\ligatureOf{\faGrin[regular]}}  % :-D
\newcommand{\ligatureEmojiGrinBeamAlt}{\ligatureOf{\faGrinBeam}}  % XD
\newcommand{\ligatureEmojiGrinBeam}{\ligatureOf{\faGrinBeam[regular]}}  % X-D
\newcommand{\ligatureEmojiGrinWinkAlt}{\ligatureOf{\faGrinWink}}  % ;D
\newcommand{\ligatureEmojiGrinWink}{\ligatureOf{\faGrinWink[regular]}}  % ;-D
\newcommand{\ligatureEmojiGrinHeartsAlt}{\ligatureOf{\faGrinHearts}}  % <3D
\newcommand{\ligatureEmojiGrinHearts}{\ligatureOf{\faGrinHearts[regular]}}  % <3-D
\newcommand{\ligatureEmojiGrinStarsAlt}{\ligatureOf{\faGrinStars}}  % xD
\newcommand{\ligatureEmojiGrinStars}{\ligatureOf{\faGrinStars[regular]}}  % x-D
%  }}}
%  Sad,Frown {{{
\newcommand{\ligatureEmojiSadCry}{\ligatureOf{\faSadCry[regular]}}  % :~(
\newcommand{\ligatureEmojiSadTear}{\ligatureOf{\faSadTear[regular]}}  % :,(
\newcommand{\ligatureEmojiFrownAlt}{\ligatureOf{\faFrown}}  % :(
\newcommand{\ligatureEmojiFrown}{\ligatureOf{\faFrown[regular]}}  % :-(
%  }}}
%  Meh {{{
\newcommand{\ligatureEmojiMehAlt}{\ligatureOf{\faMeh}}  % :|
\newcommand{\ligatureEmojiMeh}{\ligatureOf{\faMeh[regular]}}  % :-|
%  }}}
%  }}}

%  dyadic signs {{{
\newcommand{\ligatureDyadicGreater}{\ligatureOf{\faGreaterThan}}  % >
\newcommand{\ligatureDyadicGreaterEqual}{\ligatureOf{\faGreaterThanEqual}}  % >=
\newcommand{\ligatureDyadicLess}{\ligatureOf{\faLessThan}}  % <
\newcommand{\ligatureDyadicLessEqual}{\ligatureOf{\faLessThanEqual}}  % <=
\newcommand{\ligatureDyadicEqual}{\ligatureOf{\faEquals}}  % =
\RequirePackage{xfakebold}
\newcommand{\ligatureDyadicApprox}{\ligatureOf{\setBold[1.2]$\textcolor{black}{\approx}$\unsetBold}} % ≈ fontawesome doesn't contain a approx or even just a tilde in it's free version
\newcommand{\ligatureDyadicNotequal}{\ligatureOf{\faNotEqual}}  % !=
\newcommand{\ligatureDyadicPlus}{\ligatureOf{\faPlus}}  % +
\newcommand{\ligatureDyadicMinus}{\ligatureOf{\faMinus}}  % -
\newcommand{\ligatureDyadicSlash}{\ligatureOf{\reflectbox{\faSlash}
    }}  % /  faSlash is actually a backslash % TODO: consider changing, looks extreme off
\newcommand{\ligatureDyadicTimes}{\ligatureOf{\faTimes}}
\newcommand{\ligatureDyadicEqualCircled}{\ligatureOf{\faEqualsCircle}}  % (=)
\newcommand{\ligatureDyadicPlusCircled}{\ligatureOf{\faMinusCircle}}  % (-)
\newcommand{\ligatureDyadicMinusCircled}{\ligatureOf{\faPlusCircle}}  % (+)
%  }}}

%  Separator {{{
\newcommand{\ligatureSeparatorVert}{\ligatureOf{\faGripLinesVertical}}  % ||
\newcommand{\ligatureSeparatorHorizontal}{\ligatureOf{\faGripLines}}  % ==

\ifthenelse{\isundefined{fontawesomepro}}{%
    \setmathfont{XITS-Math}
    % \newcommand{\ligatureSeparatorDiamond}{\ligatureOf{\colmath{\mdblkdiamond}%
    %    }}  % <>
    \newcommand{\ligatureSeparatorDiamond}{\ligatureOf{\colmath{\mdlgblkdiamond}%
        }}  % <>
}{%
    \newcommand{\ligatureSeparatorDiamond}{\ligatureOf{\faIcon{diamond}
    }}  % <>
}
\newcommand{\ligatureSeperatorCircle}{\ligatureOf{\faCircle}}
\newcommand{\ligatureSeperatorTrinagelLeft}{\ligatureOf{\faPlay}}  % |>
\newcommand{\ligatureSeperatorTrinagelRight}{\ligatureOf{\rotatebox[origin=c]{180}{\faPlay}%
    }}  % <|
%  }}}

%  misc {{{
\newcommand{\ligatureHeardAlt}{\ligatureOf{\faHeart[regular]}}  % <3
\newcommand{\ligatureElipsis}{\ligatureOf{\faEllipsis}}  % ...
\newcommand{\ligatureExclamation}{\ligatureOf{\faExclamationTriangle}}  % <!>
\newcommand{\ligatureExclamationDouble}{\ligatureOf{\faExclamation\faExclamation}}  % <!>
\newcommand{\ligatureQuestion}{\ligatureOf{\faQuestionCircle}}  % (?)
\newcommand{\ligatureQuestionDouble}{\ligatureOf{\faQuestion\faQuestion}}  % ??
\newcommand{\ligatureQuestionStart}{\ligatureOf{
    \rotatebox[origin=c]{180}{\faQuestion}%
}}  % ¿
\newcommand{\ligatureQuestionEnd}{\ligatureOf{\faQuestion}}  % ?
\newcommand{\ligatureQuestionStartEnd}{\ligatureOf{%
    \rotatebox[origin=c]{180}{\faQuestion}\faQuestion%
}} % ¿?
\newcommand{\ligatureBulb}{\ligatureOf{\faLightbulb[regular]}}  % ()=
\newcommand{\ligatureMagnifingy}{\ligatureOf{\faSearch}}  % O-
\newcommand{\ligatureThumbsUp}{\ligatureOf{\faThumbsUp[regular]}}  % +1
\newcommand{\ligatureThumbsDown}{\ligatureOf{\faThumbsDown[regular]}}  % +1
%  }}}

%  Quotes {{{
\newcommand{\ligatureQuoteLeft}{\ligatureOf{\faAngleDoubleLeft}}  % <<
\newcommand{\ligatureQuoteRight}{\ligatureOf{\faAngleDoubleRight}}  % >>
%  }}}

%  Currency {{{
\newcommand{\ligatureCurrenyDollar}{\ligatureOf{\faDollarSign}}
\newcommand{\ligatureCurrenyEuro}{\ligatureOf{\faEuroSign}}
\newcommand{\ligatureCurrenyYen}{\ligatureOf{\faYenSign}}
%  }}}

%  Unicode {{{
\newcommand{\ligatureUnicodeLightning}{\ligatureOf{\faBolt}}
%  }}}

%  Text {{{
% All keys in all caps and followed by colon (don't find those every time I grep for actual tods)
\newcommand{\ligatureTextTodo}{\ligatureOf{\faClipboardList}} % todo
\newcommand{\ligatureTextError}{\ligatureOf{\faBomb}} % error
\newcommand{\ligatureTextWarning}{\ligatureOf{\faExclamationTriangle}} % warning
\newcommand{\ligatureTextBug}{\ligatureOf{\faBug}} % bug
\newcommand{\ligatureTextIdea}{\ligatureOf{\faLightbulb}} % idea ⇔ ()=
\newcommand{\ligatureTextQuestion}{\ligatureOf{%
    \rotatebox[origin=c]{180}{\faQuestion}\faQuestion%
}} % question ¿?
\newcommand{\ligatureTextInfo}{\ligatureOf{\faInfo}} % info
\newcommand{\ligatureTextNote}{\ligatureOf{\faStickyNote}} % note
\newcommand{\ligatureTextBookmark}{\ligatureOf{\faBookmark}} % bookmark
\newcommand{\ligatureTextStop}{\ligatureOf{\faBan}} % stop  (faOctagon/the stop sign is only in pro)
\newcommand{\ligatureTextDate}{\ligatureOf{\faCalendar*}} % date 
\newcommand{\ligatureTextCard}{\ligatureOf{\faAddressCard}} % card 
\newcommand{\ligatureTextEmail}{\ligatureOf{\faAt}} % email 
\newcommand{\ligatureTextReminder}{\ligatureOf{\faBell}} % reminder 
\newcommand{\ligatureTextGoal}{\ligatureOf{\faBullseye}} % goal 
%  }}}

%  %}}}

%  Quotes %{{{
\let\BuiltinQuote\quote
\let\endBuiltinQuote\endquote
\global\mdfdefinestyle{quoteframestyle}{linewidth=2pt,linecolor=myblue,%
    rightline=false,topline=false,bottomline=false}
\renewenvironment{quote}{%
    % \BuiltinQuote
    \begin{mdframed}[style=quoteframestyle]%
    \small\list{}{\rightmargin=0.3cm \leftmargin=0.4cm}%
        \item[\textcolor{myblue}{\faQuoteLeft}]\relax
}{%
    \hfill\rlap{\textcolor{myblue}{\faQuoteRight}}\endlist%
    \end{mdframed}%
    % \endBuiltinQuote%
}
%  %}}}

%  Enumeration Setup %{{{
\RequirePackage{enumitem} 
\setlist{nosep,leftmargin=3.mm}
\setlist[description]{%
    style=sameline,%nextline,%
}
\renewcommand{\descriptionlabel}[1]{%
    \hspace{\labelsep}%
    \raisebox{0.1em}{\fontsize{6}{10}\selectfont\textcolor{myblue}{\faThList}}~%
    \textsf{#1}~~%
    \textcolor{gray}{\raisedrule[0.3em]{0.2pt}}%
}
\setlistdepth{20}
\renewlist{itemize}{itemize}{20}
% initially, use dots for all levels
\setlist[itemize]{label=$\cdot$}
% customize the first 3 levels
\setlist[itemize,1]{label=\textbullet}
\setlist[itemize,2]{label=$\circ$}
\setlist[itemize,3]{label=$\diamond$}
% % Use `.` to skip first specially treated line of definition environment
% Unfortunately this just doesn't work for all cases e.g. if there is a command
% imidiately after \item for now move to a pandoc filter for replacing
% definition lists stating with . by a \null\hfill
% \let\internalitem\item
% \renewcommand{\item}[2][]{%
%     \internalitem[#1]\ifthenelse{%
%         \equal{#2}{.}\AND\NOT\equal{#1}{}%
%     }{\null\hfill}{#2}%
% }
%  %}}}

%  Color %{{{
\definecolor{myblue}{cmyk}{1,.72,0,.38}

\definecolor{highlight}{rgb}{1.0,0.7,0}  % TODO: this is already defined in greek.tex
\def\eqref#1{\textcolor{highlight}{(\ref{#1})}}
%  %}}}

%  calender %{{{
% Work with my custom calendar pandoc filter
\RequirePackage{longfbox}
% \RequirePackage{xltabular}  % This breaks for multi cols cannot figure out how to fix that
% \RequirePackage{array,supertabular,blindtext}
% \RequirePackage[dvipsnames,table]{xcolor} % load befor pgfplots
\RequirePackage{tabularray}

\NewTblrTheme{nohead}{
    \DefTblrTemplate{contfoot-text}{default}{}
    \DefTblrTemplate{conthead-text}{default}{}
    \DefTblrTemplate{caption}{default}{}
    \DefTblrTemplate{conthead}{default}{}
    \DefTblrTemplate{capcont}{default}{}
}

% \newsavebox\WBox
\newenvironment{calenderblock}{%
    \renewcommand{\arraystretch}{1.5}
    % \begin{longtable}{r|l}%
    % \begin{tabularx}{\textwidth}{r|X}% % using begin/end tabularx isn't supported
    % \xltabular{\columnwidth}{r|X}%
    \longtblr[entry=none,label=none, theme=nohead]{colspec={r|X}}
    % % \sbox\WBox{\calenderFmt{Mo}{2022}{22}{12}{Dez}{30}}
    % \sbox\WBox{widest text}
    % \supertabular{
    %     @{}
    %     p{\wd\WBox}
    %     p{\dimexpr\columnwidth-\wd\WBox-2\tabcolsep\relax}
    %     @{}
    % }
}{%
    % \endsupertabular%
    % \endxltabular%
    \endlongtblr
    % \end{longtable}%
    % \end{tabularx}%
}
\newcommand{\calenderDoWFmt}[2][black]{%
    \raisebox{0.2em}{\lfbox[width=2mm,text-align=center,border-color=#1]{%
            \tiny \textcolor{#1}{#2}%
        }%
    }%
}
\newcommand{\calenderFmt}[6]{%
    % \calenderFmt{dow}{longyear}{shortyear}{month}{monthname}{day}
    \ifthenelse{\equal{#1}{Sa}\OR\equal{#1}{So}}{%
        \calenderDoWFmt[myblue]{#1} \textcolor{myblue}{#6}%
    }{%
        \calenderDoWFmt{#1} #6%
    }%
}
\definecolor{calenderverylightgray}{HTML}{DDDDDD}
\newcommand{\calenderOddRow}{\SetRow{calenderverylightgray}}
\newcommand{\calenderEvenRow}{}
\definecolor{calenderverylightblue}{HTML}{4d88f7}
\newcommand{\calenderMonthStart}{\SetRow{calenderverylightblue}}
\newcommand{\calenderMonthEnd}{} %\arrayrulecolor{calender-very-light-blue}\hline}
\definecolor{calenderlightgray}{HTML}{BBBBBB}
\newcommand{\calenderDaySkipStart}{\SetRow{calenderlightgray}}
\newcommand{\calenderDaySkipEnd}{}
\newcommand{\calenderDaySep}{${\color{black}\cdots\cdots}$}
%  %}}}

%  multicols %{{{
\ifthenelse{\equal{\cols}{0}\OR\equal{\cols}{1}\OR\equal{\usemobilefmt}{yes}}{}{%
    \AtBeginDocument{\begin{multicols*}{\cols}}%
    \AtEndDocument{\end{multicols*}}%
}
\ifthenelse{\equal{\useline}{yes}}{%
    \SetMCRule{line-style=dash-dot,color=myblue}%
    \columnseprule=0.2mm%
}{}
%  %}}}

%  tikz settings %{{{
\def\firstcircle{(0,0) circle (1.5cm)}
\def\secondcircle{(0:2cm) circle (1.5cm)}

\colorlet{circle edge}{myblue}
\colorlet{circle area}{myblue!5}

\tikzset{filled/.style={fill=circle area, draw=circle edge, thick},
    outline/.style={draw=circle edge, thick}}
\pgfplotsset{compat=newest}

\RequirePackage{xstring}

\newcommand{\tikzline}[1]{
    \begin{tikzpicture}[
            >=latex',
            square/.style={regular polygon, regular polygon sides=4, draw},
            diamond/.style={regular polygon, regular polygon sides=4, shape border rotate=45, draw},
            b/.style={rectangle, draw=myblue}, % block
            s/.style={circle, fill=none, draw=myblue, minimum width=2mm, inner sep=0mm}, % sum
            p/.style={inner sep=0pt, outer sep=0pt, minimum size=2pt, fill=myblue}, % midway node
            Lof/.style n args={1}{right=1 of ##1},  % left of element
            Rof/.style n args={1}{left=1 of ##1},   % right
            Tof/.style n args={1}{above=1 of ##1},  % top
            Bof/.style n args={1}{below=1 of ##1}  % bottom
        ]
        #1
    \end{tikzpicture}
}
\newcommand{\tikzpic}[1]{\begin{center}\tikzline{#1}\end{center}}

%  circuits {{{
\usepackage[european,straightvoltages]{circuitikz}
\newcommand{\circuitline}[1]{
    \ctikzset{bipoles/length=10mm}
    \begin{circuitikz}[
            x=40mm,
            y=40mm,
            Lof/.style n args={1}{right=1 of ##1},  % left of element
            Rof/.style n args={1}{left=1 of ##1},   % right
            Tof/.style n args={1}{above=1 of ##1},  % top
            Bof/.style n args={1}{below=1 of ##1}   % bottom
        ]
        #1
    \end{circuitikz}
}
\newcommand{\circuitpic}[1]{\begin{center}\tikzline{#1}\end{center}}
%  }}}

%  Bondgraphs {{{
\usepackage{bondgraphs}
\usetikzlibrary{graphs,quotes}
\newcommand{\bgraph}[1]{\graph[grow right=15mm]{#1};}
\newcommand{\bondline}[1]{
    \begin{bondgraph}[
            Lof/.style n args={1}{right=1 of ##1},  % left of element
            Rof/.style n args={1}{left=1 of ##1},   % right
            Tof/.style n args={1}{above=1 of ##1},  % top
            Bof/.style n args={1}{below=1 of ##1}   % bottom
        ]
        #1
    \end{bondgraph}
}
\newcommand{\bondpic}[1]{\begin{center}\bondline{#1}\end{center}}
%  }}}

%  %}}}

%  background %{{{
\pgfdeclarelayer{background}
\pgfsetlayers{background,main}
%  %}}}

%  math environment %{{{
\colorlet{mymathcolor}{myblue}
\everymath\expandafter{\the\everymath \color{mymathcolor}}
\everydisplay\expandafter{\the\everydisplay \color{mymathcolor}}
\let\bar\overline
%  %}}}

%  header %{{{
\renewcommand{\baselinestretch}{.8}
\pagestyle{empty}

\global\mdfdefinestyle{header}{%
linecolor=myblue,linewidth=0.5pt,%
leftmargin=0mm,rightmargin=0mm,skipbelow=0mm,skipabove=0mm,%
innerleftmargin=3mm,innerrightmargin=3mm%
}

\newcommand{\headerText}{%
    \null\hfill\nicefrac{\thepage}{\pageref{LastPage}}
}
\newcommand{\head}[1]{\renewcommand{\headerText}{#1}}

\RequirePackage{fancyhdr}
\AtBeginDocument{%
    \fancypagestyle{myplain}{%
        \renewcommand{\headrulewidth}{0.0pt}%
        \fancyhead{%
            \begin{mdframed}[style=header]%
                \footnotesize\sffamily\noindent\headerText%
            \end{mdframed}%
        }%
        \renewcommand{\footrulewidth}{0.4pt}
        \fancyfoot{}%
    }%
    \pagestyle{myplain}%
}
%  %}}}

%  Paragraph headings %{{{
\setlength{\parindent}{0pt}
\newcommand{\useoldstyle}{no}
\colorlet{headingcolor}{black}
% \colorlet{headingcolor}{myblue}
\ifthenelse{\equal{\useoldstyle}{yes}}{
    % Author: https://tex.stackexchange.com/questions/218587/how-to-set-one-header-for-each-page-using-multicols
    \newcommand{\internalSectionHeaderStyle}[1]{%
        \textcolor{myblue}{\hrule\vspace{.9ex}\sffamily\large\bfseries #1\vspace{.2ex}\hrule}
    }
    \renewcommand{\section}{
        \@startsection{section}{1}{0mm}{.2ex}{.2ex}{\internalSectionHeaderStyle}}%
    \newcommand{\internalSubsectionHeaderStyle}[1]{%
        \textcolor{myblue}{\sffamily\bfseries #1\vspace{.2ex}\hrule}
    }
    \renewcommand{\subsection}{\@startsection{subsection}{1}{0mm}%
                                    {.2ex}%
                                    {.2ex}%x
                                    {\internalSubsectionHeaderStyle}}
    \newcommand{\internalSubsubsectionHeaderStyle}[1]{%
        \textcolor{myblue}{\bfseries #1\vspace{.1ex}}\hrule
    }
    \renewcommand{\subsubsection}{\@startsection{subsubsection}{2}{0mm}%
                                    {.0ex}%
                                    {.1ex}%x
                                    {\internalSubsubsectionHeaderStyle}}
}{
    % TODO: Use \raisedrule from below for \*section this seams surprisingly difficult
    \newcommand{\internalSectionHeaderStyle}[1]{%
        \textcolor{headingcolor}{\vspace{0.1ex}\hrule\vspace{.5ex}\sffamily\Large\bfseries #1\vspace{.5ex}\hrule\vspace{0.1ex}}
    }
    \renewcommand{\section}{
        \@startsection{section}{1}{0mm}{.2ex}{.2ex}{\internalSectionHeaderStyle}}%
    \newcommand{\internalSubsectionHeaderStyle}[1]{%
        \textcolor{headingcolor}{\vspace{0.1ex}\hrule\vspace{.4ex}\sffamily\large\bfseries #1\vspace{.4ex}\hrule\vspace{0.1ex}}%
    }
    \renewcommand{\subsection}{%
        \@startsection{subsection}{1}{0mm}{0.2ex}{0.2ex}{\internalSubsectionHeaderStyle}}
    \newcommand{\internalSubsubsectionHeaderStyle}[1]{%
        \textcolor{headingcolor}{\vspace{0.1ex}\hrule\vspace{.3ex}\sffamily\bfseries #1\vspace{.3ex}\hrule\vspace{0.1ex}}%
    }
    \renewcommand{\subsubsection}{%
        \@startsection{subsubsection}{2}{0mm}{.0ex}{.1ex}{\internalSubsubsectionHeaderStyle}%
    }
}
\newcommand{\internalParagraphHeaderStyle}[1]{%
    \textcolor{headingcolor}{\textbf{#1}}%
}
\newcommand{\internalSubparagraphHeaderStyle}[1]{%
    \textcolor{headingcolor}{#1}}
\ifthenelse{\equal{\usenumbers}{yes}}{%
    \renewcommand{\paragraph}[1]{\internalParagraphHeaderStyle{#1}}%
    \renewcommand{\subparagraph}[1]{\internalSubparagraphHeaderStyle{#1}}%
}{%
    % \def\sectionsymbol{\faBullseye}  % {\faDotCircleO}  % {◉}
    % \def\subsectionsymbol{\faCircle[regular]}  % {\faCircleO}  % {○}
    % \def\subsubsectionsymbol{\faAsterisk}  % {faCertificate}  % {✸}
    % \def\paragraphsymbol{\faCog} % {\faGear}  % {✿}
    % \def\subparagraphsymbol{\faSnowflake}  % {\faGe}  % {❀}
    % \def\subsubparagraphsymbol{\faCrosshairs}  % {\faSun0}  % {◇}  % Currently unused
    \newcommand{\secbulletstyle}[1]{\textcolor{myblue}{#1}}

    % \def\sectionsymbol{\secbulletstyle{\faBullseye}}
    % \def\subsectionsymbol{\secbulletstyle{\faCircle}}
    % \def\subsubsectionsymbol{\secbulletstyle{\faDotCircle[regular]}}
    % \def\paragraphsymbol{\secbulletstyle{\faCircle[regular]}}
    % \def\subparagraphsymbol{\secbulletstyle{\faSun[regular]}}

    % IDEA: maybe take inspiration from this list of unicode bullets
    %       https://symbl.cc/en/collections/list-bullets/
    % List Bullets 
    %     • • ∙ ⊙ ⊚ ⊛ ◉ ○ ◌ ◍ ◎ ● ◘ ◦ 。 ☉ ⦾ ⦿ ⁃ ⁌ ⁍ ◆ ◇ ◈ ★ ☆ ❖ ⋄ ❥ ❧ ☙ ✤ ✱ ✲ ✦ ✧
    % Ballot and Marks Bullets
    %     ■ □ ☐ ☒ ✓
    % Arrow Bullets
    %     ↠ ↣ ↦ ↬ ⇛ ⇝ ⇢ ⇨ ➔ ➙ ➛ ➜ ➝ ➞ ➟ ➠ ➢ ➣ ➤ ➥ ➦ ➧ ➨ ➮ ➱ ➲ ➳ ➵ ➸ ➼ ➾ → ⇾ ⇒ ‣ ▷ ▹ ► ▻
    % Emoji Bullets
    %     Black Large Square
    %     Black Medium Square
    %     Black Medium Small Square
    %     Black Small Square
    %     Black Diamond Suit
    %     Large Orange Diamond
    %     Small Blue Diamond
    %     Small Orange Diamond
    %     Radio Button
    %     Ballot Box with Check
    %     White Heavy Check Mark
    %     Heavy Check Mark
    %     Large Blue Circle
    %     Large Green Circle
    %     Large Orange Circle
    %     Large Red Circle
    %     Sparkle
    %     Medium Black Circle
    %     Large Brown Circle
    %     Large Purple Circle
    %     Information Source
    %     Diamond Shape with a Dot Inside
    %     Eight Spoked Asterisk
    %     No Entry
    %     Warning Sign
    %     Black Rightwards Arrow

    % \def\sectionsymbol{\secbulletstyle{\faBullseye}}
    % \def\subsectionsymbol{\secbulletstyle{\faCircle}}
    % \def\subsubsectionsymbol{\secbulletstyle{\faSquare}}
    % \def\paragraphsymbol{\secbulletstyle{\faPlay}}
    % \def\subparagraphsymbol{\secbulletstyle{\faMinus}}
    \def\sectionsymbol{\secbulletstyle{\faDiceOne}}
    \def\subsectionsymbol{\secbulletstyle{\faDiceTwo}}
    \def\subsubsectionsymbol{\secbulletstyle{\faDiceThree}}
    \def\paragraphsymbol{\secbulletstyle{\faDiceFour}}
    \def\subparagraphsymbol{\secbulletstyle{\faDiceFive}}
    % \faSun
    \makeatletter\renewcommand\@seccntformat[1]{%
        \csname#1symbol\endcsname\quad%
    }\makeatother

    \makeatletter
    \renewcommand{\paragraph}[1]{%
        \@startsection{paragraph}{4}{0mm}{0.0ex}{0.0ex}%
            {\internalParagraphHeaderStyle}{\paragraphsymbol\>}%
        \internalParagraphHeaderStyle{#1}\>\raisedrule[0.3em]{0.2pt}%
    }
    \renewcommand{\subparagraph}[1]{%
        \@startsection{subparagraph}{5}{0mm}{0.0ex}{0.0ex}%
            {\internalSubparagraphHeaderStyle}{\subparagraphsymbol\>}%
        \internalSubparagraphHeaderStyle{#1}\>\raisedrule[0.3em]{0.1pt}%
    }
    \makeatother
}

%  %}}}

%  float visibility %{{{
% Make Sure Figures actually show up!
\RequirePackage{float}
\floatplacement{figure}{H}
\setkeys{Gin}{width=\columnwidth}
\captionsetup{%
  font=small,
  labelfont=bf,
  singlelinecheck=false,
  tableposition=top,
  skip=0pt,
  figurename=Abb.
}
%  %}}}

%  Code Blocks using listings %{{{
\RequirePackage{code}
%  Don't color math inside listings %{{{
\AtBeginEnvironment{lstlisting}{%
    \colorlet{mymathcolorbuffer}{mymathcolor}%
    \colorlet{mymathcolor}{listing-identifier}%
}
\AtEndEnvironment{lstlisting}{\colorlet{mymathcolor}{mymathcolorbuffer}}
%  %}}}
%  %}}}

%  Operators %{{{
\let\argmin\relax
\DeclareMathOperator{\argmin}{arg\,min}
\let\argmax\relax
\DeclareMathOperator{\argmax}{arg\,max}
\let\erf\relax
\DeclareMathOperator{\erf}{erf}
\DeclareMathOperator{\rect}{rect}
\DeclareMathOperator{\sinc}{sinc}
% \providecommand{\ul}[1]{\underline{#1}}  % already in greek.sty adding it again breaks thins in soul later one
\newcommand{\ol}[1]{\overline{#1}}
\providecommand{\pgfsyspdfmark}[3]{}
%  %}}}

%  image input {{{

% Drop this for now. Cannot get those included tikz images to scale properly

% Diagram generator generated pgf files (for now only graphviz will produce
% those) are still included using \includegraphics but should be included with
% and input statement
% \RequirePackage{xstring}
% \let\latexincludegraphics\includegraphics
% \renewcommand{\includegraphics}[2][]{%
%     \IfEndWith{#2}{.pgf}{\input{#2}}{\latexincludegraphics[#1]{#2}}%
% }

%  }}}


 % vim: set foldmarker=%{{{,%}}}
