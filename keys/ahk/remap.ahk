#Requires AutoHotkey v2.0

; TODO Figure out how to send a singl AltGr as a compose key
; TODO CabsLock on both space
; TODO Make all of this work properly with an american keyboard layout
; TODO Shift hand postion over by one place

Tab::Tab
Tab & h::Left
Tab & j::Down
Tab & k::Up
Tab & l::Right
Tab & ö::PgDn
Tab & p::PgUp
Tab & u::Home
Tab & o::End
Tab & q::LShift
Tab & w::LControl
Tab & e::LAlt
; TODO figure out how to to make r and f act as mute but vol+/- individually
Tab & d::Volume_Mute
Tab & r::Volume_Up
Tab & f::Volume_Down

Space::Space
Space & q::@
Space & w::%
; €
; Space & r::^
Space & r::Send '{ASC 0094}'
; Space & t::~
Space & t::Send '{ASC 0126}'
Space & z::+
Space & u::/
Space & i::*
Space & o::-
Space & p::!
Space & a::Send '{LControl down}{RAlt down}7{RAlt up}{LControl up}' ; brace on german layout
Space & s::[
Space & d::]
Space & f::Send '{LControl down}{RAlt down}0{RAlt up}{LControl up}' ; brace on german layout
; Space & g::\
Space & g::Send '{LControl down}{RAlt down}ß{RAlt up}{LControl up}' ; backslash avoids triggering wincompose
Space & h::=
; Space & j::|
Space & j::Send '{ASC 0124}' ; pipe that avoids triggering wincompose
Space & k::_
Space & l::?
Space & y::&
Space & x::$
Space & c::(
Space & v::)
Space & b::#
; ñ
; greek
Space & ,::<
Space & .::>
Space & y::&
; Problem space and Tab stop working

; LControl::LWin
; LWin::LAlt  ; turnes out it's questionably useful to to do this because Win+L is always treated as special so you cannot repap it at all so you end up constantly looking your computer by accident.
; LAlt::RAlt

!n::0
!m::1
!,::2
!.::3
!j::4
!k::5
!l::6
!u::7
!i::8
!o::9


; <^>!a::'
; <^>!s::"
; <^>!d::´
; <^>!f::`

; Cabslock ist Vim key (Esc on press and Ctrl on combo)
; See here: https://gist.github.com/ulic-youthlic/c8efd1d8cd5c59559403ded7e5b44833

; Install the keyboard hook to capture the real key state of the keyboard
InstallKeybdHook(true)
; Disable the CapsLock key
SetCapsLockState("alwaysoff")
; Send esc key when Capslock is pressed as default
g_DoNotAbortSendEsc := true

$*Capslock::{ ; Capture CapsLock key press
  global g_DoNotAbortSendEsc ; use global variable g_DoNotAbortSendEsc
  g_DoNotAbortSendEsc := true ; set g_DoNotAbortSendEsc to true
  Send("{LControl Down}") ; send Ctrl key down
  KeyWait("CapsLock") ; capture CapsLock key up
  Send("{LControl Up}") ; send Ctrl key up
  if (A_PriorKey == "CapsLock" ; if the last key is Capslock
     && g_DoNotAbortSendEsc) { ; if the g_DoNotAbortSendEsc is true
    Send("{Esc}") ; send Esc key
  }
  return
}

; capture any key with Ctrl key down
~^*a:: ; * means can be used with any modifier key, ~ means donot block the original key, ^ means Ctrl key, a means the key is a
~^*b::
~^*c::
~^*d::
~^*e::
~^*f::
~^*g::
~^*h::
~^*i::
~^*j::
~^*k::
~^*l::
~^*m::
~^*n::
~^*o::
~^*p::
~^*q::
~^*r::
~^*s::
~^*t::
~^*u::
~^*v::
~^*w::
~^*x::
~^*y::
~^*z::
~^*1::
~^*2::
~^*3::
~^*4::
~^*5::
~^*6::
~^*7::
~^*8::
~^*9::
~^*0::
~^*Space::
~^*Backspace::
~^*Delete::
~^*Insert::
~^*Home::
~^*End::
~^*PgUp::
~^*PgDn::
~^*Tab::
~^*Enter::
~^*,::
~^*.::
~^*/::
~^*;::
~^*'::
~^*[::
~^*]::
~^*\::
~^*-::
~^*=::
~^*`::
~^*F1::
~^*F2::
~^*F3::
~^*F4::
~^*F5::
~^*F6::
~^*F7::
~^*F8::
~^*F9::
~^*F10::
~^*F11::
~^*F12::{
  global g_DoNotAbortSendEsc
  g_DoNotAbortSendEsc := false
}