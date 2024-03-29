%%% def_class : utilizzato per la definizione di una classe

%%% def_class senza Parents e senza Slots

def_class(Name, [], []) :-
    atom(Name),
    NewClass =.. [class, Name, [], []],
    salvaClasse(NewClass),
    !.


%%% def_class senza Parents e con Slots

def_class(Name, [], Slots) :-
    atom(Name),
    controlla_slot_values(Slots),
    NewClass =.. [class, Name, [], Slots],
    salvaClasse(NewClass),
    !.


%%% def_class con Parents e senza Slots

def_class(Name, Parents, []) :-
    atom(Name),
    Class =.. [class, Name, Parents, []],
    is_list(Parents),
    controlla_parents(Parents),
    salvaClasse(Class),
    !.


%%% def_class con Parents e con Slots

def_class(Name, Parents, Slots) :-
    atom(Name),
    controlla_slot_values(Slots),
    Class =.. [class, Name, Parents, Slots],
    controlla_parents(Parents),
    salvaClasse(Class),
    !.


%%% salvaClasse : utilizzato per il savataggio della classe

%% se la classe esiste già non la salvo ancora
%% NB: in questo modo non si può sovrascrivere una classe

salvaClasse(Class) :-
    Class,
    !.


%% se la classe non esiste la salvo

salvaClasse(Class) :-
    not(Class),
    !,
    assert(Class).

%%% Caso base di class

class(default, [], []).


%%% controlla_parents : Controlla che esistano tutte le classi Parents

controlla_parents([]).

controlla_parents([Parent | Others]) :-
    atom(Parent),
    Class2 =.. [class, Parent, _, _],
    Class2,
    controlla_parents(Others).


%%% controlla_slot_values: controlla la conformità degli slot passati

controlla_slot_values([]).


controlla_slot_values([SlotValue | Others]) :-
    term_string(SlotValue, String),
    split_string(String, "=", " ", List),
    nth0(0, List, SlotTemp),
    not(sub_string(SlotTemp, _, _, _, "(")),
    nth0(1, List, ValueTemp),
    controlla_values(ValueTemp),
    controlla_slot_values(Others).


%% Viene controllato che non ci sia nessuna parentesi tonda aperta = nessun
%% metodo

controlla_values(ValueString) :-
    not(sub_string(ValueString, _, _, _, "(")),
    !.


%% Nel caso ci sia un method

controlla_values(ValueString) :-
    sub_string(ValueString, 0, _, _, "method("),
    !,
    term_string(ValueTerm, ValueString),
    ValueTerm =.. [method, ArgList, Form],
    is_list(ArgList),
    compound(Form),
    not(is_list(Form)).


%%% New e metodi utili al suo funzionamento

%%% new : definisce una nuova istanza (new/3:considera la modifica di
%%% Slots)

new(Istance, Class, Slots):-
    class(Class, ParentsList, PSlots),
    slots_to_list(PSlots, [], ParentsSlots),
    slots_to_list(Slots, [], PromptList),
    eredita(Class,ParentsList, SlotsDef),
    unisci(SlotsDef, ParentsSlots, Res),
    get_name_list(Res,[], ResNameList),
    get_name_list(PromptList,[], PromptNameList),
    check_slots(ResNameList, PromptNameList),
    unisci(Res, PromptList, Lista),
    list_to_slots(Lista, [], Def),
    sostituisci_this(Istance,Def,ResDef),
    NewIstance =.. [istanza, Istance, Class, ResDef],
    salvaIstanza(NewIstance),
    !.


%%% new : definisce una nuova istanza (new/2: senza passaggio di Slots)

new(Istance, Class):-
    class(Class, ParentsList, PSlots),
    slots_to_list(PSlots, [], ParentsSlots),
    eredita(Class,ParentsList, SlotsDef),
    unisci(SlotsDef, ParentsSlots, Res),
    list_to_slots(Res, [], Def),
    sostituisci_this(Istance,Def,ResDef),
    NewIstance =.. [istanza, Istance, Class, ResDef],
    salvaIstanza(NewIstance),
    !.

%%% se l'istanza esiste non la salvo

salvaIstanza(Istanza) :-
    Istanza,
    !.


%%% se l'istanza non esiste la salvo

salvaIstanza(Istanza) :-
    not(Istanza),
    !,
    assert(Istanza).


istanza(defaultIstanza, default, []).


%%% sostituisci_this:se prensente un method, trova e sostituisce this
%%% con il nome dell'istanza

sostituisci_this(_,[],[]).


sostituisci_this(Istanza,[SlotValue | Others],Res) :-
    term_string(SlotValue, String),
    split_string(String, "=", " ", List),
    nth0(0, List, SlotTemp),
    not(sub_string(SlotTemp, _, _, _, "(")),
    nth0(1, List, ValueTemp),
    ciclo_find_this(Istanza, ValueTemp,Res2Tmp),
    string_concat(SlotTemp, "=", StringTmp),
    string_concat(StringTmp, Res2Tmp, StringDef),
    term_string(Res2, StringDef),
    term_string(CorpoMetodo, Res2Tmp),
    asserisci_method(Istanza, SlotTemp, ValueTemp, CorpoMetodo),
    sostituisci_this(Istanza,Others,Res1),
    append([Res2],Res1, Res).


%%% ciclo_find_this:individuato un metodo, questa funzione ne cerca la
%%% presenza di un "this" al suo interno

ciclo_find_this(_, ValueString, ValueString):-
    not(sub_string(ValueString, _, _, _, "this")),
    !.


ciclo_find_this(Istanza, ValueString, Res):-
    sub_string(ValueString, _, _, _, "this"),
    !,
    trova_this(Istanza, ValueString,Res2Tmp),
    ciclo_find_this(Istanza, Res2Tmp, Res).


trova_this(_, Stringa, Stringa) :-
    not(sub_string(Stringa, _, _, _, "this")),
    !.


trova_this(Istanza, Stringa, Res) :-
    sub_string(Stringa, PrimaThis, _, DopoThis, "this"),
    !,
    sub_string(Stringa, 0, PrimaThis, _, Sub1),
    sub_string(Stringa, _, DopoThis, 0, Sub2),
    atom_string(Istanza, IstanzaStringa),
    string_concat(Sub1, IstanzaStringa, Concat1),
    string_concat(Concat1, Sub2, Res).


%%% asserisci_method:se individuato un metodo, lo asserisce

asserisci_method(_, _, ValueString,_):-
    not(sub_string(ValueString, 0, _, _, "method(")),
    !.


asserisci_method(Istanza, SlotString, ValueString, Res):-
    sub_string(ValueString, 0, _, _, "method("),
    !,
    atom_string(AtomValue,SlotString),
    Metodo1 =.. [AtomValue, Istanza],
    Metodo2 =.. [AtomValue, Istanza, Arglist],
    Res =.. [method, Arglist, Operations],
    assert((Metodo1 :- call(Metodo2))),
    assert((Metodo2 :- call(Operations))).


%%% Caso base di method

method(_,_).


%%% get_name_list: Estrae una lista contenete i soli nomi delle
%%% variabili

get_name_list([], X, X).


get_name_list([Slot|Slots], Value, Rest):-
    nth0(0, Slot, Name),
    get_name_list(Slots, [Name|Value], Rest),
    !.


%%% check_slots:Controlla che i valori inizializati alla definizione del
%%% new esistano nelle classi usate

check_slots(_, []).


check_slots(EredNames, [Name|PromptNames]):-
    member(Name, EredNames),
    check_slots(EredNames, PromptNames).


%%% eredita: Utilizzata per applicare il principio di eredità dell' OOP

eredita(_,[], _).


eredita(Class, [Parent1,Parent2 | Others], Res) :-
    length([Parent1,Parent2 | Others], X),
    X >= 2,
    !,
    class(Parent1, _, Slots1),
    class(Parent2, _, Slots2),
    slots_to_list(Slots1, [], Tmp1),
    slots_to_list(Slots2, [], Tmp2),
    unisci(Tmp2, Tmp1, Res2),
    eredita(Class, Others, Res1),
    unisci(Res1, Res2, Res).


eredita(Class, [Parent], Res) :-
    length([Parent], X),
    X == 1,
    !,
    class(Parent, _, Slots1),
    class(Class, _, Slots2),
    slots_to_list(Slots1, [], Tmp1),
    slots_to_list(Slots2, [], Tmp2),
    unisci(Tmp1, Tmp2, Res).


%%% unisci : accetta due liste di coppie(liste), e applica il principio
%%% di ereditarietà

%% Casi base

unisci([], [], []) :-
    !.


unisci(List, [], List) :-
    !.


unisci([], List, List) :-
    !.


%% Caso ricorsivo

unisci([X | X1], [Y | Y1], Z) :-
    unisci1([X | X1], [Y | Y1], Z1),
    !,
    unisci2([Y | Y1], [X | X1], Z2),
    !,
    append(Z1, Z2, Z).


%% unisci1 e unisci2 sono funzioni ausiliare di appoggio a unisci
%% controllano la presenza dello slot negli Slots

unisci1([], [], []) :-
    !.


unisci1(_, [], []) :-
    !.


unisci1([], _, []) :-
    !.


unisci1([X | X1], [Y | Y1], [[NomeX, Z] | Z1]) :-
    nth0(0, X, NomeX),
    member([NomeX, Z], [Y | Y1]),
    !,
    unisci1(X1, [Y | Y1], Z1).


unisci1([X | X1], [Y | Y1], [[NomeX, Nome2X] | Z1]) :-
    nth0(0, X, NomeX),
    nth0(1, X, Nome2X),
    not(member([NomeX, _], [Y | Y1])),
    !,
    unisci1(X1, [Y | Y1], Z1).


unisci2([], [], []) :-
    !.


unisci2(_, [], []) :-
    !.


unisci2([], _, []) :-
    !.


unisci2([X | X1], [Y | Y1], Z1) :-
    nth0(0, X, NomeX),
    member([NomeX, _], [Y | Y1]),
    !,
    unisci2(X1, [Y | Y1], Z1).


unisci2([X | X1], [Y | Y1], [[NomeX, Nome2X] | Z1]) :-
    nth0(0, X, NomeX),
    nth0(1, X, Nome2X),
    not(member([NomeX, _], [Y | Y1])),
    !,
    unisci2(X1, [Y | Y1], Z1).


%%% Metodo utilizzato per la conversione da Slot a semplice Lista,
%%% esempio: [nome='Ciao'] --> [nome, 'Ciao']

slots_to_list([],X,X).


slots_to_list([Slot|Slots], TmpList, Rest):-
    term_string(Slot, String),
    split_string(String, "=", " ", List),
    nth0(0, List, SlotTmp),
    term_string(SlotTerm, SlotTmp),
    nth0(1, List, ValueTmp),
    term_string(ValueTerm, ValueTmp),
    slots_to_list(Slots, [[SlotTerm, ValueTerm]|TmpList], Rest).


%%% Metodo utilizzato per la conversione da semplice Lista a Slot
%%% esempio: [nome,'Ciao'] --> [nome='Ciao']

list_to_slots([], X, X).


list_to_slots([Slot|Slots], TmpList, Rest):-
    nth0(0, Slot, SlotTmp),
    nth0(1, Slot, ValueTmp),
    term_to_atom(SlotTmp, SlotAtom),
    term_to_atom(ValueTmp, ValueAtom),
    atom_concat(SlotAtom, ' = ', RTmp),
    atom_concat(RTmp, ValueAtom, R),
    term_to_atom(Term , R),
    list_to_slots(Slots, [Term|TmpList], Rest).


%%% getv, dato un nome di variabile e un istanza, restituisce il
%%% valore della variabile

getv(Instance, SlotName, Result) :-
    istanza(Instance, _, Slots),
    slots_to_list(Slots, [], ListaSlots),
    member([SlotName, Result], ListaSlots),
    !.


%%% getvx: data un istanza e una lista di valori conteneti altre
%%% istanze restituisce il valore dell'ultima variabile della lista

getvx(Instance, [Lista], Res) :-
    length([Lista], 1),
    !,
    getv(Instance, Lista, Res).


getvx(Instance, [Name | SlotName], Res) :-
    length([Name | SlotName], X),
    X > 1,
    !,
    getv(Instance, Name, Res2),
    getvx(Res2, SlotName, Res).
