;;; p4-mode.el --- Support for the P4 programming language

;; Copyright (C) 2016- Barefoot Networks
;; Author: Vladimir Gurevich <vladimir.gurevich@barefootnetworks.com>
;; Maintainer: Vladimir Gurevich <vladimir.gurevich@barefootnetworks.com>
;; Created: 21 Jan 2016
;; Version: 1.0
;; Keywords: languages p4
;; Homepage: http://p4.org

;; This file is not part of GNU Emacs.

;; This file is free software…

;; Given two different versions of P4 language, P4_14 and P4_16 I decided to
;; split P4 mode into two separate ones: P4_14 and P4_16
;;
;; This file therefore will load both modes and then the user can choose them
;; by using Emacs mode line. Unfortunately, at least for now, P4 programs have
;; the same extension (.p4) regardless of the version of the language. I would
;; recommend associating this extension with the mode you use most, while
;; getting into the habit of starting .p4 files with the mode line, e.g.
;;
;; /* -*- mode: P4_16 -*- */

(load "p4_14-mode")
(load "p4_16-mode")

