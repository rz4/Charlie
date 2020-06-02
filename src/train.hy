;-
(require [mino.mu [*]]
         [mino.thread [*]]
         [mino.spec [*]]
         [hy.contrib.walk [let]])

;-
(import os
        [pandas :as pd])

;- Static Globals
(setv NB-ROWS 100
      LEDGER-PATH "data/ledger.parquet")

;-
(defn read-spoken []
  (with [f (open "data/spoken.txt" "r")]
    (cut (f.read) 0 -1)))

;-
(defn load-ledger []
  (assert (os.path.exists LEDGER-PATH) "")
  (pd.read-parquet LEDGER-PATH))

;-
(let [ledger (load-ledger)]
  (defn listen [self? text command]
    (setv ledger
      (.append ledger :ignore-index True
       {"id" (+ 1 (.max (get ledger "id")))
        "speaker_id" (if self? 0 1)
        "cmd_id" command
        "spoken_text" text}))
    (when (> (len ledger) NB-ROWS)
      (get (. ledger loc) (!= (get ledger "id") (.min (get ledger "id"))))
      (setv (get ledger "id") (- (get ledger "id") 1)))
    (.to-parquet ledger LEDGER-PATH :index False)))

;-
(defn think []
  (let [speak "I am thinking" ;; ADD Model
        command 0] ;; ADD Model
    (listen True speak command)
    (, command speak)))

;-
(defn respond [command reply]
  (print (.format "{command},{reply}"
           :command command
           :reply reply)))

;-
(defmain [args]

  ;-- Add Spoken Dialogue to Database
  (listen False (read-spoken) 0)

  ;-- Build Command and Reply
  (let [thought (think)]
    (setv (, command reply) thought)
    (respond command reply)))
