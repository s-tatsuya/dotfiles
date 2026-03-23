return {
    {
        "3rd/image.nvim",
        opts = {
            backend = "kitty",
        },
    },
    {
        "3rd/diagram.nvim",
        dependencies = { "3rd/image.nvim" },
        opts = function()
            return {
                integrations = {
                    require("diagram.integrations.markdown"),
                },
                renderer_options = {
                    mermaid = { background = "transparent" },
                },
            }
        end,
    },
}
