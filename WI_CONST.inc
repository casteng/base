  IK_ESCAPE          := 27;
  IK_1               :=Ord('1');
  IK_2               :=Ord('2');
  IK_3               :=Ord('3');
  IK_4               :=Ord('4');
  IK_5               :=Ord('5');
  IK_6               :=Ord('6');
  IK_7               :=Ord('7');
  IK_8               :=Ord('8');
  IK_9               :=Ord('9');
  IK_0               :=Ord('0');
  IK_MINUS           :=189;    (* - on main keyboard *)
  IK_EQUALS          :=187;
  IK_BACK            :=8;      (* backspace *)
  IK_TAB             :=9;
  IK_Q               :=Ord('Q');
  IK_W               :=Ord('W');
  IK_E               :=Ord('E');
  IK_R               :=Ord('R');
  IK_T               :=Ord('T');
  IK_Y               :=Ord('Y');
  IK_U               :=Ord('U');
  IK_I               :=Ord('I');
  IK_O               :=Ord('O');
  IK_P               :=Ord('P');
  IK_LBRACKET        :=219;
  IK_RBRACKET        :=221;
  IK_RETURN          :=13;     (* Enter on main keyboard *)
  IK_LCONTROL        :=162;
  IK_A               :=Ord('A');
  IK_S               :=Ord('S');
  IK_D               :=Ord('D');
  IK_F               :=Ord('F');
  IK_G               :=Ord('G');
  IK_H               :=Ord('H');
  IK_J               :=Ord('J');
  IK_K               :=Ord('K');
  IK_L               :=Ord('L');
  IK_SEMICOLON       :=186;
  IK_APOSTROPHE      :=222;
  IK_GRAVE           :=192; //$29;    (* accent grave *)
  IK_LSHIFT          :=160;
  IK_BACKSLASH       :=220;
  IK_Z               :=Ord('Z');
  IK_X               :=Ord('X');
  IK_C               :=Ord('C');
  IK_V               :=Ord('V');
  IK_B               :=Ord('B');
  IK_N               :=Ord('N');
  IK_M               :=Ord('M');
  IK_COMMA           :=188;
  IK_PERIOD          :=190;    (* . on main keyboard *)
  IK_SLASH           :=191;    (* / on main keyboard *)
  IK_RSHIFT          :=161;
  IK_MULTIPLY        :=106;    (* * on numeric keypad *)
  IK_LMENU           :=164;    (* left Alt *)
  IK_SPACE           :=32;
  IK_CAPITAL         :=20;
  IK_F1              :=112;
  IK_F2              :=113;
  IK_F3              :=114;
  IK_F4              :=115;
  IK_F5              :=116;
  IK_F6              :=117;
  IK_F7              :=118;
  IK_F8              :=119;
  IK_F9              :=120;
  IK_F10             :=121;
  IK_NUMLOCK         :=144;
  IK_SCROLL          :=145;    (* Scroll Lock *)
  IK_NUMPAD7         :=36;
  IK_NUMPAD8         :=38;
  IK_NUMPAD9         :=33;
  IK_SUBTRACT        :=109;    (* - on numeric keypad *)
  IK_NUMPAD4         :=37;
  IK_NUMPAD5         :=12;
  IK_NUMPAD6         :=39;
  IK_ADD             :=107;    (* + on numeric keypad *)
  IK_NUMPAD1         :=35;
  IK_NUMPAD2         :=40;
  IK_NUMPAD3         :=34;
  IK_NUMPAD0         :=45;
  IK_DECIMAL         :=46;     (* . on numeric keypad *)
  // $54 to $55 unassigned
  IK_OEM_102         :=$56;    (* < > | on UK/Germany keyboards *)
  IK_F11             :=122;
  IK_F12             :=123;
  // $59 to $63 unassigned
  IK_F13             :=$64;    (*                     (NEC PC98) *)
  IK_F14             :=$65;    (*                     (NEC PC98) *)
  IK_F15             :=$66;    (*                     (NEC PC98) *)
  // $67 to $6F unassigned
  IK_KANA            :=$70;    (* (Japanese keyboard)            *)
  IK_ABNT_C1         :=$73;    (* / ? on Portugese (Brazilian) keyboards *)
  // $74 to $78 unassigned
  IK_CONVERT         :=$79;    (* (Japanese keyboard)            *)
  // $7A unassigned
  IK_NOCONVERT       :=$7B;    (* (Japanese keyboard)            *)
  // $7C unassigned
  IK_YEN             :=$7D;    (* (Japanese keyboard)            *)
  IK_ABNT_C2         :=$7E;    (* Numpad . on Portugese (Brazilian) keyboards *)  
  // $7F to 8C unassigned
  IK_NUMPADEQUALS    :=13;     (* :=on numeric keypad (NEC PC98) *)
  // $8E to $8F unassigned
  IK_CIRCUMFLEX      :=$90;    (* (Japanese keyboard)            *)
  IK_AT              :=$91;    (*                     (NEC PC98) *)
  IK_COLON           :=$92;    (*                     (NEC PC98) *)
  IK_UNDERLINE       :=$93;    (*                     (NEC PC98) *)
  IK_KANJI           :=$94;    (* (Japanese keyboard)            *)
  IK_STOP            :=$95;    (*                     (NEC PC98) *)
  IK_AX              :=$96;    (*                     (Japan AX) *)
  IK_UNLABELED       :=$97;    (*                        (J3100) *)
  // $98 unassigned
  IK_NEXTTRACK       :=$99;    (* Next Track *)
  // $9A to $9D unassigned    
  IK_NUMPADENTER     :=13;     (* Enter on numeric keypad *)
  IK_RCONTROL        :=163;
  // $9E to $9F unassigned
  IK_MUTE            :=$A0;    (* Mute *)
  IK_CALCULATOR      :=$A1;    (* Calculator *)
  IK_PLAYPAUSE       :=$A2;    (* Play / Pause *)
  IK_MEDIASTOP       :=$A4;    (* Media Stop *)
  // $A5 to $AD unassigned  
  IK_VOLUMEDOWN      :=$AE;    (* Volume - *)
  // $AF unassigned  
  IK_VOLUMEUP        :=$B0;    (* Volume + *)
  // $B1 unassigned  
  IK_WEBHOME         :=$B2;    (* Web home *)
  IK_NUMPADCOMMA     :=$B3;    (* , on numeric keypad (NEC PC98) *)
  // $B4 unassigned
  IK_DIVIDE          :=111;    (* / on numeric keypad *)
  // $B6 unassigned
  IK_SYSRQ           :=$B7;
  IK_RMENU           :=165;    (* right Alt *)
  // $B9 to $C4 unassigned
  IK_PAUSE           :=19;     (* Pause (watch out - not realiable on some kbds) *)
  // $C6 unassigned
  IK_HOME            :=36;     (* Home on arrow keypad *)
  IK_UP              :=38;     (* UpArrow on arrow keypad *)
  IK_PRIOR           :=33;     (* PgUp on arrow keypad *)
  // $CA unassigned
  IK_LEFT            :=37;     (* LeftArrow on arrow keypad *)
  // $CC unassigned  
  IK_RIGHT           :=39;     (* RightArrow on arrow keypad *)
  // $CE unassigned
  IK_END             :=35;     (* End on arrow keypad *)
  IK_DOWN            :=40;     (* DownArrow on arrow keypad *)
  IK_NEXT            :=34;     (* PgDn on arrow keypad *)
  IK_INSERT          :=45;     (* Insert on arrow keypad *)
  IK_DELETE          :=46;     (* Delete on arrow keypad *)
  IK_LOS             :=91;     (* Left Windows key *)
  IK_ROS             :=92;     (* Right Windows key *)
  IK_APPS            :=93;     (* AppMenu key *)
  IK_POWER           :=$DE;
  IK_SLEEP           :=$DF;
  // $E0 to $E2 unassigned
  IK_WAKE            :=$E3;    (* System Wake *)
  // $E4 unassigned
  IK_WEBSEARCH       :=$E5;    (* Web Search *)
  IK_WEBFAVORITES    :=$E6;    (* Web Favorites *)
  IK_WEBREFRESH      :=$E7;    (* Web Refresh *)
  IK_WEBSTOP         :=$E8;    (* Web Stop *)
  IK_WEBFORWARD      :=$E9;    (* Web Forward *)
  IK_WEBBACK         :=$EA;    (* Web Back *)
  IK_MYCOMPUTER      :=$EB;    (* My Computer *)
  IK_MAIL            :=$EC;    (* Mail *)
  IK_MEDIASELECT     :=$ED;    (* Media Select *)


(*
 *  Alternate names for keys, to facilitate transition from DOS.
 *)
  IK_BACKSPACE      :=IK_BACK;      (* backspace *)
  IK_NUMPADSTAR     :=IK_MULTIPLY;  (* * on numeric keypad *)
  IK_LALT           :=IK_LMENU;     (* left Alt *)
  IK_CAPSLOCK       :=IK_CAPITAL;   (* CapsLock *)
  IK_NUMPADMINUS    :=IK_SUBTRACT;  (* - on numeric keypad *)
  IK_NUMPADPLUS     :=IK_ADD;       (* + on numeric keypad *)
  IK_NUMPADPERIOD   :=IK_DECIMAL;   (* . on numeric keypad *)
  IK_NUMPADSLASH    :=IK_DIVIDE;    (* / on numeric keypad *)
  IK_RALT           :=IK_RMENU;     (* right Alt *)
  IK_UPARROW        :=IK_UP;        (* UpArrow on arrow keypad *)
  IK_PGUP           :=IK_PRIOR;     (* PgUp on arrow keypad *)
  IK_LEFTARROW      :=IK_LEFT;      (* LeftArrow on arrow keypad *)
  IK_RIGHTARROW     :=IK_RIGHT;     (* RightArrow on arrow keypad *)
  IK_DOWNARROW      :=IK_DOWN;      (* DownArrow on arrow keypad *)
  IK_PGDN           :=IK_NEXT;      (* PgDn on arrow keypad *)

(*
 *  Alternate names for keys originally not used on US keyboards.
 *)

  IK_PREVTRACK      :=IK_CIRCUMFLEX;  (* Japanese keyboard *)

  IK_MOUSELEFT       :=$1;
  IK_MOUSERIGHT      :=$2;
  IK_MOUSEMIDDLE     :=$4;

  IK_SHIFT :=16;
  IK_CONTROL :=17;
  IK_ALT :=18;