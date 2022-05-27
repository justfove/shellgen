
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