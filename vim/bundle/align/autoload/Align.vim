
" Align: tool to align multiple fields based on one or more separators
"   Author:		Charles E. Campbell, Jr.
"   Date:		Jun 18, 2012
"   Version:	36
" GetLatestVimScripts: 294 1 :AutoInstall: Align.vim
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim
" Copyright:    Copyright (C) 1999-2012 Charles E. Campbell, Jr. {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               Align.vim is provided *as is* and comes with no warranty
"               of any kind, either expressed or implied. By using this
"               plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
"
" Romans 1:16,17a : For I am not ashamed of the gospel of Christ, for it is {{{1
" the power of God for salvation for everyone who believes; for the Jew first,
" and also for the Greek.  For in it is revealed God's righteousness from
" faith to faith.
"redraw!|call DechoSep()|call inputsave()|call input("Press <cr> to continue")|call inputrestore()

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_Align") || &cp
 finish
endif
let g:loaded_Align = "v36"
if v:version < 700
 echohl WarningMsg
 echo "***warning*** this version of Align needs vim 7.0"
 echohl Normal
 finish
endif
let s:keepcpo= &cpo
set cpo&vim
"DechoTabOn

" ---------------------------------------------------------------------
" Debugging Support: {{{1
"if !exists("g:loaded_Decho") | runtime plugin/Decho.vim | endif

" ---------------------------------------------------------------------
" Options: {{{1
if !exists("g:Align_xstrlen")
 if &enc == "latin1" || $LANG == "en_US.UTF-8" || !has("multi_byte")
  let g:Align_xstrlen= 0
 else
  let g:Align_xstrlen= 1
 endif
endif

" ---------------------------------------------------------------------
" Align#AlignCtrl: enter alignment patterns here {{{1
"
"   Styles   =  all alignment-break patterns are equivalent
"            C  cycle through alignment-break pattern(s)
"            l  left-justified alignment
"            r  right-justified alignment
"            c  center alignment
"            -  skip separator, treat as part of field
"            :  treat rest of line as field
"            +  repeat previous [lrc] style
"            <  left justify separators
"            >  right justify separators
"            |  center separators
"
"   Builds   =  s:AlignPat  s:AlignCtrl  s:AlignPatQty
"            C  s:AlignPat  s:AlignCtrl  s:AlignPatQty
"            p  s:AlignPrePad
"            P  s:AlignPostPad
"            w  s:AlignLeadKeep
"            W  s:AlignLeadKeep
"            I  s:AlignLeadKeep
"            l  s:AlignStyle
"            r  s:AlignStyle
"            -  s:AlignStyle
"            +  s:AlignStyle
"            :  s:AlignStyle
"            c  s:AlignStyle
"            g  s:AlignGPat
"            v  s:AlignVPat
"            <  s:AlignSep
"            >  s:AlignSep
"            |  s:AlignSep
fun! Align#AlignCtrl(...)

"  call Dfunc("Align#AlignCtrl(...) a:0=".a:0)

  " save options that may be changed later
  call s:SaveUserOptions()

  " turn ignorecase off
  setlocal noic

  " clear visual mode so that old visual-mode selections don't
  " get applied to new invocations of Align().
  if v:version < 602
   if !exists("s:Align_gavemsg")
	let s:Align_gavemsg= 1
    echomsg "Align needs at least Vim version 6.2 to clear visual-mode selection"
   endif
  elseif exists("s:dovisclear")
"   call Decho("clearing visual mode a:0=".a:0." a:1<".a:1.">")
   let clearvmode= visualmode(1)
  endif

  " set up a list akin to an argument list
  if a:0 > 0
   let A= s:QArgSplitter(a:1)
  else
   let A=[0]
  endif

  if A[0] > 0
   let style = A[1]

   " Check for bad separator patterns (zero-length matches)
   " (but zero-length patterns for g/v is ok)
   if style !~# '[gv]'
    let ipat= 2
    while ipat <= A[0]
     if "" =~ A[ipat]
      echoerr "(AlignCtrl) separator<".A[ipat]."> matches zero-length string"
	  call s:RestoreUserOptions()
"	  call Dret("Align#AlignCtrl")
      return
     endif
     let ipat= ipat + 1
    endwhile
   endif
  endif
"  call Decho("(AlignCtrl) passed bad-separator pattern check (no zero-length matches)")

"  call Decho("(AlignCtrl) A[0]=".A[0])
  if !exists("s:AlignStyle")
   let s:AlignStyle= 'l'
  endif
  if !exists("s:AlignPrePad")
   let s:AlignPrePad= 0
  endif
  if !exists("s:AlignPostPad")
   let s:AlignPostPad= 0
  endif
  if !exists("s:AlignLeadKeep")
   let s:AlignLeadKeep= 'w'
  endif

  if A[0] == 0
   " ----------------------
   " List current selection
   " ----------------------
   if !exists("s:AlignPatQty")
	let s:AlignPatQty= 0
   endif
   echo "AlignCtrl<".s:AlignCtrl."> qty=".s:AlignPatQty." AlignStyle<".s:AlignStyle."> Padding<".s:AlignPrePad."|".s:AlignPostPad."> LeadingWS=".s:AlignLeadKeep." AlignSep=".s:AlignSep
"   call Decho("(AlignCtrl) AlignCtrl<".s:AlignCtrl."> qty=".s:AlignPatQty." AlignStyle<".s:AlignStyle."> Padding<".s:AlignPrePad."|".s:AlignPostPad."> LeadingWS=".s:AlignLeadKeep." AlignSep=".s:AlignSep)
   if      exists("s:AlignGPat") && !exists("s:AlignVPat")
	echo "AlignGPat<".s:AlignGPat.">"
   elseif !exists("s:AlignGPat") &&  exists("s:AlignVPat")
	echo "AlignVPat<".s:AlignVPat.">"
   elseif exists("s:AlignGPat") &&  exists("s:AlignVPat")
	echo "AlignGPat<".s:AlignGPat."> AlignVPat<".s:AlignVPat.">"
   endif
   let ipat= 1
   while ipat <= s:AlignPatQty
	echo "Pat".ipat."<".s:AlignPat_{ipat}.">"
"	call Decho("(AlignCtrl) Pat".ipat."<".s:AlignPat_{ipat}.">")
	let ipat= ipat + 1
   endwhile

  else
   " ----------------------------------
   " Process alignment control settings
   " ----------------------------------
"   call Decho("process the alignctrl settings")
"   call Decho("style<".style.">")

   if style ==? "default"
     " Default:  preserve initial leading whitespace, left-justified,
     "           alignment on '=', one space padding on both sides
	 if exists("s:AlignCtrlStackQty")
	  " clear AlignCtrl stack
      while s:AlignCtrlStackQty > 0
	   call Align#AlignPop()
	  endwhile
	  unlet s:AlignCtrlStackQty
	 endif
	 " Set AlignCtrl to its default value
     call Align#AlignCtrl("Ilp1P1=<",'=')
	 call Align#AlignCtrl("g")
	 call Align#AlignCtrl("v")
	 let s:dovisclear = 1
	 call s:RestoreUserOptions()
"	 call Dret("Align#AlignCtrl")
	 return
   endif

   if style =~# 'm'
	" map support: Do an AlignPush now and the next call to Align()
	"              will do an AlignPop at exit
"	call Decho("style case m: do AlignPush")
	call Align#AlignPush()
	let s:DoAlignPop= 1
   endif

   " = : record a list of alignment patterns that are equivalent
   if style =~# "=" || (A[0] >= 2 && style !~# "C" && s:AlignCtrl =~# '=')
"	call Decho("style case =: record list of equiv alignment patterns")
    let s:AlignCtrl  = '='
	if A[0] >= 2
     let s:AlignPatQty= 1
     let s:AlignPat_1 = A[2]
     let ipat         = 3
     while ipat <= A[0]
      let s:AlignPat_1 = s:AlignPat_1.'\|'.A[ipat]
      let ipat         = ipat + 1
     endwhile
     let s:AlignPat_1= '\('.s:AlignPat_1.'\)'
"     call Decho("AlignCtrl<".s:AlignCtrl."> AlignPat<".s:AlignPat_1.">")
	endif

    "c : cycle through alignment pattern(s)
   elseif style =~# 'C' || (A[0] >= 2 && s:AlignCtrl =~# '=')
"	call Decho("style case C: cycle through alignment pattern(s)")
    let s:AlignCtrl  = 'C'
	if A[0] >= 2
     let s:AlignPatQty= A[0] - 1
     let ipat         = 1
     while ipat < A[0]
      let s:AlignPat_{ipat}= A[ipat+1]
"     call Decho("AlignCtrl<".s:AlignCtrl."> AlignQty=".s:AlignPatQty." AlignPat_".ipat."<".s:AlignPat_{ipat}.">")
      let ipat= ipat + 1
     endwhile
	endif
   endif

   if style =~# 'p'
    let s:AlignPrePad= substitute(style,'^.*p\(\d\+\).*$','\1','')
"	call Decho("style case p".s:AlignPrePad.": pre-separator padding")
    if s:AlignPrePad == ""
     echoerr "(AlignCtrl) 'p' needs to be followed by a numeric argument'"
	 call s:RestoreUserOptions()
"	 call Dret("Align#AlignCtrl")
     return
	endif
   endif

   if style =~# 'P'
    let s:AlignPostPad= substitute(style,'^.*P\(\d\+\).*$','\1','')
"	call Decho("style case P".s:AlignPostPad.": post-separator padding")
    if s:AlignPostPad == ""
     echoerr "(AlignCtrl) 'P' needs to be followed by a numeric argument'"
	 call s:RestoreUserOptions()
"	 call Dret("Align#AlignCtrl")
     return
	endif
   endif

   if     style =~# 'w'
"	call Decho("style case w: ignore leading whitespace")
	let s:AlignLeadKeep= 'w'
   elseif style =~# 'W'
"	call Decho("style case W: keep leading whitespace")
	let s:AlignLeadKeep= 'W'
   elseif style =~# 'I'
"	call Decho("style case I: retain initial leading whitespace")
	let s:AlignLeadKeep= 'I'
   endif

   if style =~# 'g'
	" first list item is a "g" selector pattern
"	call Decho("style case g: global selector pattern")
	if A[0] < 2
	 if exists("s:AlignVPat")
	  unlet s:AlignVPat
"	  call Decho("unlet s:AlignGPat")
	 endif
	else
	 let s:AlignGPat= A[2]
"	 call Decho("s:AlignGPat<".s:AlignGPat.">")
	endif
   elseif style =~# 'v'
	" first list item is a "v" selector pattern
"	call Decho("style case v: global selector anti-pattern")
	if A[0] < 2
	 if exists("s:AlignGPat")
	  unlet s:AlignGPat
"	  call Decho("unlet s:AlignVPat")
	 endif
	else
	 let s:AlignVPat= A[2]
"	 call Decho("s:AlignVPat<".s:AlignVPat.">")
	endif
   endif

    "[-lrc+:] : set up s:AlignStyle
   if style =~# '[-lrc+:*]'
"	call Decho("style case [-lrc+:]: field justification")
    let s:AlignStyle= substitute(style,'[^-lrc:+*]','','g')
"    call Decho("AlignStyle<".s:AlignStyle.">")
   endif

   "[<>|] : set up s:AlignSep
   if style =~# '[<>|]'
"	call Decho("style case [-lrc+:]: separator justification")
	let s:AlignSep= substitute(style,'[^<>|]','','g')
"	call Decho("AlignSep ".s:AlignSep)
   endif
  endif

  " sanity
  if !exists("s:AlignCtrl")
   let s:AlignCtrl= '='
  endif

  " restore options and return
  call s:RestoreUserOptions()
"  call Dret("Align#AlignCtrl ".s:AlignCtrl.'p'.s:AlignPrePad.'P'.s:AlignPostPad.s:AlignLeadKeep.s:AlignStyle)
  return s:AlignCtrl.'p'.s:AlignPrePad.'P'.s:AlignPostPad.s:AlignLeadKeep.s:AlignStyle
endfun

" ---------------------------------------------------------------------
" s:MakeSpace: returns a string with spacecnt blanks {{{1
fun! s:MakeSpace(spacecnt)
"  call Dfunc("MakeSpace(spacecnt=".a:spacecnt.")")
  let str      = ""
  let spacecnt = a:spacecnt
  while spacecnt > 0
   let str      = str . " "
   let spacecnt = spacecnt - 1
  endwhile
"  call Dret("MakeSpace <".str.">")
  return str
endfun

" ---------------------------------------------------------------------
" Align#Align: align selected text based on alignment pattern(s) {{{1
fun! Align#Align(hasctrl,...) range
"  call Dfunc("Align#Align(hasctrl=".a:hasctrl.",...) a:0=".a:0)

  " sanity checks
  if string(a:hasctrl) != "0" && string(a:hasctrl) != "1"
   echohl Error|echo 'usage: Align#Align(hasctrl<'.a:hasctrl.'> (should be 0 or 1),"separator(s)"  (you have '.a:0.') )'|echohl None
"   call Dret("Align#Align")
   return
  endif
  if exists("s:AlignStyle") && s:AlignStyle == ":"
   echohl Error |echo '(Align#Align) your AlignStyle is ":", which implies "do-no-alignment"!'|echohl None
"   call Dret("Align#Align")
   return
  endif

  " save user options
  call s:SaveUserOptions()

  " set up a list akin to an argument list
  if a:0 > 0
   let A= s:QArgSplitter(a:1)
  else
   let A=[0]
  endif

  " if :Align! was used, then the first argument is (should be!) an AlignCtrl string
  " Note that any alignment control set this way will be temporary.
  let hasctrl= a:hasctrl
"  call Decho("hasctrl=".hasctrl)
  if a:hasctrl && A[0] >= 1
"   call Decho("Align! : using A[1]<".A[1]."> for AlignCtrl")
   if A[1] =~ '[gv]'
   	let hasctrl= hasctrl + 1
	call Align#AlignCtrl('m')
    call Align#AlignCtrl(A[1],A[2])
"    call Decho("Align! : also using A[2]<".A[2]."> for AlignCtrl")
   elseif A[1] !~ 'm'
    call Align#AlignCtrl(A[1]."m")
   else
    call Align#AlignCtrl(A[1])
   endif
  endif

  " Check for bad separator patterns (zero-length matches)
  let ipat= 1 + hasctrl
  while ipat <= A[0]
   if "" =~ A[ipat]
	echoerr "(Align) separator<".A[ipat]."> matches zero-length string"
	call s:RestoreUserOptions()
"    call Dret("Align#Align")
	return
   endif
   let ipat= ipat + 1
  endwhile

  " record current search pattern for subsequent restoration
  " (these are all global-only options)
  set noic report=10000 nohls

  if A[0] > hasctrl
  " Align will accept a list of separator regexps
"   call Decho("A[0]=".A[0].": accepting list of separator regexp")

   if s:AlignCtrl =~# "="
   	"= : consider all separators to be equivalent
"    call Decho("AlignCtrl: record list of equivalent alignment patterns")
    let s:AlignCtrl  = '='
    let s:AlignPat_1 = A[1 + hasctrl]
    let s:AlignPatQty= 1
    let ipat         = 2 + hasctrl
    while ipat <= A[0]
     let s:AlignPat_1 = s:AlignPat_1.'\|'.A[ipat]
     let ipat         = ipat + 1
    endwhile
    let s:AlignPat_1= '\('.s:AlignPat_1.'\)'
"    call Decho("AlignCtrl<".s:AlignCtrl."> AlignPat<".s:AlignPat_1.">")

   elseif s:AlignCtrl =~# 'C'
    "c : cycle through alignment pattern(s)
"    call Decho("AlignCtrl: cycle through alignment pattern(s)")
    let s:AlignCtrl  = 'C'
    let s:AlignPatQty= A[0] - hasctrl
    let ipat         = 1
    while ipat <= s:AlignPatQty
     let s:AlignPat_{ipat}= A[(ipat + hasctrl)]
"     call Decho("AlignCtrl<".s:AlignCtrl."> AlignQty=".s:AlignPatQty." AlignPat_".ipat."<".s:AlignPat_{ipat}.">")
     let ipat= ipat + 1
    endwhile
   endif
  endif

  " Initialize so that begline<endline and begcol<endcol.
  " Ragged right: check if the column associated with '< or '>
  "               is greater than the line's string length -> ragged right.
  " Have to be careful about visualmode() -- it returns the last visual
  " mode used whether or not it was used currently.
  let begcol   = virtcol("'<")-1
  let endcol   = virtcol("'>")-1
  if begcol > endcol
   let begcol  = virtcol("'>")-1
   let endcol  = virtcol("'<")-1
  endif
"  call Decho("begcol=".begcol." endcol=".endcol)
  let begline  = a:firstline
  let endline  = a:lastline
  if begline > endline
   let begline = a:lastline
   let endline = a:firstline
  endif

  " Expand range to cover align-able lines when the given range is only the current line.
  " Look for the first line above the current line that matches the first separator pattern, and
  " look for the last  line below the current line that matches the first separator pattern.
  if begline == endline
"   call Decho("case begline == endline")
   if !exists("s:AlignPat_{1}")
	echohl Error|echo "(Align) no separators specified!"|echohl None
	call s:RestoreUserOptions()
"    call Dret("Align#Align")
    return
   endif
   let seppat = s:AlignPat_{1}
   let begline= search('^\%(\%('.seppat.'\)\@!.\)*$',"bnW")
   if begline == 0|let begline= 1|else|let begline= begline + 1|endif
   let endline= search('^\%(\%('.seppat.'\)\@!.\)*$',"nW")
   if endline == 0|let endline= line("$")|else|let endline= endline - 1|endif
"   call Decho("begline=".begline." endline=".endline." curline#".line("."))
  endif
"  call Decho("begline=".begline." endline=".endline)
  let fieldcnt = 0
  if (begline == line("'>") && endline == line("'<")) || (begline == line("'<") && endline == line("'>"))
   let vmode= visualmode()
"   call Decho("vmode=".vmode)
   if vmode == "\<c-v>"
    let ragged   = ( col("'>") > s:Strlen(getline("'>")) || col("'<") > s:Strlen(getline("'<")) )
   else
	let ragged= 1
   endif
  else
   let ragged= 1
  endif
  if ragged
   let begcol= 0
  endif
"  call Decho("lines[".begline.",".endline."] col[".begcol.",".endcol."] ragged=".ragged." AlignCtrl<".s:AlignCtrl.">")

  " record initial whitespace
  if s:AlignLeadKeep == 'W'
   let wskeep = map(getline(begline,endline),"substitute(v:val,'^\\(\\s*\\).\\{-}$','\\1','')")
  endif

  " Align needs these options
  setl et
  set  paste

  " convert selected range of lines to use spaces instead of tabs
  " but if first line's initial white spaces are to be retained
  " then use 'em
  if begcol <= 0 && s:AlignLeadKeep == 'I'
   " retain first leading whitespace for all subsequent lines
   let bgntxt= substitute(getline(begline),'^\(\s*\).\{-}$','\1','')

   " exception: retain first leading whitespace predicated on g and v patterns
   "            if such a selected line exists
   if exists("s:AlignGPat")
	let firstgline= search(s:AlignGPat,"cnW",endline)
	if firstgline > 0
	 let bgntxt= substitute(getline(firstgline),'^\(\s*\).\{-}$','\1','')
	endif
   elseif exists("s:AlignVPat")
	let firstvline= search(s:AlignVPat,"cnW",endline)
	if firstvline > 0
	 let bgntxt= substitute('^\%(\%('.getline(firstvline).')\@!\)*$','^\(\s*\).\{-}$','\1','')
	endif
   endif
"   call Decho("retaining 1st leading whitespace: bgntxt<".bgntxt.">")
   let &l:et= s:keep_et
  endif
  exe begline.",".endline."ret"

  " record transformed to spaces leading whitespace
  if s:AlignLeadKeep == 'W'
   let wsblanks = map(getline(begline,endline),"substitute(v:val,'^\\(\\s*\\).\\{-}$','\\1','')")
  endif

  " Execute two passes
  " First  pass: collect alignment data (max field sizes)
  " Second pass: perform alignment
  let pass= 1
  while pass <= 2
"   call Decho(" ")
"   call Decho("---- Pass ".pass.": ----")

   let line= begline
   while line <= endline
    " Process each line
    let txt = getline(line)
"    call Decho(" ")
"    call Decho("Pass".pass.": Line ".line." <".txt.">")

    " AlignGPat support: allows a selector pattern (akin to g/selector/cmd )
    if exists("s:AlignGPat")
"	 call Decho("Pass".pass.": AlignGPat<".s:AlignGPat.">")
	 if match(txt,s:AlignGPat) == -1
"	  call Decho("Pass".pass.": skipping")
	  let line= line + 1
	  continue
	 endif
    endif

    " AlignVPat support: allows a selector pattern (akin to v/selector/cmd )
    if exists("s:AlignVPat")
"	 call Decho("Pass".pass.": AlignVPat<".s:AlignVPat.">")
	 if match(txt,s:AlignVPat) != -1
"	  call Decho("Pass".pass.": skipping")
	  let line= line + 1
	  continue
	 endif
    endif

	" Always skip blank lines
	if match(txt,'^\s*$') != -1
"	  call Decho("Pass".pass.": skipping")
	 let line= line + 1
	 continue
	endif

    " Extract visual-block selected text (init bgntxt, endtxt)
     let txtlen= s:Strlen(txt)
    if begcol > 0
	 " Record text to left of selected area
     let bgntxt= strpart(txt,0,begcol)
"	  call Decho("Pass".pass.": record text to left: bgntxt<".bgntxt.">")
    elseif s:AlignLeadKeep == 'W'
	 let bgntxt= substitute(txt,'^\(\s*\).\{-}$','\1','')
"	  call Decho("Pass".pass.": retaining all leading ws: bgntxt<".bgntxt.">")
    elseif s:AlignLeadKeep == 'w' || !exists("bgntxt")
	 " No beginning text
	 let bgntxt= ""
"	  call Decho("Pass".pass.": no beginning text")
    endif
    if ragged
	 let endtxt= ""
    else
     " Elide any text lying outside selected columnar region
     let endtxt= strpart(txt,endcol+1,txtlen-endcol)
     let txt   = strpart(txt,begcol,endcol-begcol+1)
    endif
"    call Decho(" ")
"    call Decho("Pass".pass.": bgntxt<".bgntxt.">")
"    call Decho("Pass".pass.":    txt<". txt  .">")
"    call Decho("Pass".pass.": endtxt<".endtxt.">")
	if !exists("s:AlignPat_{1}")
	 echohl Error|echo "(Align) no separators specified!"|echohl None
	 call s:RestoreUserOptions()
"     call Dret("Align#Align")
	 return
	endif

    " Initialize for both passes
    let seppat      = s:AlignPat_{1}
    let ifield      = 1
    let ipat        = 1
    let bgnfield    = 0
    let endfield    = 0
    let alignstyle  = s:AlignStyle
    let doend       = 1
	let newtxt      = ""