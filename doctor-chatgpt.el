;;; doctor-chatgpt.el --- chatGPT mode -*- lexical-binding: t; -*-

;;; Commentary:

;; https://emacs-china.org/t/chatgpt-emacs-doctor/23773

;;; Code:

(require 'markdown-mode)

(defvar doctor-chatgpt-buffer-name "*doctor-chatgpt*")
(defvar doctor-chatgpt-process-buffer-name "*doctor-chatgpt-process*")
(defvar doctor-chatgpt-process nil)
(defvar doctor-chatgpt-cmd "C:/Users/zhijia.zhang/chatgpt.exe")
(defvar doctor-chatgpt-replying nil)
(defvar doctor-chatgpt-ready nil)
(defvar doctor-chatgpt-recv-list nil)
(defvar doctor-chatgpt-send-list nil)


(defun doctor-chatgpt-filter (process output)
  "Filter for chatgpt process."
  (message "doctor-chatgpt-filter: %s" output)
  (let ((buffer (process-buffer process)))
    (cond
     ((string-match "输入你的问题):" output)
      (setq doctor-chatgpt-ready t))
     ((not doctor-chatgpt-ready))
     ((equal output "输入你的问题):")
      (setq doctor-chatgpt-replying t)
      (with-current-buffer doctor-chatgpt-buffer-name (read-only-mode 1)))
     (t
      (when-let* ((el (string-match "输入你的问题):$" output)))
        (setq doctor-chatgpt-replying nil)
        (setq output (substring output 0 el)))
      (when (> (length output) 1) (push output doctor-chatgpt-recv-list))
      (with-current-buffer doctor-chatgpt-buffer-name
        (read-only-mode -1)
        (goto-char (point-max))
        ;; HACK: don't know why it will repeat the first send, so remove it
        (insert
         (if (eq (length doctor-chatgpt-recv-list) 1)
             (string-replace (string-trim (nth 0 doctor-chatgpt-send-list)) "" output)
           output))
        (if doctor-chatgpt-replying
            (read-only-mode 1)
          ;; (if doctor-chatgpt-recv-list (insert "\n"))
          ))))))

(defun doctor-chatgpt-start-process ()
  "Start a chat with ChatGPT."
  (when (and (processp doctor-chatgpt-process)
             (process-live-p doctor-chatgpt-process))
    (kill-process doctor-chatgpt-process))
  (setq doctor-chatgpt-recv-list nil)
  (setq doctor-chatgpt-send-list nil)

  (setq doctor-chatgpt-process
        (start-process
         doctor-chatgpt-process-buffer-name
         doctor-chatgpt-process-buffer-name
         doctor-chatgpt-cmd
         ))
  (setq doctor-chatgpt-ready nil)
  (set-process-sentinel doctor-chatgpt-process #'doctor-chatgpt-process-sentinel)
  (set-process-filter doctor-chatgpt-process #'doctor-chatgpt-filter))

(defun doctor-chatgpt-process-sentinel (process event)
  "Sentinel for chatgpt process.
PROCESS is the process that changed.
EVENT is a string describing the change."
  (setq doctor-chatgpt-ready nil)
  (message "%s end with the event '%s'" process event))

(defun doctor-chatgpt-ret-or-read (arg)
  "Insert a newline if preceding character is not a newline.
Otherwise call the Doctor to parse preceding sentence.
ARG will be passed to `newline'."
  (interactive "*p" doctor-chatgpt-mode)
  (if (= (preceding-char) ?\n)
      (doctor-chatgpt-read-print)
    (newline arg)))


(defun doctor-chatgpt-read-print ()
  "Top level loop."
  (interactive nil doctor-chatgpt-mode)
  ;; send the sentence before point
  (let ((doctor-sent
         (save-excursion
           (backward-sentence 1)
           (buffer-substring-no-properties (point) (point-max)))))
    (push doctor-sent doctor-chatgpt-send-list)
    (setq doctor-chatgpt-replying t)
    (process-send-string doctor-chatgpt-process (concat doctor-sent " ")
                         )))

(defvar-keymap doctor-chatgpt-mode-map
  "C-j" #'doctor-chatgpt-read-print
  "RET" #'doctor-chatgpt-ret-or-read)

(define-derived-mode doctor-chatgpt-mode gfm-mode "Doctor ChatGPT"
  "Major mode for running the ChatGPT.
Like Text mode with Auto Fill mode
except that RET when point is after a newline, or LFD at any time,
reads the sentence before point, and prints the ChatGPT's answer."
  :interactive nil
  (setq-local word-wrap-by-category t)
  ;; (visual-line-mode)
  (evil-normal-state)
  (evil-goto-line nil)
  (evil-open-below nil)
  (insert "\nHi. I'm chatGPT. ask me question...\n\n")
  (evil-insert-state 1)
  )

(defun doctor-chatgpt ()
  "Switch to `doctor-chatgpt-buffer' and start talking with ChatGPT."
  (interactive)
  (doctor-chatgpt-start-process)
  (switch-to-buffer doctor-chatgpt-buffer-name)
  (doctor-chatgpt-mode))

(provide 'doctor-chatgpt)

;; coding: utf-8
;; End:
;;; doctor-chatgpt.el ends here
