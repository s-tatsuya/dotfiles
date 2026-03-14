vim.g.mapleader = " "

local keymap = vim.keymap

-- 検索時のハイライトをクリアする
keymap.set("n", "<C-l>", ":<C-u>nohlsearch<CR><C-l>")

-- *の検索で移動しない
keymap.set("n", "*", "*N")

-- カーソル移動:スクリーン表示の行で移動
-- wrapをfalseにしている場合はこの設定は不要
keymap.set({ "n", "v" }, "j", "gj")
keymap.set({ "n", "v" }, "k", "gk")

-- Quicklistの操作
keymap.set("n", "[c", ":cp<CR>")
keymap.set("n", "]c", ":cn<CR>")

-- バッファの移動
keymap.set("n", "[b", ":bp<CR>", { silent = true })
keymap.set("n", "]b", ":bn<CR>", { silent = true })
