;-
(require [hy.contrib.walk [let]])

;-
(import os
        [pandas :as pd])

;- Static Globals
(setv LEDGER-PATH "data/ledger.csv")

;--
(defn read-spoken []
  (with [f (open "data/spoken.txt" "r")]
    (let [inputs (.split (.strip (f.read)) "\n")
          inputs1 (.split (first inputs) ",")
          inputs2 (.split (last inputs) ",")
          inputs (lfor i (range (len inputs)) [(get inputs1 i) (get inputs2 i)])
          df (pd.DataFrame inputs :columns ["Score" "Spoken"])]
      (get df "Spoken" (.argmax (.astype (get df "Score") "float"))))))

;--
(defn listen [self? text command]
  (with [ledger (open LEDGER-PATH "a")]
    (ledger.write
      (.format "{},{},{}\n"
        (if self? 0 1)
        command
        text))))

;--
(defn think [spoken]
  (let [speak (.format "You said : {}" spoken) ;; ADD Model
        command 0] ;; ADD Model
    (listen True speak command)
    (, command speak)))

;--
(defn respond [command reply]
  (print (.format "{command},{reply}"
           :command command
           :reply reply)))

;--
(defmain [args]

  ;- Add Spoken Dialogue to Database
  (let [spoken (read-spoken)]
    (listen False (read-spoken) 0)

    ;- Build Command and Reply
    (let [thought (think spoken)]
      (setv (, command reply) thought)
      (respond command reply))))
