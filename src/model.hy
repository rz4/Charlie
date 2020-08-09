;-
(require [mino.mu [*]]
         [mino.thread [*]]
         [mino.spec [*]]
         [hy.contrib.walk [let]])

;-
(import os torch
        [time [time]]
        [pandas :as pd]
        [numpy :as np]
        [torch.utils.data [DataLoader]])

(import torch
        [torch.nn :as nn]
        [torch.nn.functional :as F]
        [transformers [BertConfig BertForMaskedLM AdamW]])

;- Static Globals
(setv LEDGER-PATH "data/ledger.csv"
      VOCAB-PATH "data/vocab.csv"
      MODEL-PATH "data/model.pt")

;--
(defn read-ledger []
  (if (os.path.exists LEDGER-PATH)
      (setv df (pd.read-csv LEDGER-PATH :header None)
            df.columns (, 'self? 'command 'text))
      (setv df (pd.DataFrame [] :columns (, 'self? 'command 'text))))
  df)

;--
(defn read-vocab []
  (if (os.path.exists VOCAB-PATH)
      (pd.read-csv VOCAB-PATH)
      (pd.DataFrame [[0 "[START]"] [1 "[END]"] [2 "[MASK]"] [3 "[UNKOWN]"] [4 "[PAD]"]]
                    :columns (, 'TID 'TOKEN))))

;--
(defn tokenizer [vocab &optional [size None] [detokenize? False]]
  (let [lookup (if detokenize?
                 (dfor (, i row) (.iterrows vocab) [(get row 'TID) (get row 'TOKEN)])
                 (dfor (, i row) (.iterrows vocab) [(get row 'TOKEN) (get row 'TID)]))]
    (fn [x]
     (let [split (if detokenize? x (.split x))]
       (setv tokens (lfor i (range (len split)) (let [token (get split i)]
                                                  (if (in token lookup) (get lookup token) 3))))
       (when (and size (< (len split) size))
         (+= tokens (lfor i (range (- size (len split))) 4)))
       (if detokenize? (.join " ") (np.array tokens))))))

;--
(defn mask-input [x &optional [nb-tokens None] [mask-percent 0.5] [indices None]]
  (let [size (.size x)
        masked-tensor (.long (.clone x))
        boolean-mask (torch.zeros size)]
    (let [nb-tokens (if nb-tokens nb-tokens (get size 1))
          inds (if indices
                   indices
                   (np.random.choice nb-tokens (int (* nb-tokens mask-percent)) :replace False))]
      (setv (get masked-tensor (, inds)) 2
            (get boolean-mask (, inds)) 1)
      (, masked-tensor (.bool boolean-mask)))))

;--
(defn model-input [tokens-input &optional [size None] [masked? False]]
  (fn [x]
    (let [tokens (tokens-input x)
          nb-tokens (len (.split x))
          attens (np.ones (, nb-tokens))
          attens (if (and size (< (len attens) size))
                     (np.pad attens (, 0 (- size (len attens))))
                     attens)
          tokens (.astype tokens "int")
          attens (.astype attens "int")]
      (if masked?
        (do (setv (, masked-tokens mask-bool) (mask-input (torch.Tensor tokens) nb-tokens))
            [tokens attens masked-tokens mask-bool])
        [tokens attens]))))


;--
(defn load-model [vocab-size tokens-size &optional [file None]]
  (let [model (BertForMaskedLM (BertConfig :vocab-size vocab-size
                                           :hidden-state 128
                                           :num-hidden-layers 4
                                           :num-attention-heads 4
                                           :intermediate-size 128
                                           :max-position-embeddings tokens-size
                                           :pad-token-id 3))]
    (when file (-> (torch.load file)
                   (->> (.load-state-dict model))))
    (.eval model)))

;--
(defmain [args]

  ;- Load Data and Model
  (let [ledger (read-ledger)
        vocab (read-vocab)]

    ;- Expand Vocabulary
    (let [terms (-> ledger (get 'text) (. str) .split .explode .unique list)
          new-terms (flatten (lfor t terms (if (.sum (= vocab.TOKEN t)) [] t)))
          maxid (.max vocab.TID)]
      (for [i (range (len new-terms))]
        (setv vocab (.append vocab {'TID (+ maxid i 1) 'TOKEN (get new-terms i)}
                                   :ignore-index True)))
      (.to-csv vocab VOCAB-PATH :index False))

    ;- Create Dataset
    (setv dataset (mino/apply (.tolist ledger.text)
                    (model-input (tokenizer vocab :size 8) :size 8 :masked? True)))


    ;- Load Language Model
    (setv model (load-model (len vocab) 8 (if (os.path.exists MODEL-PATH) MODEL-PATH None))))

  ;- Train Language Model
  (let [epochs 10 batch-size 4
        dataloader (DataLoader dataset :batch-size batch-size :shuffle True)
        optimizer (AdamW (.parameters model) :lr 2e-5 :correct_bias False)
        device "cpu"]

    (setv model (.to (.train model) device))
    (for [e (range epochs)]
      (for [(, i batch) (enumerate dataloader)]
        (setv (, labels attens inputs mask) (lfor b batch (.to b device))
              (, loss logits) (model :input_ids inputs :attention_mask attens :labels labels)
              vals (- (get labels mask) (get (torch.argmax logits -1) mask))
              vals (- 1 (torch.clamp (torch.abs vals) 0 1))
              acc (/ (.sum vals) (.sum (.float mask))))
        (.zero_grad model)
        (.zero_grad optimizer)
        (.backward loss)
        (torch.nn.utils.clip_grad_norm_ (.parameters model) 1)
        (.step optimizer)
        (print (.format "Epoch {}: Batch {} of {}: [Loss: {}; Acc: {}]"
                 e
                 i
                 (int (/ (len dataset) batch-size))
                 (-> loss .detach .cpu)
                 (-> acc .detach .cpu)))))
    (.eval model)

    (torch.save (.state-dict model) MODEL-PATH)))
