## usage


```elisp

(use-package doctor-chatgpt
  :config
  :quelpa (doctor-chatgpt :fetcher git :url  "https://github.com/jiahut/doctor-chatgpt.el")
  :ensure t
  :config
  (general-define-key
    :prefix "SPC"
    :keymaps 'normal
    "oc"    'doctor-chatgpt
  )
  (general-define-key
   :prefix "SPC"
    :keymaps 'visual
   "oc" 'doctor-chatgpt-send-selected-text
  ))
```
