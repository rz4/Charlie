;
(require [minotauro.mu [*]]
         [minotauro.thread [*]]
         [minotauro.spec [*]]
         [hy.contrib.walk [let]])

;-
(defn read-spoken [] (with [f (open "data/spoken.txt" "r")] (f.read)))

;-
(defn respond [command speak]
  (print (.format "{command},{speak}" :command command :speak speak)))

;-
(defmain [args]

  ;--
  (let [command 0
        response (read-spoken)]
    (respond command speak)))
