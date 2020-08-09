;-
(require [mino.mu [*]]
         [mino.thread [*]]
         [mino.spec [*]]
         [hy.contrib.walk [let]])

;-
(import os)

;- Static Globals
(setv LEDGER-PATH "data/ledger.csv")

;--
(defn read-spoken []
  (with [f (open "data/spoken.txt" "r")]
    (.strip (f.read))))

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
