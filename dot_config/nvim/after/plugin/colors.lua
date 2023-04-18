function ColourMyPencils(color)
  color = color or 'catppuccin'
  vim.cmd.colorscheme(color)
end

ColourMyPencils()
