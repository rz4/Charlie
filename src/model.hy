;-
(require [mino.mu [*]]
         [mino.thread [*]]
         [mino.spec [*]]
         [hy.contrib.walk [let]])

;-
(import os torch
        [pandas :as pd])

;- Static Globals
(setv LEDGER-PATH "data/ledger.csv"
      VOCAB-PATH "data/vocab.parquet")
    
;--
(defn read-ledger []
  (setv df (pd.read-csv LEDGER-PATH :header None)
        df.columns (, 'self? 'command 'text))
  df)

;--
(defmain [args]
         
  ;- Load Registry
  (let [df (read-ledger)]
    (print df))
  
  ;- Expand Vocabulary 
  
  ;- Load Language Model
  
  ;- Train Language Model
  
)