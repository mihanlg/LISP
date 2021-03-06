;;;Вариант "Построение конечного автомата по грамматике" - Постников М. М. 325 группа, весенний семестр, 2016г.

;;Возвращает часть списка до первого разделителя, либо весь список
(defun firstof (str sep)
  (cond ((null str) ())
        ((let ((sym (car str)) (tail (cdr str)))
           (cond ((eql sym sep) ())
                 ((cons sym (firstof tail sep))))
           )
        )
  )
)

;;Возвращает часть списка после первого разделителя, либо  пустой список
(defun tailof (str sep)
  (cond ((null str) ())
        ((let ((sym (car str)) (tail (cdr str)))
           (cond ((eql sym sep) tail)
                 ((tailof tail sep))
                 )
           )
         )
        )
  )

;;Делит список по разделителю
(defun divideby (str sep)
  (cond ((null str) ())
        ((cons (firstof str sep) (divideby (tailof str sep) sep)))
        )
  )

;;Модифицировать входной список (разделить по символу ;)
(defun modrg (input) input
  (cond ((null input) ())
        ((divideby input #\;))
        )
  )

;;Вставка симовла в начало каждого списка из списка
(defun mapinsert(sym elements)
  (cond ((null elements) ())
        ((cons (cons sym (car elements)) (mapinsert sym (cdr elements))))
        )
  )

;;Добавление конечного состояния S в грамматику
(defun checkFinal (alts)
  (cond ((null alts) ())
        ((null (cdar alts)) (cons (cons (caar alts) (list #\S)) (checkFinal (cdr alts))))
        ((cons (car alts) (checkFinal (cdr alts))))
        )
  )

;;;Преобразование правила грамматики в автоматную запись
(defun ruletoa (rule)
  (let ((pos (car rule)) (alts (checkFinal (divideby (cddr rule) #\|))))
    (mapinsert pos alts)
    )
  )

;;Преобразование регулярной грамматики в НКА
(defun rgtonka (rg)
  (cond ((null rg) ())
        ((append (ruletoa (car rg)) (rgtonka (cdr rg))))
        )
  )

;;Получить i-тый элемент списка
(defun geti (elements pos)
  (cond ((= pos 0) (car elements))
        ((geti (cdr elements) (- pos 1)))
        )
  )

;;Получить список из i-тых элементов списков списка
(defun cut (elements pos)
  (cond ((null elements) ())
        ((cons (geti (car elements) pos) (cut (cdr elements) pos)))
        )
  )

;;Составление множества из входящих в список символов
(defun unique (elements uset)
  (cond ((null elements) uset)
        ((member (car elements) uset) (unique (cdr elements) uset))
        ((unique (cdr elements) (cons (car elements) uset)))
        )
  )

;;Предикат - является ли список1 подсписком списка2
(defun memberlist (list1 list2)
  (cond ((null list1) T)
        ((member (car list1) list2) (memberlist (cdr list1) list2))
        (nil)
        )
  )

;;Проверка состояний автомата на эквивалентность
(defun eqState (state1 state2)
  (and (memberlist state1 state2) (memberlist state2 state1))
  )

;;Предикат - входит ли текущее состояние в множество уже обработанных
(defun inProcessed (processed current)
  (cond ((null processed) nil)
        ((eqState (caar processed) current) T)
        ((inProcessed (cdr processed) current))
        )
  )

;;Добавление, если необходимо, текущего состояния в множество обработанных
(defun toProcessed (processed current)
  (cond ((inProcessed processed current) processed)
        ((cons (list current (length processed)) processed))
        )
  )

;;Получить состояние автомата при переходе по символу
(defun getState (nka state letter)
  (cond ((null nka) ())
        ((let ((transition (car nka)))
           (cond ((and (eql (car transition) state) (eql (cadr transition) letter))
                  (cons (caddr transition) (getState (cdr nka) state letter)))
                 ((getState (cdr nka) state letter))
                 )
           )
         )
        )
  )

;;Объединение множеств (без повторения)
(defun join (state1 state2)
  (cond ((null state1) state2)
        ((member (car state1) state2) (join (cdr state1) state2))
        ((cons (car state1) (join (cdr state1) state2)))
        )
  )

;;Предикат - входит ли текущее состояние в множество уже обработанных
(defun memberQueue (queue current)
  (cond ((null queue) nil)
        ((eqState (car queue) current) T)
        ((memberQueue (cdr queue) current))
        )
  )

;;Объединение очередей (без повторения)
(defun joinQueue (queue1 queue2)
  (cond ((null queue1) queue2)
        ((memberQueue queue2 (car queue1)) (joinQueue (cdr queue1) queue2))
        ((cons (car queue1) (joinQueue (cdr queue1) queue2)))
        )
  )

;;;Получить частичные переходы по автомату для текущего состояния
(defun getTransitions (nka current alphabet)
  (cond ((or (null current) (null alphabet)) ()) ;;пустой алфавит или состояние
        ;;если рассматриваем алфавит, а не конечный символ, то запускаем рекурсию по буквам
        ((cond ((listp alphabet) (let ((transition (getTransitions nka current (car alphabet))))
                                   (cond ((null transition) (getTransitions nka current (cdr alphabet)))
                                         ((cons (list (car alphabet) transition) (getTransitions nka current (cdr alphabet))))
                                   )))    
               ;;если символ, то составляем для него множество состояний, в которые мы можем попасть, при переходе из текущего
               ((let ((state (getState nka (car current) alphabet)))
                  (cond ((null state) (getTransitions nka (cdr current) alphabet))
                        ((join state (getTransitions nka (cdr current) alphabet)))
                        )
                  ))
               ))
        )
  )

;;Составление автоматных переходов для текущего состояния по частичным переходам
(defun constructTransitions (current newTransitions)
  (cond ((null newTransitions) ())
        ((cons (cons current (car newTransitions)) (constructTransitions current (cdr newTransitions))))
        )
  )
 
;;Добавление в очередь новых, еще не просмотренных, состояний
(defun getQueue (newProcessed newTransitions)
  (cond ((null newTransitions) ())
        ((let ((state (cadar newTransitions)))
           (cond ((inProcessed newProcessed state) (getQueue newProcessed (cdr newTransitions)))
                 ((cons state (getQueue newProcessed (cdr newTransitions))))
                 )
           ))
        )
  )

;;;Добавление в ДКА правила перехода в конечное состояние по epsilon, если в НКА было несколько конечных состояний
(defun checkFinalState (dka current)
  (cond ((eqState (list #\S) current) dka)
        ((member #\S current) (append dka (list (list current #\~ (list #\S)))))
        (dka)
        )
  )

;;;Алгоритмически основная функция, в которой происходит извлечение состояния из очереди, обработка, составление ДКА из НКА
(defun process (nka dka processed queue alphabet)
  (cond ((null queue) (list dka processed))
        ((let* ((current (car queue))
                (newProcessed (toProcessed processed current))
                (newTransitions (getTransitions nka current alphabet))
                (newQueue (joinQueue (cdr queue) (getQueue newProcessed newTransitions))))
           (process nka
                    (checkFinalState (append dka (constructTransitions current newTransitions)) current)
                    newProcessed
                    newQueue
                    alphabet
                    )
           ))
        )
  )

;;Получение номера состояния (порядкового)
(defun getStateId (state processed)
  (cond ((null processed) -1)
        ((eqState (caar processed) state) (cadar processed))
        ((getStateId state (cdr processed)))
        )
  )

;;;Создание нового названия для состояния
(defun createName (state processed)
  (cond ((eqState state (list #\S)) state)
        ((= (getStateId state processed) 0) (list #\H))
        ((cons #\Q (coerce (write-to-string (getStateId state processed)) 'list)))
        )
  )

;;Переименование состояний и приведение переходов к строковому формату
(defun renameState (state1 letter state2 processed)
  (coerce (append (append (createName state1 processed) (list #\  letter #\ ) (createName state2 processed))) 'string)
  )

;;;Переименование состояний ДКА
(defun renameStates (dka processed)
  (cond ((null dka) ())
        ((let* ((transition (car dka))
                (state1 (car transition))
                (letter (cadr transition))
                (state2 (caddr transition)))
           (cons (renameState state1 letter state2 processed) (renameStates (cdr dka) processed))
           ))
        )
  )

;;;Построение ДКА из НКА и переименование состояний
(defun nkatodka (nka)
  (cond ((null nka) ())
        ((let* ((alphabet (reverse (unique (cut nka 1) ())))
                (automat (process nka () () (list (list (caar nka))) alphabet)))
           (renameStates (car automat) (cadr automat))
           ))
        )
  )

;;;Основная функция для запуска алгоритма, приглашение для ввода, вывод
(defun main ()
  (print "Input: ")
  (let ((input (read)))
    (print "Output: ")
    (nkatodka (rgtonka (modrg (coerce input 'list))))))
