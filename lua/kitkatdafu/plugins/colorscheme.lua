return {
    "nyoom-engineering/oxocarbon.nvim",
    name = "oxocarbon",
    priority = 1000,
    config = function()
        vim.o.background = "light"
        vim.cmd.colorscheme "oxocarbon"
    end
}
