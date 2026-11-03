
local M = {}
M.pathes = {}

function M.set_image(path, row, col, width, height)
    local id = vim.ui.img.set(vim.fn.readblob(path),
        {row=row, col=col, width=width, height=height, zindex=50}
    )
    M.pathes[id] = path
    return id
end

function M.update_image(path, pre_id, row, col)
    if path == M.pathes[pre_id] then
        -- the same image
        opt = {row=row, col=col}
        arg0 = pre_id
    else
        -- replace the image
        opt = vim.ui.img.get(pre_id)
        opt.row = row
        opt.col = col
        arg0 = vim.fn.readblob(path)
        vim.ui.img.del(pre_id)
        M.pathes[pre_id] = nil
    end
    local id = vim.ui.img.set(arg0, opt)
    M.pathes[id] = path
    return id
end

function M.update_ball(id, row, col)
    vim.ui.img.set(id, {row=row, col=col})
end

function M.close(id)
    vim.ui.img.del(id)
    M.pathes[id] = nil
end

function M.clear()
    for key, val in pairs(M.pathes) do
        vim.ui.img.del(key)
    end
    M.pathes = {}
end

return M
