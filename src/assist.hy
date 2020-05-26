
(defn read-spoken [] (with [f (open "data/spoken.txt" "r")] (f.read)))

(defmain [args] (print (read-spoken)))
