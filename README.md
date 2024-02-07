# OOP_Prolog
Costruzione di un'estensione "object oriented" di Prolog scritta in linguaggio Prolog.
Definizione di 4 primitive: def_class, new, getv e getvx.

  1) il predicato define class definisce la struttura di una classe e la memorizza nella “base di conoscenza” di Prolog.
      def_class ( <class-name>, <parents>, <slot-values> )
          dove <parents> è una lista (possibilmente vuota) di atomi (simboli), e <slot-values> è una lista di termini <slot-value>
      
  2) new: crea una nuova istanza di una classe.
      new ( <instance-name>, <class-name>, [ [ <slot-name> = <value> [ , <slot-name> = <value> ]* ]* ] )
          dove <instance-name>, <class-name> e <slot-name> sono simboli, mentre <value> `e un qualunque termine Prolog, incluso un “metodo”.

  3) getv: estrae il valore di un campo da una classe.
      getv ( <instance>, <slot-name>, <result> )
          dove <instance> è un’istanza di una classe (nel caso più semplice un simbolo) e <slot-name> è un simbolo. Il valore recuperato viene unificato con <result> ed è il valore associato a <slot-name> nell’istanza (tale valore potrebbe anche essere ereditato dalla classe o da uno dei suoi antenati). Se <slot-name> non esiste               nella classe dell’istanza il predicato fallisce.

  4) getvx: estrae il valore da una classe percorrendo una catena di attributi.
      getvx ( <instance>, <slot-names>, <result> )
          dove <instance> è un’istanza di una classe (nel caso più semplice un simbolo) e <slot-namea> è una lista non vuota di simboli, che rappresentano attributi nei vari oggetti recuperati. Il valore recuperato viene unificato con <result> ed è il valore associato all’ultimo elemento di <slot-names> nell’ultima istanza (tale               valore potrebbe anche essere ereditato dalla classe o da uno dei suoi antenati). Se uno degli elementi di <slot-names> non esiste nella classe dell’istanza il predicato fallisce.
