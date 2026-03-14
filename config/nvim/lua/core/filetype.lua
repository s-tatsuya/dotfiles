local M = {}

-- インデントの設定を行う関数
local function set_indent(tab_length, is_hard_tab)
    if is_hard_tab then
        vim.bo.expandtab = false
    else
        vim.bo.expandtab = true
    end

    vim.bo.shiftwidth = tab_length
    vim.bo.softtabstop = tab_length
    vim.bo.tabstop = tab_length
end

-- YAML と Markdown のインデント設定を行う関数
M.yaml = function()
    set_indent(2, false)  -- YAML ファイルのために2つのスペースのソフトタブ
end

M.markdown = function()
    set_indent(2, false)  -- Markdown ファイルのために2つのスペースのソフトタブ
end

-- その他のファイルタイプのインデント設定を行う関数（デフォルト）
M.default = function()
    set_indent(4, false)  -- デフォルトのファイルタイプのために4つのスペースのソフトタブ
end

return M
